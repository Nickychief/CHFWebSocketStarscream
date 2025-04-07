//
//  WebSocketService.swift
//  CHFWebSocketStarscream
//
//  Created by 刘远明 on 2025/4/7.
//

import UIKit
import Starscream
import Combine

public class WebSocketService: WebSocketDelegate {
    private var socket: WebSocket?
    private let identifier: String
    private let url: String
    private var heartbeatTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let subscriptionQueue = SubscriptionQueue()
    private let topicSubjects = [String: PassthroughSubject<[String: Any], Never>]().withLock()
    private let reconnectDelay: TimeInterval = 5
    private var isConnected = false
    private var reconnectAttempts = 0

    init(webSocketServiceType: WebSocketServiceType) {
        self.identifier = webSocketServiceType.identity
        self.url = webSocketServiceType.host
        setupSocket()
    }

    private func setupSocket() {
        let request = URLRequest(url: URL(string: url)!)
        socket = WebSocket(request: request)
        socket?.delegate = self
        connect()
    }

    func connect() {
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
        stopHeartbeat()
        isConnected = false
    }

    func sendSubscription(_ subscription: WebSocketSubscription, _ event: String = "sub") {
        if isConnected {
            sendMessages(subscription, event)
        } else {
            subscriptionQueue.add(subscription)
        }
    }
    
    func cancelSubscription(_ subscription: WebSocketSubscription, _ event: String = "cancel") {
        subscriptionQueue.cancel(subscription)
        sendMessages(subscription, event)
    }
    
    func observeTopic(_ topic: String) -> AnyPublisher<[String: Any], Never> {
        topicSubjects[topic, default: PassthroughSubject<[String: Any], Never>()]
            .eraseToAnyPublisher()
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
            socket.write(string: message)
        }
    }
    
    private func dictionaryToJsonString(dictionary: [String: Any]) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            } else {
                return nil // 转换失败
            }
        } catch {
            print("Error converting dictionary to JSON: \(error)")
            return nil // 编码失败
        }
    }
    
    private func resendAllSubscriptions() {
        for subscription in subscriptionQueue.all() {
            sendSubscription(subscription)
        }
    }
    
    // MARK: - Heartbeat
    private func startHeartbeat() {
        stopHeartbeat()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func sendPing() {
        let heartbeatMessage = "{\"ping\": \(Int(Date().timeIntervalSince1970 * 1000))}"
        socket?.write(string: heartbeatMessage)
//        chf_print(.info, heartbeatMessage)
    }
    
    // MARK: - WebSocketDelegate
    public func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected:
            chf_print(.info, "WebSocket connected")
            isConnected = true
            reconnectAttempts = 0
            startHeartbeat()
            resendAllSubscriptions()
        case .disconnected(let reason, let code):
            chf_print(.info, "WebSocket disconnected \(reason) === \(code)")
            isConnected = false
            stopHeartbeat()
            attemptReconnect(reason: reason, code: code)
        case .text(let text):
            if let data = text.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let topic = json["topic"] as? String {
                chf_print(.info, "WebSocket Received text: \(text)")
                topicSubjects[topic]?.send(json)
            }
        case .error(let error):
            print("WebSocket error: \(error?.localizedDescription ?? "Unknown error")")
        default: break
        }
    }
    
    private func attemptReconnect(reason: String, code: UInt16) {
        guard reconnectAttempts < 5 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + reconnectDelay) { [weak self] in
            self?.reconnectAttempts += 1
            self?.connect()
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

