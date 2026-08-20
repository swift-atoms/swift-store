// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-store-primitives",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "Store Reduction Primitives",
            targets: ["Store Reduction Primitives"]
        ),
        .library(
            name: "Store Reduction Primitives Test Support",
            targets: ["Store Reduction Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-primitives/swift-algebra-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-optic-primitives.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Store Reduction Primitives",
            dependencies: [
                .product(name: "Algebra Monoid Primitives", package: "swift-algebra-primitives"),
                .product(name: "Optic Primitives", package: "swift-optic-primitives"),
            ]
        ),
        .target(
            name: "Store Reduction Primitives Test Support",
            dependencies: [
                "Store Reduction Primitives",
                .product(name: "Algebra Monoid Primitives", package: "swift-algebra-primitives"),
                .product(name: "Optic Primitives", package: "swift-optic-primitives"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Store Reduction Primitives Tests",
            dependencies: [
                "Store Reduction Primitives",
                "Store Reduction Primitives Test Support",
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
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
