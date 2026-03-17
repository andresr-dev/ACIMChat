// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "ChatUI",
  platforms: [.iOS(.v26)],
  products: [
    .library(
      name: "ChatUI",
      targets: ["ChatUI"]
    ),
  ],
  dependencies: [
    .package(name: "Chat", path: "../Chat"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.25.2")
  ],
  targets: [
    .target(
      name: "ChatUI",
      dependencies: [
        "Chat",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ],
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
