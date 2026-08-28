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
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-algebra.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-optic.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Store",
            dependencies: [
                .product(name: "Algebra Monoid", package: "swift-algebra"),
                .product(name: "Optic", package: "swift-optic"),
            ]
        ),
        .testTarget(
            name: "Store Tests",
            dependencies: [
                .target(name: "Store"),
            ]
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
