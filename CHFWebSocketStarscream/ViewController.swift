//
//  ViewController.swift
//  CHFWebSocketStarscream
//
//  Created by 刘远明 on 9/14/23.
//

import UIKit

class ViewController: UIViewController {
    
    deinit {
        ITApplicationReachablility?.stopNotifier()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "连接", style: .plain, target: self, action: #selector(connect))
        
        //        WebSocketManager1.shared.connect()
        //            
        //        // 延迟 3 秒等待连接成功后订阅
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        //            WebSocketManager.shared.subscribeToDepth(symbol: "300.700", scale: "0.01")
        //        }
        
        // 监听网络状态变化
//        startReachability()
//        
//        CHFWebSocketManager.shared.connect()
        // 延迟 3 秒等待连接成功后订阅
        // 订阅 TSLA 期权
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            CHFWebSocketManager.shared.subscribeToTrade(stock: "TSLA", symbol: "TSLA250328P00730000", timeMode: "0")
//        }
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            CHFWebSocketManager.shared.subscribeToOrder(stock: "TSLA", symbol: "TSLA250328P00730000", timeMode: "0")
//        }
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            CHFWebSocketManager.shared.subscribeToExtendSnap(stock: "TSLA", symbol: "TSLA250328P00730000", timeMode: "0", params: ["needSnap": "1"])
//        }
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            CHFWebSocketManager.shared.subscribeToOptionSnapshot(stock: "TSLA", symbol: "TSLA250328P00730000", timeMode: "0", params: ["needSnap": "1"])
//        }
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            CHFWebSocketManager.shared.subscribeToOptionStatus(stock: "TSLA", symbol: "TSLA250328P00730000", timeMode: "0")
//        }
    }
    
    public func startReachability() {
        ITApplicationReachablility = CHFReachability.init(hostname: "https://baidu.com")
        do {
            try ITApplicationReachablility?.startNotifier()
        } catch {
            
        }
    }
    
    @objc func connect() {
        self.navigationController?.pushViewController(TwoViewController(), animated: true)
    }
}
