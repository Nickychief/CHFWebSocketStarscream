//
//  WebSocketEventBus.swift
//  CHFWebSocketStarscream
//
//  Created by Nikcy on 2025/4/7.
//

import UIKit
import Combine

public class WebSocketEventBus {
    static let shared = WebSocketEventBus()
    private var subjects: [String: PassthroughSubject<[String: Any], Never>] = [:]

    func publisher(for topic: String) -> AnyPublisher<[String: Any], Never> {
        let subject = subjects[topic] ?? {
            let newSubject = PassthroughSubject<[String: Any], Never>()
            subjects[topic] = newSubject
            return newSubject
        }()
        return subject.eraseToAnyPublisher()
    }

    func send(topic: String, payload: [String: Any]) {
        subjects[topic]?.send(payload)
    }
}
