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
    
    var requestTimeoutInterval: TimeInterval {
        switch self {
        case .MarketService:
            return 10
        case.USStockOptions:
            return 10
        }
    }
    
    var heartbeatTimerInterval: TimeInterval {
        switch self {
        case .MarketService:
            return 30
        case.USStockOptions:
            return 30
        }
    }
}
