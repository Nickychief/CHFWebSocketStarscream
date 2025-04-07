//
//  CHFEvent.swift
//  CHFWebSocketStarscream
//
//  Created by Nikcy on 2025/4/3.
//

import UIKit

public enum CHFEvent: String {
    case sub
    case cancel
}

public enum CHFTopic: String {
    case trade
    case order
    case extend_snap
    case option_snapshot
    case option_status
}
