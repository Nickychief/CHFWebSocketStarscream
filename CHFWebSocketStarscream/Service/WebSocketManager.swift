//
//  WebSocketManager.swift
/// ============================================
/// WebSocketService 功能概览
///
/// ✅ 支持多 WebSocket 服务类型（通过 WebSocketServiceType 枚举）
/// ✅ 每个服务可配置独立的 host、timeout、心跳间隔
/// ✅ 自动重连机制（断开后重试，指数退避）
/// ✅ 心跳机制（按服务间隔发送）
/// ✅ 延迟订阅支持（未连接时先缓存，连接后自动发送）
/// ✅ 统一的订阅/取消订阅接口（支持 JSON 协议）
/// ✅ 基于 Combine 发布响应数据（PassthroughSubject）
/// ✅ 支持订阅去重、取消、优先级调度（结构预留）丢包重传机制（确认+重发）
/// ✅ 日志与调试功能（连接、订阅、接收、错误打印）
/// ✅ 网络状态监听自动重连
/// ============================================

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
    
    func unsubscribeAll(to webSocketServiceType: WebSocketServiceType) {
        services[webSocketServiceType]?.cancelSubscriptionAll()
    }

    func unsubscribe(to webSocketServiceType: WebSocketServiceType, subscription: WebSocketSubscription) {
        services[webSocketServiceType]?.cancelSubscription(subscription)
    }

    func observeTopic(_ topic: String) -> AnyPublisher<[String: Any], Never> {
        return WebSocketEventBus.shared.publisher(for: topic)
    }
}
