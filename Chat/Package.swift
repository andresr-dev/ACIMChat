// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Chat",
    platforms: [.macOS(.v26)],
    products: [
        .library(
            name: "Chat",
            targets: ["Chat"]
        ),
    ],
    dependencies: [
      .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.25.2")
    ],
    targets: [
        .target(
            name: "Chat",
            dependencies: [
              .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            swiftSettings: [
              .defaultIsolation(MainActor.self)
            ]
        ),
        .testTarget(
          name: "ChatTests",
          dependencies: ["Chat"]
        )
    ],
    swiftLanguageModes: [.v6]
)
