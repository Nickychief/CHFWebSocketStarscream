//
// CHFWebSocketManager.swift
//
// Copyright © 2024 Chief Group Limited. All rights reserved.
//

import Foundation
import Starscream

extension Notification.Name {
    public static let CHFUserDidLogout: NSNotification.Name = Notification.Name.init("user_did_logout")
    
    public static let CHFWebSocketRequestConnect = Notification.Name.init(rawValue: "CHFWebSocketRequestConnect")
    public static let CHFWebSocketConnected = Notification.Name.init(rawValue: "CHFWebSocketConnected")
    public static let CHFWebSocketDisconnected = Notification.Name.init(rawValue: "CHFWebSocketDisconnected")
}

open class CHFWebSocketManager: CHFWebSocketAdvancedDelegate {
    let TimeOfConnectingWaiting = 20
    let TimeOfPingPeriod = 10
    let TimeOfPongWait = 30
    
    public static let shared = CHFWebSocketManager()
    
    var websocket: CHFWebSocket?
    var timer: DispatchSourceTimer
    var currentStatus: CHFConnectStatus
    
    var sendResiduePingResidueTime: Int = 0
    var receivePongResidueTime: Int = 0
    var retryTime: Int = 0
    var connectingResidueTime: Int = 0
    var concedeWaitResidueTime = 10
    
    var commandHandlers = [String: CHFCommandEventHandler]()
    private var messageQueue: [String] = []
    // 使用 DispatchQueue 进行同步访问，避免竞态条件。
    private let queueLock = DispatchQueue(label: "CHFWebSocketManager.messageQueue")
    private let backgroundQueue = DispatchQueue.global(qos: .background)
    
    fileprivate init() {
        self.currentStatus = .readyToConnect
        
        timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags.init(rawValue: 0), queue: DispatchQueue.main)
        timer.schedule(deadline: DispatchTime.now(), repeating: .seconds(1), leeway: .milliseconds(100))
        timer.setEventHandler { [weak self] in
            self?.timeCheck()
        }
        timer.resume()
        
        initCommondHandlers()
        
        initNotification()
    }
    
    deinit {
        timer.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    func initNotification() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.CHFUserDidLogout, object: nil, queue: nil) { [weak self] (notification) in
            self?.setNoNeedConnect()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.CHFReachabilityChanged, object: nil, queue: nil) { [weak self] (notification) in
            if let reachability = ITApplicationReachablility {
                chf_print(.info, "------", "reachabilityChanged", reachability.connection)
                
                if reachability.connection == .none {
                    return
                }
                
                if self?.currentStatus == .networkWating, reachability.connection != .none {
                    self?.currentStatus = .readyToConnect
                    self?.connect()
                    return
                }
                
                if reachability.connection == .wifi {
                    self?.reachabilityChanged(isWifi: true)
                    return
                }
                
                self?.reachabilityChanged()
            }
        }
    }
    
    func initCommondHandlers() {
        commandHandlers["event"] = CHFCommandEventHandler()
    }
    
    func reachabilityChanged(isWifi: Bool = false) {
        guard currentStatus != .networkWating else { return } // 避免重复操作

        switch self.currentStatus {
        case .concedeWating:
            self.connect()
        case .connected where isWifi:
            self.disconnect()
            self.connect()
        default:
            break
        }
    }
    
    public func timeCheck() {
        switch self.currentStatus {
        case .connecting:
            connectingResidueTime -= 1
            if connectingResidueTime < 0 { concedeRetry() }
            
        case .concedeWating:
            concedeWaitResidueTime -= 1
            if concedeWaitResidueTime < 0 { connect() }
            
        case .connected:
            sendResiduePingResidueTime -= 1
            receivePongResidueTime -= 1
            
            if sendResiduePingResidueTime <= 0 {
                sendPingHeartbeatMessage()
                receivePongResidueTime = TimeOfPongWait // 发送 Ping 后重置 Pong 等待时间
            }
            
            if receivePongResidueTime <= 0 {
                concedeRetry() // 若未收到 Pong，则重新连接
            }
            
        default:
            break
        }
    }
    
    public func connectIfNeeded() {
        chf_print(.info, "------", "connectIfNeeded")
        self.backgroundQueue.async {
            switch self.currentStatus {
            case .readyToConnect:
                self.connect()
            default:
                break
            }
        }
    }
    
    public func setNoNeedConnect() {
        self.disconnect()
        self.currentStatus = .readyToConnect
    }
    
    // MARK: - WebSocket Connect And disconnect()
    func connect() {
        guard self.currentStatus == .readyToConnect || self.currentStatus == .concedeWating else {
            return
        }
        chf_print(.info, "------", "connect")
        
        self.sendNotificationOfRequestConnect(self.retryTime)
        self.websocket = CHFWebSocket(token: "MGGG iToken", deviceId: UUID().uuidString, host: "wss://api-dev.stx365.com/quote-us-option/ws/v1")
        self.websocket?.connect(delegate: self)
        self.currentStatus = .connecting
        self.connectingResidueTime = self.TimeOfConnectingWaiting
    }
    
    public func disconnect(completion: (() -> Void)? = nil) {
        guard websocket != nil else {
            completion?()
            return
        }
        
        resetWebSocket()
        self.currentStatus = .concedeWating
        sendNotificationOfDisconnected()
        
        completion?()
    }
    
    private func resetWebSocket() {
        websocket?.disconnect()
        websocket?.delegate = nil
        websocket = nil
    }
    
    func sendPingHeartbeatMessage() {
        self.websocket?.pingHeartbeatMessage()
        self.sendResiduePingResidueTime = self.TimeOfPingPeriod
    }
    
    // 退让
    private func concedeRetry() {
        resetWebSocket()
        self.retryTime += 1
        self.concedeWaitResidueTime = getConcedeRetryWaitingTime()
        self.currentStatus = .concedeWating
        
        chf_print(.info, "------", "concedeRetry", self.retryTime, self.concedeWaitResidueTime)
    }
    
    private func getConcedeRetryWaitingTime() -> Int {
        let maxWaitTime = min(self.retryTime + 2, 10)
        return Int.random(in: 1...maxWaitTime)
    }
    
    private func sendNotificationOfDisconnected() {
        if Thread.isMainThread {
            NotificationCenter.default.post(name: Notification.Name.CHFWebSocketDisconnected, object: nil)
        } else {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name.CHFWebSocketDisconnected, object: nil)
            }
        }
    }
    
    private func sendNotificationOfConnected() {
        if Thread.isMainThread {
            NotificationCenter.default.post(name: Notification.Name.CHFWebSocketConnected, object: nil)
        } else {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name.CHFWebSocketConnected, object: nil)
            }
        }
    }
    
    private func sendNotificationOfRequestConnect(_ num: Int) {
        if Thread.isMainThread {
            NotificationCenter.default.post(name: Notification.Name.CHFWebSocketRequestConnect, object: nil, userInfo: ["retry": num])
        } else {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name.CHFWebSocketRequestConnect, object: nil, userInfo: ["retry": num])
            }
        }
    }
    
    // MARK: - CHFWebSocketAdvancedDelegate
    public func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        chf_print(.info, "\(event) === \(client)")
        switch event {
        case .connected(_):
            chf_print(.info, "CHFWebSocket connected")
            self.currentStatus = .connected
            self.receivePongResidueTime = self.TimeOfPongWait
            self.sendNotificationOfConnected()
            sendPendingMessages() // 重新发送缓存的消息
        case .disconnected(let reason, let code):
            chf_print(.info, "CHFWebSocket disconnected \(reason) === \(code)")
            self.websocket = nil
            self.sendNotificationOfDisconnected()
            self.concedeRetry()
        case .text(let message):
            chf_print(.info, "CHFWebSocket Received text: \(message)")
            if  let jsonData = message.data(using: .utf8),
                let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                if let _ = CHFDictionaryUnwrap(jsonObject).get("topic").string(),
                    let handler = commandHandlers["event"] {
                    handler.handleCommand(eventMap: jsonObject)
                }
            }
        case .binary(let data):
            chf_print(.info, "CHFWebSocket Received binary: \(data.count) bytes")
        case .cancelled:
            concedeRetry()
        case .error(let error):
            chf_print(.error, "CHFWebSocket WebSocket error: \(error?.localizedDescription ?? "Unknown error")")
        default:
            break
        }
    }
}

// MARK: - WebSocket Command Handlers
extension CHFWebSocketManager {
    // MARK: - trade 订阅trade
    /// 订阅 `trade` 数据
    func subscribeToTrade(stock: String, symbol: String, timeMode: String) {
        sendMessage(topic: .trade, event: .sub, stock: stock, symbol: symbol, timeMode: timeMode)
    }
    
    // 取消订阅 `trade` 数据
    func unsubscribeToTrade(stock: String, symbol: String, timeMode: String) {
        sendMessage(topic: .trade, event: .cancel, stock: stock, symbol: symbol, timeMode: timeMode)
    }
    
    // MARK: - Order 订阅Order
    /// 订阅 `Order` 数据
    func subscribeToOrder(stock: String, symbol: String, timeMode: String) {
        sendMessage(topic: .order, event: .sub, stock: stock, symbol: symbol, timeMode: timeMode)
    }
    
    /// 取消订阅 `Order` 数据
    func unsubscribeToOrder(stock: String, symbol: String, timeMode: String) {
        sendMessage(topic: .order, event: .cancel, stock: stock, symbol: symbol, timeMode: timeMode)
    }
    
    // MARK: - extend_snap 订阅扩展行情
    /// 订阅 `extend_snap` 数据
    func subscribeToExtendSnap(stock: String, symbol: String, timeMode: String, params: [String: Any] = [:]) {
        sendMessage(topic: .extend_snap, event: .sub, stock: stock, symbol: symbol, timeMode: timeMode, params: params)
    }
    
    // 取消订阅 `extend_snap` 数据
    func unsubscribeToExtendSnap(stock: String, symbol: String, timeMode: String, params: [String: Any] = [:]) {
        sendMessage(topic: .extend_snap, event: .cancel, stock: stock, symbol: symbol, timeMode: timeMode, params: params)
    }
    
    // MARK: - option_snapshot 订阅快照
    /// 订阅 `option_snapshot` 数据
    func subscribeToOptionSnapshot(stock: String, symbol: String, timeMode: String, params: [String: Any] = [:]) {
        sendMessage(topic: .option_snapshot, event: .sub, stock: stock, symbol: symbol, timeMode: timeMode, params: params)
    }
    
    // 取消订阅 `option_snapshot` 数据
    func unsubscribeToOptionSnapshot(stock: String, symbol: String, timeMode: String, params: [String: Any] = [:]) {
        sendMessage(topic: .option_snapshot, event: .cancel, stock: stock, symbol: symbol, timeMode: timeMode, params: params)
    }
    
    // MARK: - option_status 订阅单个期权状态
    /// 订阅 `option_status` 数据
    func subscribeToOptionStatus(stock: String, symbol: String, timeMode: String) {
        sendMessage(topic: .option_status, event: .sub, stock: stock, symbol: symbol, timeMode: timeMode)
    }
    
    // 取消订阅 `option_status` 数据
    func unsubscribeToOptionStatus(stock: String, symbol: String, timeMode: String) {
        sendMessage(topic: .option_status, event: .cancel, stock: stock, symbol: symbol, timeMode: timeMode)
    }
    
    // MARK: - 发送消息
    /// 发送消息
    func sendMessage(topic: CHFTopic, event: CHFEvent, stock: String, symbol: String, timeMode: String, params: [String: Any] = [:]) {
        let message: [String: Any] = [
            "topic": topic.rawValue,
            "event": event.rawValue, // 订阅：sub  取消订阅：cancel
            "stock": stock, // 股票代码
            "timeMode": timeMode, // 实时：0，延时：1
            "symbol": symbol,  // 期权代码
            "params": params,
            "sendTime": Int(Date().timeIntervalSince1970 * 1000)
        ]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                guard self.currentStatus == .connected else {
                    chf_print(.warning, "WebSocket 未连接，消息入队等待发送")
                    enqueueMessage(jsonString) // 缓存未发送的消息
                    return
                }
                websocket?.webSocket.write(string: jsonString)
                chf_print(.info, "📤 发送消息: \(jsonString)")
            }
        } catch {
            chf_print(.error, "❌ JSON 序列化错误: \(error.localizedDescription)")
        }
    }
    
    // 连接成功后，重新发送未处理的消息
    private func sendPendingMessages() {
        queueLock.sync {
            while !messageQueue.isEmpty, self.currentStatus == .connected {
                let message = messageQueue.removeFirst()
                websocket?.webSocket.write(string: message)
            }
        }
    }
    
    // MARK: - 处理消息
    private func enqueueMessage(_ message: String) {
        queueLock.sync {
            messageQueue.append(message)
        }
    }

    private func dequeueMessage() -> String? {
        queueLock.sync {
            return messageQueue.isEmpty ? nil : messageQueue.removeFirst()
        }
    }
}

public func chf_print(_ level: LogLevel = .info, _ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    let prefix: String
    switch level {
    case .info: prefix = "ℹ️"
    case .warning: prefix = "⚠️"
    case .error: prefix = "❌"
    }
    print(prefix, items, separator: separator, terminator: terminator)
    #endif
}

public enum LogLevel {
    case info, warning, error
}
