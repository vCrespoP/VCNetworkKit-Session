// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "VCNetworkKit-Session",
    platforms: [
        .iOS(.v8),
        .tvOS(.v9),
        .watchOS(.v2),
        .macOS(.v10_10)
    ],
    products: [
        .library(
            name: "VCNetworkKit-Session",
            targets: ["VCNetworkKit-Session"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/vCrespoP/VCNetworkKit.git",
            from: "1.0.0"
        ),
    ],
    targets: [
        .target(
            name: "VCNetworkKit-Session",
            dependencies: ["VCNetworkKit"],
            path: "Sources"
        ),
        .testTarget(
            name: "VCNetworkKit-SessionTests",
            dependencies: ["VCNetworkKit-Session"],
            path: "Tests"
        ),
    ]
)
