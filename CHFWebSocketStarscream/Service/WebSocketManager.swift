//
//  WebSocketManager.swift

/*
// 核心模块设计
WebSocketManager       // 管理多个服务连接
 ├─ WebSocketService   // 单个 WebSocket 实例
     ├─ WebSocketSubscriptionQueue      // 缓存订阅消息
     ├─ HeartbeatScheduler     // 心跳管理
     └─ WebSocketEventBus      // 事件统一派发（Rx / Combine）
**/

import UIKit
import Combine

public class WebSocketManager {
    static let shared = WebSocketManager()
    private var services: [WebSocketServiceType: WebSocketService] = [:]

    @discardableResult
    func registerService(webSocketServiceType: WebSocketServiceType) -> WebSocketService? {
        if services[webSocketServiceType] == nil {
            let service = WebSocketService(webSocketServiceType: webSocketServiceType)
            service.connect()
            services[webSocketServiceType] = service
            return service
        } else {
            return services[webSocketServiceType]
        }
    }
    
    func unregisterService(webSocketServiceType: WebSocketServiceType) {
        if services.keys.contains(webSocketServiceType) {
            services[webSocketServiceType]?.disconnect()
            services.removeValue(forKey: webSocketServiceType)
        }
    }
    
    func unregisterServiceAll() {
        if !services.isEmpty {
            services.forEach({ $0.value.disconnect() })
            services.removeAll()
        }
    }

    func subscribe(to webSocketServiceType: WebSocketServiceType, subscription: WebSocketSubscription) {
        services[webSocketServiceType]?.sendSubscription(subscription)
    }

    func unsubscribe(to webSocketServiceType: WebSocketServiceType, subscription: WebSocketSubscription) {
        services[webSocketServiceType]?.cancelSubscription(subscription)
    }

    func observeTopic(_ topic: String) -> AnyPublisher<[String: Any], Never> {
        return WebSocketEventBus.shared.publisher(for: topic)
    }
}
