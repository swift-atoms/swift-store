// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-store",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "Store",
            targets: ["Store"]
        ),
        .library(
            name: "Store Standard Library Integration",
            targets: ["Store Standard Library Integration"]
        ),
        .library(
            name: "Store Apple Foundation Integration",
            targets: ["Store Apple Foundation Integration"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Store",
            dependencies: []
        ),
        .target(
            name: "Store Standard Library Integration",
            dependencies: ["Store"]
        ),
        .target(
            name: "Store Apple Foundation Integration",
            dependencies: [
                "Store",
                "Store Standard Library Integration",
            ]
        ),
        .testTarget(
            name: "Store Tests",
            dependencies: ["Store"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
