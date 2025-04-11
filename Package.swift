？*
CHFWebSocketStarscream/
├── Package.swift
├── Sources/
│   └── CHFWebSocketStarscream/
│       └── WebSocketService/
│           ├── WebSocketManager.swift
│           ├── WebSocketEventBus.swift
│           └── WebSocketService.swift
│           ├── WebSocketServiceType.swift
│           ├── WebSocketSubscription.swift
│           └── WebSocketSubscriptionQueue.swift
*/


// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CHFWebSocketStarscream",
    platforms: [
        .iOS(.v13) // 根据你支持的最低版本修改
    ],
    products: [
        .library(
            name: "CHFWebSocketStarscream",
            targets: ["CHFWebSocketStarscream"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "CHFWebSocketStarscream",
            dependencies: [
                "Starscream"
            ],
            resources: [
                .process("Resources"),

            ]
            publicHeadersPath: nil
        )
    ]
)
