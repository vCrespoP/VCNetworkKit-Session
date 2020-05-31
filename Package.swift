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
    dependencies: [ ],
    targets: [
        .target(
            name: "VCNetworkKit-Session",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "VCNetworkKit-SessionTests",
            dependencies: ["VCNetworkKit-Session"],
            path: "Tests"
        ),
    ]
)
