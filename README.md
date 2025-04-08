# [CHFWebSocketStarscream](https://github.com/Nickychief/CHFWebSocketStarscream/wiki/How-to-use-it) 

```
┌────────────────────────┐
│   WebSocketService     │
├────────────────────────┤
│ ✅ 多实例（按服务区分）    │
│ ✅ 订阅 / 取消订阅       │
│ ✅ 订阅暂存队列支持       │
│ ✅ 自动重连（限次 + 延迟） │
│ ✅ Combine 回调接口      │
│ ✅ 独立心跳机制           │
│ ✅ 消息去重 / 可扩展优先级  │
│ ✅ 日志打印              │    
│ ✅ 网络状态监听自动重连    │
└────────────────────────┘

// 核心模块设计  

WebSocketManager               // 管理多个服务连接 （通过WebSocketServiceType生成唯一标识）
 ├─ WebSocketServiceType       // WebSocket服务类型（通过 WebSocketServiceType 枚举）
 ├─ WebSocketService           // 单个 WebSocket 实例
     ├─ WebSocketSubscription  // 消息Model
     ├─ WebSocketSubscriptionQueue // 缓存订阅消息
     ├─ HeartbeatScheduler     // 心跳管理（暂时移除，通过WebSocketServiceType配置）
     └─ WebSocketEventBus      // 事件统一派发（Rx / Combine）
```


✅ 功能清单汇总 	
1.	支持多 WebSocket 服务类型（通过 WebSocketServiceType 枚举）每个服务可配置独立的 host、timeout、心跳间隔	
2.	延迟订阅支持，连接前订阅信息暂存、自动连接后重发（丢包重传机制（确认+重发））	
3.	订阅 / 取消订阅的统一封装
4.	不同服务器响应结构统一处理 	
5.	自动重连机制（断开后重试，指数退避）	
6.	每个连接自定义心跳机制（心跳机制（按服务间隔发送））	
7.	支持 RxSwift / Combine 事件流 	
8.	日志与调试功能（连接、订阅、接收、错误打印）
9.      网络状态监听自动重连

---
---
---



✅ 现有功能一览

💡 1. 多 WebSocket 实例支持
	•	支持多个 WebSocket 服务源（例如：
	•	MarketService: wss://api-test.stx365.com/quote/ws/v1
	•	USStockOptions: wss://api-dev.stx365.com/quote-us-option/ws/v1
	•	每个服务通过 WebSocketServiceType 枚举区分，支持独立配置 host、heartbeat、timeout 等。

---

 📩 2. 消息订阅管理
	•	提供统一的 subscribe() / unsubscribe() 接口，发送标准订阅请求。
	•	支持延迟订阅队列：
	•	在 WebSocket 未连接时调用 subscribe(...)，会先缓存订阅请求，等连接建立后再自动发送。
	•	支持取消指定 topic 或全部订阅（cancel(topic:) / cancelAll()）。

---

🔁 3. 自动重连机制
	•	在连接断开或失败时，尝试自动重连。
	•	限制最大重连次数，支持重连延迟（如 5s 后重连）。
	•	后续优化中已加入：避免重复重连、防止并发多次调用 connect()、指数退避策略等。

---

🫀 4. 心跳机制
	•	每个 WebSocket 实例支持独立心跳发送（基于 Timer）。
	•	心跳内容通过 heartbeatMessage 动态生成，可定制不同服务的格式。

---

🧪 5. 统一响应处理
	•	所有 WebSocket 返回的数据解析为 JSON 后，根据 topic 进行广播。
	•	使用 PassthroughSubject<[String: Any], Never>（Combine）发布响应数据，便于外部组件订阅数据流。

---

📦 6. 使用 Combine 暴露接口
	•	提供 observeTopic(_:) 方法供业务方订阅指定 topic 数据流。
	•	返回 Combine 的 AnyPublisher，可与 UI/模型层轻松集成。

---

🧼 7. 订阅去重 / 优先级 / 取消支持
	•	WebSocketSubscriptionQueue 支持去重逻辑，避免重复订阅相同内容。
	•	后续可扩展优先级和订阅取消逻辑（目前结构预留良好）。

---

🪵 8. 日志和调试
	•	内部使用 chf_print(...) 打印关键事件，如连接、重连、订阅、接收数据等。
	•	有助于调试和线上问题追踪。

