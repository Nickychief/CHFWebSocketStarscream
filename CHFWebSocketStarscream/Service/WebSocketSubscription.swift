//
//  WebSocketSubscription.swift
//  CHFWebSocketStarscream
//
//  Created by 刘远明 on 2025/4/7.
//

import UIKit

// MARK: - Subscription Model
public struct WebSocketSubscription: Hashable {
    public var topic: String
    public var stock: String?
    public var symbol: String?
    public var timeMode: String?
    public var payload: [String: Any]
    public var sendTime: TimeInterval = TimeInterval(Date().timeIntervalSince1970 * 1000)
    public var id: String = UUID().uuidString
    
    public init(topic: String,
                stock: String? = nil,
                symbol: String? = nil,
                timeMode: String? = nil,
                payload: [String: Any] = [:]) {
        self.topic = topic
        self.stock = stock
        self.symbol = symbol
        self.timeMode = timeMode
        self.payload = payload
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(topic)
        hasher.combine(symbol)
    }

    public static func == (lhs: WebSocketSubscription, rhs: WebSocketSubscription) -> Bool {
        return lhs.topic == rhs.topic && lhs.symbol == rhs.symbol
    }
}
