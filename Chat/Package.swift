// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Chat",
    platforms: [.macOS(.v26), .iOS(.v26)],
    products: [
        .library(
            name: "Chat",
            targets: ["Chat"]
        ),
    ],
    dependencies: [
      .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.25.2"),
      .package(
        url: "https://github.com/pointfreeco/swift-snapshot-testing",
        from: "1.19.0"
      )
    ],
    targets: [
        .target(
            name: "Chat",
            dependencies: [
              .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .testTarget(
          name: "ChatTests",
          dependencies: [
            "Chat",
            .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
            .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
          ],
          swiftSettings: [
            .enableExperimentalFeature("StrictConcurrency")
          ]
        )
    ],
    swiftLanguageModes: [.v6]
)
