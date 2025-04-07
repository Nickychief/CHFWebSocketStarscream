//
// CHFWebSocket.swift
//
// Copyright © 2024 Chief Group Limited. All rights reserved.
//

import Foundation
import Starscream

open class CHFWebSocket: Equatable {

    weak var delegate: CHFWebSocketAdvancedDelegate?
    let token: String
    let deviceId: String
    let host: String
    let queue: DispatchQueue?
    
    init(token: String, deviceId: String, host: String, queue: DispatchQueue? = nil) {
        self.token = token
        self.deviceId = deviceId
        self.host = host
        self.queue = queue
    }

    lazy var webSocket: WebSocket = {
        let url = URL.init(string: host)!
        var urlHost = url.host!
        var wsscheme = "ws"
        if url.scheme == "https" || url.scheme == "wss" {
            wsscheme = "wss"
        }
        var request = URLRequest(url: url)
        //        request.setValue(token, forHTTPHeaderField: "X-Token")
        //        request.setValue("MGGG", forHTTPHeaderField: "User-Agent")
        request.setValue(deviceId, forHTTPHeaderField: "X-Device")

        let socket = WebSocket(request: request)
        socket.callbackQueue = self.queue ?? DispatchQueue.main
        return socket
    }()

    func pingHeartbeatMessage() {
        let heartbeatMessage = "{\"ping\": \(Int(Date().timeIntervalSince1970 * 1000))}"
        webSocket.write(string: heartbeatMessage)
        chf_print(.info, heartbeatMessage)
//        webSocket.write(ping: Data())
    }

    func connect(delegate: CHFWebSocketAdvancedDelegate) {
        self.delegate = delegate
        webSocket.delegate = self
        webSocket.connect()
    }

    func disconnect() {
        webSocket.disconnect()
    }

    func sendMessage(json: String) {
        webSocket.write(string: json)
    }
    
    public static func == (lhs: CHFWebSocket, rhs: CHFWebSocket) -> Bool {
        let lhsP = Unmanaged.passUnretained(lhs).toOpaque()
        let rhsP = Unmanaged.passUnretained(rhs).toOpaque()
        return lhsP == rhsP
    }
}
extension CHFWebSocket: WebSocketDelegate {
    public func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
//        chf_print("\(event) === \(client)")
        self.delegate?.didReceive(event: event, client: client)
    }
}

public protocol CHFWebSocketAdvancedDelegate: AnyObject {
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient)
}
