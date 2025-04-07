//
//  WebSocketManager.swift

/*
// 核心模块设计
WebSocketManager       // 管理多个服务连接
 ├─ WebSocketService   // 单个 WebSocket 实例
     ├─ SubscriptionQueue      // 缓存订阅消息
     ├─ HeartbeatScheduler     // 心跳管理
     └─ WebSocketEventBus      // 事件统一派发（Rx / Combine）
**/

import UIKit
import Combine

public class WebSocketManager {
    static let shared = WebSocketManager()
    private var services: [WebSocketServiceType: WebSocketService] = [:]

    func registerService(webSocketServiceType: WebSocketServiceType) {
        if services[webSocketServiceType] == nil {
            let service = WebSocketService(webSocketServiceType: webSocketServiceType)
            services[webSocketServiceType] = service
        }
    }
    
    func unregisterService(webSocketServiceType: WebSocketServiceType) {
        if services.keys.contains(webSocketServiceType) {
            services.removeValue(forKey: webSocketServiceType)
        }
    }

//    func sendMessage(to webSocketServiceType: WebSocketServiceType, message: WebSocketSubscription) {
//        services[webSocketServiceType]?.send(message)
//    }

    func subscribe(to webSocketServiceType: WebSocketServiceType, subscription: WebSocketSubscription) {
        services[webSocketServiceType]?.sendSubscription(subscription)
    }

    func unsubscribe(to webSocketServiceType: WebSocketServiceType, subscription: WebSocketSubscription) {
        services[webSocketServiceType]?.cancelSubscription(subscription)
    }

    func observeTopic(_ topic: String) -> AnyPublisher<[String: Any], Never> {
        return WebSocketEventBus.shared.publisher(for: topic).eraseToAnyPublisher()
    }
}
