# CHFWebSocketStarscream

<img width="541" alt="image" src="https://github.com/user-attachments/assets/aa090a4d-6ee6-423d-9c72-026f36d2b511" />
// 核心模块设计
WebSocketManager       // 管理多个服务连接
 ├─ WebSocketService   // 单个 WebSocket 实例
     ├─ SubscriptionQueue      // 缓存订阅消息
     ├─ HeartbeatScheduler     // 心跳管理
     └─ WebSocketEventBus      // 事件统一派发（Rx / Combine）

✅ 功能清单汇总 	
1.	支持多个域名、独立 WebSocket 实例管理 	
2.	连接前订阅信息暂存、自动连接后重发 	
3.	订阅 / 取消订阅的统一封装 	
4.	不同服务器响应结构统一处理 	
5.	自动断线重连，支持指数回退重试 	
6.	每个连接自定义心跳机制 	
7.	支持 RxSwift / Combine 事件流 	
8.	日志 & 调试接口封装
