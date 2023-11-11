// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Regulate",
    platforms: [
        .iOS(.v14),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "Regulate",
            targets: ["Regulate"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Regulate",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "RegulateTests",
            dependencies: ["Regulate"],
            path: "Tests"
        ),
    ]
)
