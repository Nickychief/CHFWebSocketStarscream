//
//  WebSocketManager1.swift
//  CHFWebSocketStarscream
//
//  Created by Nikcy on 2025/4/3.
//

import UIKit
import Foundation
import Starscream

class WebSocketManager1: WebSocketDelegate {
    
    static let shared = WebSocketManager1()
    
    private var socket: WebSocket?
    private var isConnected = false
    private var urlString: String = "wss://api-test.stx365.com/quote/ws/v1"
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let heartbeatInterval: TimeInterval = 5
    private var heartbeatTimer: Timer?
    
    private init() {}
    
    func connect() {
        guard !isConnected else { return }
        var request = URLRequest(url: URL(string: urlString)!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
        isConnected = false
        stopHeartbeat()
    }
    
    private func reconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("Max reconnect attempts reached. Stopping reconnect attempts.")
            return
        }
        reconnectAttempts += 1
        print("Reconnecting attempt: \(reconnectAttempts)")
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.connect()
        }
    }
    
    private func startHeartbeat() {
        stopHeartbeat()
        heartbeatTimer = Timer.scheduledTimer(timeInterval: heartbeatInterval, target: self, selector: #selector(sendHeartbeat), userInfo: nil, repeats: true)
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    @objc private func sendHeartbeat() {
        guard isConnected else { return }
//        let heartbeatMessage = "{\"ping\": \(Int(Date().timeIntervalSince1970 * 1000))}"
//        socket?.write(string: heartbeatMessage)
//        print("Sent heartbeat: \(heartbeatMessage)")
    }
    
    func subscribe(topic: String, symbol: String) {
        guard isConnected else { return }
        let message: [String: Any] = [
            "topic": topic,
            "event": "sub",
            "symbol": symbol,
            "sendTime": Int(Date().timeIntervalSince1970 * 1000),
            "id": UUID().uuidString
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: message, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            socket?.write(string: jsonString)
            print("Subscribed: \(jsonString)")
        }
    }
    
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected(_):
            isConnected = true
            reconnectAttempts = 0
            print("WebSocket connected")
            startHeartbeat()
        case .disconnected(let reason, let code):
            isConnected = false
            print("WebSocket disconnected: \(reason) (code: \(code))")
            stopHeartbeat()
            reconnect()
        case .text(let message):
            print("Received text: \(message)")
        case .binary(let data):
            print("Received binary: \(data.count) bytes")
        case .cancelled:
            isConnected = false
            print("WebSocket connection cancelled")
            stopHeartbeat()
            reconnect()
        case .error(let error):
            isConnected = false
            print("WebSocket error: \(error?.localizedDescription ?? "Unknown error")")
            stopHeartbeat()
            reconnect()
        default:
            break
        }
    }
}

extension WebSocketManager1 {
    func subscribeToDepth(symbol: String, scale: String) {
        guard isConnected else {
            print("WebSocket 未连接，无法订阅")
            return
        }
        
        let message: [String: Any] = [
            "topic": "depth",
            "event": "sub",
            "symbol": symbol,
            "params": ["scale": scale],
            "sendTime": Int(Date().timeIntervalSince1970 * 1000),
            "id": UUID().uuidString
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: message, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            socket?.write(string: jsonString)
            print("发送订阅请求: \(jsonString)")
        }
    }
}
