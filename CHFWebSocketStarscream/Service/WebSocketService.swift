//
//  WebSocketService.swift
//  CHFWebSocketStarscream
//
//  Created by Nikcy on 2025/4/7.
//

import UIKit
import Starscream
import Combine
import Network

public class WebSocketService: WebSocketDelegate {
    private let identifier: String
    private let webSocketServiceType: WebSocketServiceType
    // 从webSocketServiceType获取请求超时时间
    private var socket: WebSocket?
    // 从webSocketServiceType获取url
    private let url: String
    /// 从webSocketServiceType获取定时间隔
    private var heartbeatTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    /// 在连接未建立时临时保存订阅消息的一个队列
    private let webSocketSubscriptionQueue = WebSocketSubscriptionQueue()
    /// 订阅的主题回调处理
    private let topicSubjects = [String: PassthroughSubject<[String: Any], Never>]().withLock()
    /// 连接状态
    private var isConnected = false
    private var reconnectAttempts = 0
    
    private var isReconnecting = false
    
    /// 超时检测字典
    private var pendingMessages: [String: (message: String, timestamp: TimeInterval)] = [:]
    
    // 网络监听
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "websocket.network.monitor")
    
    /// 增加连接状态发布接口（Combine）方便 UI 或管理组件监听连接状态：
    public var connectionStatus = CurrentValueSubject<Bool, Never>(false)

    
    deinit {
        disconnect()
        stopNetworkMonitor()
        chf_print(.info, "\(self) -- \(#function)")
    }

    init(webSocketServiceType: WebSocketServiceType) {
        self.identifier = webSocketServiceType.identity
        self.url = webSocketServiceType.host
        self.webSocketServiceType = webSocketServiceType
        setupSocket()
        startNetworkMonitor()
    }

    private func setupSocket() {
        let request = URLRequest(url: URL(string: url)!)
        socket = WebSocket(request: request)
        socket?.request.timeoutInterval = webSocketServiceType.requestTimeoutInterval
        socket?.delegate = self
    }
    
    private func startNetworkMonitor() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            if path.status == .satisfied && !self.isConnected {
                chf_print(.info, "Network reachable, attempting reconnect...")
                DispatchQueue.main.async {
                    self.connect()
                }
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }

    private func stopNetworkMonitor() {
        pathMonitor.cancel()
    }

    func connect() {
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
        stopHeartbeat()
        isConnected = false
    }

    // MARK: - 发送消息
    func sendSubscription(_ subscription: WebSocketSubscription, _ event: String = "sub") {
        if isConnected {
            sendMessages(subscription, event)
        } else {
            webSocketSubscriptionQueue.add(subscription)
        }
    }
    
    func cancelSubscription(_ subscription: WebSocketSubscription, _ event: String = "cancel") {
        webSocketSubscriptionQueue.cancel(subscription)
        sendMessages(subscription, event)
    }
    
    func cancelSubscriptionAll(_ event: String = "cancel") {
        webSocketSubscriptionQueue.clear()
    }
    
    private func sendMessages(_ subscription: WebSocketSubscription, _ event: String) {
        guard let socket = socket else { return }
                
        let jsonObject: [String: Any?] = [
            "topic": subscription.topic,
            "event": event,
            "stock": subscription.stock,
            "symbol": subscription.symbol,
            "timeMode": subscription.timeMode,
            "payload": subscription.payload,
            "sendTime": subscription.sendTime,
            "id": subscription.id
        ]
        
        // 移除值为 nil 的键，避免 JSON 中出现 null 值 (可选)
        let validJsonObject = jsonObject.compactMapValues { $0 }
        
        if let message = dictionaryToJsonString(dictionary: validJsonObject) {
            chf_print(.info, "WebSocket send text: \(message)")
            socket.write(string: message)
            
            // 启动超时检测
            if webSocketServiceType.packetLossRetransmissionMechanism {
                let messageID = subscription.topic
                pendingMessages[messageID] = (message, Date().timeIntervalSince1970)
                DispatchQueue.main.asyncAfter(deadline: .now() + self.webSocketServiceType.messageTimeout) { [weak self] in
                    self?.checkMessageTimeout(id: messageID)
                }
            }
        }
    }
    
    private func dictionaryToJsonString(dictionary: [String: Any]) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            } else {
                return nil
            }
        } catch {
            chf_print(.error, "Error converting dictionary to JSON: \(error)")
            return nil
        }
    }
    
    private func resendAllSubscriptions() {
        for subscription in webSocketSubscriptionQueue.all() {
            sendSubscription(subscription)
        }
    }
    
    // WebSocketService内回调可供外部调用
    public func observeTopic(_ topic: String) -> AnyPublisher<[String: Any], Never> {
        topicSubjects[topic, default: PassthroughSubject<[String: Any], Never>()]
            .eraseToAnyPublisher()
    }
    
    
    /// 如果连接失败多次触发 .disconnected，可能并发进入多个 attemptReconnect() 调用，导致多个 connect() 同时进行。✅：引入状态标识（isReconnecting）防止重入
    private func attemptReconnect(reason: String, code: UInt16) {
        guard !isReconnecting && reconnectAttempts < 5 else { return }
        isReconnecting = true
        reconnectAttempts += 1
        
        let reconnectDelay = min(pow(2.0, Double(reconnectAttempts)), 60) // 指数退避策略
        DispatchQueue.main.asyncAfter(deadline: .now() + reconnectDelay) { [weak self] in
            self?.isReconnecting = false
            self?.connect()
        }
    }
    
    // MARK: - WebSocketDelegate + 自动重连 + 心跳 + 响应处理
    public func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected:
            handleConnectedEvent()
        case .disconnected(let reason, let code):
            handleDisconnectedEvent(reason: reason, code: code)
        case .text(let text):
            handleTextEvent(text: text)
        case .error(let error):
            handleErrorEvent(error: error)
        default: break
        }
    }
    
    /// 处理连接成功后的逻辑
    private func handleConnectedEvent() {
        chf_print(.info, "WebSocket connected")
        isConnected = true
        reconnectAttempts = 0
        startHeartbeat()
        resendAllSubscriptions()
        connectionStatus.send(true)
    }
    
    private func handleDisconnectedEvent(reason: String, code: UInt16) {
        chf_print(.info, "WebSocket disconnected \(reason) === \(code)")
        isConnected = false
        connectionStatus.send(false)
        stopHeartbeat()
        attemptReconnect(reason: reason, code: code)
    }
    
    private func handleTextEvent(text: String) {
        if let data = text.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let topic = json["topic"] as? String {
            chf_print(.info, "WebSocket Received text: \(text)")
            DispatchQueue.main.async {
                self.topicSubjects[topic]?.send(json)
                WebSocketEventBus.shared.send(topic: topic, payload: json)
            }
        }
    }

    private func handleErrorEvent(error: Error?) {
        let errorMessage = error?.localizedDescription ?? "Unknown error"
        chf_print(.error, "WebSocket error: \(errorMessage)")
        // 可以根据错误类型进行更精细的处理
        // 例如，某些错误可能不需要重连
    }
}

// MARK: - Heartbeat
extension WebSocketService {
    private func startHeartbeat() {
        stopHeartbeat()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: webSocketServiceType.heartbeatTimerInterval, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func sendPing() {
        let heartbeatMessage = webSocketServiceType.heartbeatMessage
        socket?.write(string: heartbeatMessage)
//        chf_print(.info, heartbeatMessage)
    }
}

// MARK: - 启动超时检测
extension WebSocketService {
    private func checkMessageTimeout(id: String) {
        guard let (msg, timestamp) = pendingMessages[id] else { return }
        if Date().timeIntervalSince1970 - timestamp >= self.webSocketServiceType.messageTimeout {
            chf_print(.warning, "Message \(id) timeout, resending...")
            socket?.write(string: msg)
            pendingMessages[id] = (msg, Date().timeIntervalSince1970)
            checkMessageTimeout(id: id)
        }
    }
}

// MARK: - Thread-safe Dictionary Extension
extension Dictionary where Key == String, Value == PassthroughSubject<[String: Any], Never> {
    func withLock() -> SynchronizedDictionary {
        return SynchronizedDictionary(self)
    }
}

final class SynchronizedDictionary {
    private var dictionary: [String: PassthroughSubject<[String: Any], Never>]
    private let queue = DispatchQueue(label: "dict.lock")
    
    init(_ dict: [String: PassthroughSubject<[String: Any], Never>]) {
        self.dictionary = dict
    }
    
    subscript(key: String) -> PassthroughSubject<[String: Any], Never>? {
        get {
            queue.sync { dictionary[key] }
        }
        set {
            queue.sync { dictionary[key] = newValue }
        }
    }
    
    subscript(key: String, default defaultValue: @autoclosure () -> PassthroughSubject<[String: Any], Never>) -> PassthroughSubject<[String: Any], Never> {
        get {
            return queue.sync {
                if let existing = dictionary[key] {
                    return existing
                } else {
                    let new = defaultValue()
                    dictionary[key] = new
                    return new
                }
            }
        }
    }
}

