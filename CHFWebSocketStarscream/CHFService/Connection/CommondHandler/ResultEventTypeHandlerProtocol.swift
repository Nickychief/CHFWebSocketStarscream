//
//  ResultEventTypeHandlerProtocol.swift
//  CHFWebSocketStarscream
//
//  Created by 刘远明 on 2025/4/3.
//

import UIKit

protocol ResultEventTypeHandlerProtocol {
    func handleEvent(eventMap: [AnyHashable: Any])
}

open class CHFDictionaryUnwrap {
    public let value: Any?
    public init(_ dic: Any?) {
        self.value = dic
    }
    
    public func get(_ key: String) -> CHFDictionaryUnwrap {
        if let dic = value as? [String: Any] {
            return CHFDictionaryUnwrap(dic[key])
        }
        return CHFDictionaryUnwrap(nil)
    }
    
    public func string() -> String? {
        return (value as? String)
    }
    
    public func int() -> Int? {
        return (value as? Int)
    }
}
