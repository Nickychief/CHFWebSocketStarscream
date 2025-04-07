//
//  TwoViewController.swift
//  CHFWebSocketStarscream
//
//  Created by 刘远明 on 2025/4/7.
//

import UIKit

class TwoViewController: UIViewController {
    let textView = UITextView()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // ✅ 调试所有订阅事件
//        let cancellable = WebSocketManager.shared.subject
//            .sink { payload in
//                print("🔥 收到事件：\(payload)")
//            }
        
        let ordercancellable = WebSocketManager.shared
            .observeTopic("order")
            .sink { payload in
                print("🔥 Received depth data: \(payload)")
                self.textView.text += "\n  \(payload)"
            }
        
        let option_statuscancellable = WebSocketManager.shared
            .observeTopic("option_status")
            .sink { payload in
                print("🔥 Received depth data: \(payload)")
                self.textView.text += "\n  \(payload)"
            }
        //        cancellable.cancel() // 取消订阅
        
        WebSocketManager.shared.registerService(webSocketServiceType: .MarketService)
        WebSocketManager.shared.registerService(webSocketServiceType: .USStockOptions)
        
        WebSocketManager.shared.subscribe(to: .MarketService, subscription: WebSocketSubscription(topic: "depth", symbol: "301.700", timeMode: "0", payload: ["scale": "0.01"]))
        WebSocketManager.shared.subscribe(to: .USStockOptions, subscription: WebSocketSubscription(topic: "order", stock: "TSLA", symbol: "TSLA250328P00730000", timeMode: "0"))
        WebSocketManager.shared.subscribe(to: .USStockOptions, subscription: WebSocketSubscription(topic: "option_status", stock: "TSLA", symbol: "TSLA250328P00730000", timeMode: "0"))
    }
}
