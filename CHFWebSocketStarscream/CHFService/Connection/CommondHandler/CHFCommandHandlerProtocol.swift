//
//  CommandHandlerProtocol.swift
//  CHFWebSocketStarscream
//
//  Created by Nikcy on 2025/4/3.
//

import UIKit

protocol CHFCommandHandlerProtocol {
    func handleCommand(eventMap: [AnyHashable: Any])
}
