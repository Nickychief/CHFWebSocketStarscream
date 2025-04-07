//
//  CommondHandler.swift
//  CHFWebSocketStarscream
//
//  Created by Nikcy on 2025/4/3.
//

import Foundation

public extension Notification.Name {
    static let CHFWebsocketEventOption_Trade = Notification.Name.init(rawValue: "CHFWebsocketEventOption_Trade")
    static let CHFWebsocketEventOption_Order = Notification.Name.init(rawValue: "CHFWebsocketEventOption_Order")
    static let CHFWebsocketEventOption_ExtendSnap = Notification.Name.init(rawValue: "CHFWebsocketEventOption_ExtendSnap")
    static let CHFWebsocketEventOption_Snapshot = Notification.Name.init(rawValue: "CHFWebsocketEventOption_Snapshot")
    static let CHFWebsocketEventOption_Status: NSNotification.Name = Notification.Name.init("CHFWebsocketEventOption_Status")
}

class CHFCommandEventHandler: CHFCommandHandlerProtocol {
    init() {
        
    }
    
    func handleCommand(eventMap: [AnyHashable : Any]) {
        if let resultType = CHFDictionaryUnwrap(eventMap).get("topic").string() {
            let userInfo = CHFDictionaryUnwrap(eventMap).get("data").value as? [String: Any]
            let topic = CHFTopic(rawValue: resultType)
            switch topic {
            case .trade:
                NotificationCenter.default.post(name: .CHFWebsocketEventOption_Trade, object: nil, userInfo: userInfo)
            case .order:
                NotificationCenter.default.post(name: .CHFWebsocketEventOption_Order, object: nil, userInfo: userInfo)
            case .extend_snap:
                NotificationCenter.default.post(name: .CHFWebsocketEventOption_ExtendSnap, object: nil, userInfo: userInfo)
            case .option_snapshot:
                NotificationCenter.default.post(name: .CHFWebsocketEventOption_Snapshot, object: nil, userInfo: userInfo)
            case .option_status:
                NotificationCenter.default.post(name: .CHFWebsocketEventOption_Status, object: nil, userInfo: userInfo)
            case .none:
                break
            }
        } else {
            chf_print(.info, "------", "未处理的消息事件")
        }
    }
}

