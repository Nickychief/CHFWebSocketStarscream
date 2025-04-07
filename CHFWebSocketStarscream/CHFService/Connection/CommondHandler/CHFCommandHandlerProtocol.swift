//
//  CommandHandlerProtocol.swift
//  CHFWebSocketStarscream
//
//  Created by 刘远明 on 2025/4/3.
//

import UIKit

protocol CHFCommandHandlerProtocol {
    func handleCommand(eventMap: [AnyHashable: Any])
}
