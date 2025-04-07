//
//  WebSocketServiceType.swift
//  CHFWebSocketStarscream
//
//  Created by 刘远明 on 2025/4/7.
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
        default:
            return ""
        }
    }
    
}
