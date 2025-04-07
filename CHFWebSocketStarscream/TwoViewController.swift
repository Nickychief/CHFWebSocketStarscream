//
//  TwoViewController.swift
//  CHFWebSocketStarscream
//
//  Created by 刘远明 on 2025/4/7.
//

import UIKit
import Combine

class TwoViewController: UIViewController {
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
        
        WebSocketService1 = WebSocketManager.shared.registerService(webSocketServiceType: .MarketService)
        WebSocketService2 = WebSocketManager.shared.registerService(webSocketServiceType: .USStockOptions)
        
        WebSocketManager.shared.subscribe(to: .MarketService, subscription: WebSocketSubscription(topic: "depth", symbol: "301.700", timeMode: "0", payload: ["scale": "0.01"]))
//        WebSocketManager.shared.subscribe(to: .USStockOptions, subscription: WebSocketSubscription(topic: "order", stock: "TSLA", symbol: "TSLA250328P00730000", timeMode: "0"))
//        WebSocketManager.shared.subscribe(to: .USStockOptions, subscription: WebSocketSubscription(topic: "option_status", stock: "TSLA", symbol: "TSLA250328P00730000", timeMode: "0"))
        
        startListeningToQuotation()
    }
    
    func startListeningToQuotation() {
        // ✅ 调试所有订阅事件
//        WebSocketEventBus.shared.
//            .sink { payload in
//                print("🔥 收到事件：\(payload)")
//        } .store(in: &cancellables)
        
        WebSocketEventBus.shared.publisher(for: "depth")
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
