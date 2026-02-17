// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PingKitMacExample",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "PingKitMacExample",
            dependencies: [
                .product(name: "PingKit", package: "pingkit-swift"),
            ],
            path: "Sources"
        ),
    ]
)
