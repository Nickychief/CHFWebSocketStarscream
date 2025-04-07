//
//  HeartbeatScheduler.swift
//  CHFWebSocketStarscream
//
//  Created by 刘远明 on 2025/4/7.
//

import UIKit

//public class HeartbeatScheduler {
//    private var timer: Timer?
//    private weak var service: WebSocketService?
//
//    init(service: WebSocketService) {
//        self.service = service
//    }
//
//    func start() {
//        timer?.invalidate()
//        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
//            self?.service?.send(["event": "ping"])
//        }
//    }
//
//    func stop() {
//        timer?.invalidate()
//        timer = nil
//    }
//}
