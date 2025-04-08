//
//  WebSocketServiceType.swift
//  CHFWebSocketStarscream
//
//  Created by Nikcy on 2025/4/7.
//

import UIKit

enum WebSocketServiceType: String {
    case MarketService
    case USStockOptions
    
    var identity: String {
        switch self {
        case .MarketService:
            return "MarketService"
        case.USStockOptions:
            return "USStockOptions"
        }
    }
    
    var host: String {
        switch self {
        case .MarketService:
            return "wss://api-test.stx365.com/quote/ws/v1"
        case.USStockOptions:
            return "wss://api-dev.stx365.com/quote-us-option/ws/v1"
        }
    }
    
    /// 请求超时时间
    var requestTimeoutInterval: TimeInterval {
        switch self {
        case .MarketService:
            return 10
        case.USStockOptions:
            return 10
        }
    }
    
    /// 心跳包消息间隔
    var heartbeatTimerInterval: TimeInterval {
        switch self {
        case .MarketService:
            return 30
        case.USStockOptions:
            return 30
        }
    }
    
    /// 心跳包消息
    var heartbeatMessage: String {
        return "{\"ping\": \(self.identity)--\(Int(Date().timeIntervalSince1970 * 1000))}"
    }
    
    /// 消息超时（服务器未响应）
    var messageTimeout: TimeInterval {
        switch self {
        case .MarketService:
            return 5
        case.USStockOptions:
            return 5
        }
    }
    
    /// 是否需要丢包重传机制（确认+重发）
    var packetLossRetransmissionMechanism: Bool {
        switch self {
        case .MarketService:
            return false
        case.USStockOptions:
            return false
        }
    }
}
