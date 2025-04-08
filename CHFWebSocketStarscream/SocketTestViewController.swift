//
//  SocketTestViewController.swift
//  CHFWebSocketStarscream
//
//  Created by Nikcy on 2025/4/7.
//

import UIKit
import Combine

class SocketTestViewController: UIViewController {
    private var cancellables: Set<AnyCancellable> = []
    let textView = UITextView()
    
    weak var WebSocketService1: WebSocketService? = nil
    weak var WebSocketService2: WebSocketService? = nil
    
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
       
        WebSocketManager.shared.unregisterService(webSocketServiceType: .MarketService)
        WebSocketManager.shared.unregisterService(webSocketServiceType: .USStockOptions)
        chf_print(.info, "\(self) -- \(#function)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textColor = .black
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // 创建socket1
        WebSocketService1 = WebSocketManager.shared.registerService(webSocketServiceType: .MarketService)
        // 创建socket2
        WebSocketService2 = WebSocketManager.shared.registerService(webSocketServiceType: .USStockOptions)
        
        // socket1的订阅
        WebSocketManager.shared.subscribe(to: .MarketService, subscription: WebSocketSubscription(topic: "depth", symbol: "301.700", timeMode: "0", payload: ["scale": "0.01"]))
        WebSocketManager.shared.subscribe(to: .MarketService, subscription: WebSocketSubscription(topic: "trade", symbol: "700", timeMode: "0", payload: ["scale": "0.01"]))
        WebSocketManager.shared.subscribe(to: .MarketService, subscription: WebSocketSubscription(topic: "realtime", symbol: "700", timeMode: "0", payload: ["scale": "0.01"]))
        WebSocketManager.shared.subscribe(to: .MarketService, subscription: WebSocketSubscription(topic: "kline_1m", symbol: "700", timeMode: "0", payload: ["scale": "0.01"]))
        
        
        // socket2的订阅
        WebSocketManager.shared.subscribe(to: .USStockOptions, subscription: WebSocketSubscription(topic: "trade", stock: "TSLA", symbol: "TSLA250328P00730000", timeMode: "0"))
        WebSocketManager.shared.subscribe(to: .USStockOptions, subscription: WebSocketSubscription(topic: "order", stock: "TSLA", symbol: "TSLA250328P00730000", timeMode: "0"))
        WebSocketManager.shared.subscribe(to: .USStockOptions, subscription: WebSocketSubscription(topic: "extend_snap", stock: "TSLA", symbol: "TSLA250328P00730000", timeMode: "0", payload: ["needSnap": "1"]))
        WebSocketManager.shared.subscribe(to: .USStockOptions, subscription: WebSocketSubscription(topic: "option_snapshot", stock: "TSLA", symbol: "TSLA250328P00730000", timeMode: "0", payload: ["needSnap": "1"]))
        WebSocketManager.shared.subscribe(to: .USStockOptions, subscription: WebSocketSubscription(topic: "option_status", stock: "TSLA", symbol: "TSLA250328P00730000", timeMode: "0"))
        
        // socket1和socket2的回调
        startListeningToQuotation()
    }
    
    func startListeningToQuotation() {
        WebSocketEventBus.shared.publisher(for: "realtime")
            .sink { [weak self] receivedPayload in
                // 在这里处理接收到的 "quotation" 事件的 payload
                print("Received quotation payload: \(receivedPayload)")
                self?.textView.text += "\n  \(receivedPayload)"
                
                // 你可以在这里根据 payload 的内容执行相应的操作
                if let symbol = receivedPayload["symbol"] as? String,
                   let price = receivedPayload["price"] as? Double {
                    print("Symbol: \(symbol), Price: \(price)")
                    // 更新你的 UI 或业务逻辑
                }
            }
            .store(in: &cancellables)
        
        WebSocketEventBus.shared.publisher(for: "kline_1m")
            .sink { [weak self] receivedPayload in
                // 在这里处理接收到的 "quotation" 事件的 payload
                print("Received quotation payload: \(receivedPayload)")
                self?.textView.text += "\n  \(receivedPayload)"
                
                // 你可以在这里根据 payload 的内容执行相应的操作
                if let symbol = receivedPayload["symbol"] as? String,
                   let price = receivedPayload["price"] as? Double {
                    print("Symbol: \(symbol), Price: \(price)")
                    // 更新你的 UI 或业务逻辑
                }
            }
            .store(in: &cancellables)
        
        WebSocketEventBus.shared.publisher(for: "trade")
            .sink { [weak self] receivedPayload in
                // 在这里处理接收到的 "quotation" 事件的 payload
                print("Received quotation payload: \(receivedPayload)")
                self?.textView.text += "\n  \(receivedPayload)"
                
                // 你可以在这里根据 payload 的内容执行相应的操作
                if let symbol = receivedPayload["symbol"] as? String,
                   let price = receivedPayload["price"] as? Double {
                    print("Symbol: \(symbol), Price: \(price)")
                    // 更新你的 UI 或业务逻辑
                }
            }
            .store(in: &cancellables)
        
        WebSocketEventBus.shared.publisher(for: "order")
            .sink { [weak self]  receivedPayload in
                // 在这里处理接收到的 "quotation" 事件的 payload
                print("Received quotation payload: \(receivedPayload)")
                self?.textView.text += "\n  \(receivedPayload)"
                
                // 你可以在这里根据 payload 的内容执行相应的操作
                if let symbol = receivedPayload["symbol"] as? String,
                   let price = receivedPayload["price"] as? Double {
                    print("Symbol: \(symbol), Price: \(price)")
                    // 更新你的 UI 或业务逻辑
                }
            }
            .store(in: &cancellables) // 将订阅存储在 cancellables 中，以便在不再需要时取消订阅
        
        WebSocketEventBus.shared.publisher(for: "option_status")
            .sink {  [weak self] receivedPayload in
                // 在这里处理接收到的 "quotation" 事件的 payload
                print("Received quotation payload: \(receivedPayload)")
                self?.textView.text += "\n  \(receivedPayload)"
                
                // 你可以在这里根据 payload 的内容执行相应的操作
                if let symbol = receivedPayload["symbol"] as? String,
                   let price = receivedPayload["price"] as? Double {
                    print("Symbol: \(symbol), Price: \(price)")
                    // 更新你的 UI 或业务逻辑
                }
            }
            .store(in: &cancellables) // 将订阅存储在 cancellables 中，以便在不再需要时取消订阅
        
        WebSocketService2?.observeTopic("order")
            .sink {  [weak self] receivedPayload in
                // 在这里处理接收到的 "quotation" 事件的 payload
                print("Received quotation payload: \(receivedPayload)")
                self?.textView.text += "\n  \(receivedPayload)"
                
                // 你可以在这里根据 payload 的内容执行相应的操作
                if let symbol = receivedPayload["symbol"] as? String,
                   let price = receivedPayload["price"] as? Double {
                    print("Symbol: \(symbol), Price: \(price)")
                    // 更新你的 UI 或业务逻辑
                }
            }
            .store(in: &cancellables) // 将订阅存储在 cancellables 中，以便在不再需要时取消订阅
        
        WebSocketService2?.observeTopic("option_status")
            .sink {  [weak self] receivedPayload in
                // 在这里处理接收到的 "quotation" 事件的 payload
                print("Received quotation payload: \(receivedPayload)")
                self?.textView.text += "\n  \(receivedPayload)"
                
                // 你可以在这里根据 payload 的内容执行相应的操作
                if let symbol = receivedPayload["symbol"] as? String,
                   let price = receivedPayload["price"] as? Double {
                    print("Symbol: \(symbol), Price: \(price)")
                    // 更新你的 UI 或业务逻辑
                }
            }
            .store(in: &cancellables) // 将订阅存储在 cancellables 中，以便在不再需要时取消订阅
    }
}
