// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PingKit",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "PingKit",
            targets: ["PingKit"]
        ),
    ],
    targets: [
        .target(
            name: "PingKit",
            path: "Sources/PingKit"
        ),
        .testTarget(
            name: "PingKitTests",
            dependencies: ["PingKit"],
            path: "Tests/PingKitTests"
        ),
    ]
)
