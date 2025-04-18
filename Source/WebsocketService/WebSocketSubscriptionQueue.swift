//
//  WebSocketSubscriptionQueue.swift
//  CHFWebSocketStarscream
//
//  Created by Nikcy on 2025/4/7.
//

import UIKit

final class WebSocketSubscriptionQueue {
    private var subscriptions: Set<WebSocketSubscription> = []
    private var priorityQueue: [WebSocketSubscription] = []
    private let queue = DispatchQueue(label: "subscription.queue")
    
    deinit {
        chf_print(.info, "\(self) -- \(#function)")
    }

    func add(_ subscription: WebSocketSubscription) {
        queue.sync {
            if !subscriptions.contains(subscription) {
                subscriptions.insert(subscription)
                priorityQueue.append(subscription)
                priorityQueue.sort { $0.priority > $1.priority }
            }
        }
    }

    func cancel(_ subscription: WebSocketSubscription) {
        queue.sync {
            subscriptions.remove(subscription)
            priorityQueue.removeAll { $0 == subscription }
        }
    }

    func next() -> WebSocketSubscription? {
        queue.sync {
            return priorityQueue.first
        }
    }

    func all() -> [WebSocketSubscription] {
        queue.sync {
            return Array(priorityQueue)
        }
    }

    func clear() {
        queue.sync {
            subscriptions.removeAll()
            priorityQueue.removeAll()
        }
    }
}
