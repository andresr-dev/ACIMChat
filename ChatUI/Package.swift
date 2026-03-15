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
  targets: [
    .target(
      name: "ChatUI",
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
  ]
)
