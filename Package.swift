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
        .library(name: "Store", targets: ["Store"]),
        .library(name: "Store Protocol", targets: ["Store Protocol"]),
        .library(name: "Store Operations", targets: ["Store Operations"]),
        .library(name: "Store Initialization", targets: ["Store Initialization"]),
        .library(name: "Store Ledgered", targets: ["Store Ledgered"]),
        .library(name: "Store Inline", targets: ["Store Inline"]),
        .library(name: "Store Split", targets: ["Store Split"]),
        .library(name: "Store Generational", targets: ["Store Generational"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-index.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-affine.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-ordinal.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Store",
            dependencies: []
        ),
        .target(
            name: "Store Protocol",
            dependencies: [
                .target(name: "Store"),
                .product(name: "Index", package: "swift-index"),
            ]
        ),
        .target(
            name: "Store Operations",
            dependencies: [
                .target(name: "Store Protocol"),
                .product(name: "Index", package: "swift-index"),
                .product(
                    name: "Affine Standard Library Integration",
                    package: "swift-affine"
                ),
                .product(
                    name: "Ordinal Standard Library Integration",
                    package: "swift-ordinal"
                ),
            ]
        ),
        .target(
            name: "Store Initialization",
            dependencies: [
                .target(name: "Store"),
                .product(name: "Index", package: "swift-index"),
            ]
        ),
        .target(
            name: "Store Ledgered",
            dependencies: [
                .target(name: "Store"),
                .target(name: "Store Protocol"),
                .target(name: "Store Initialization"),
            ]
        ),
        .target(
            name: "Store Inline",
            dependencies: [
                .target(name: "Store"),
                .target(name: "Store Protocol"),
                .target(name: "Store Initialization"),
                .target(name: "Store Ledgered"),
                .product(name: "Index", package: "swift-index"),
                .product(
                    name: "Affine Standard Library Integration",
                    package: "swift-affine"
                ),
                .product(
                    name: "Ordinal Standard Library Integration",
                    package: "swift-ordinal"
                ),
            ],
            swiftSettings: [
                .enableExperimentalFeature("RawLayout")
            ]
        ),
        .target(
            name: "Store Split",
            dependencies: [
                .target(name: "Store"),
                .target(name: "Store Protocol"),
                .product(name: "Index", package: "swift-index"),
            ]
        ),
        .target(
            name: "Store Generational",
            dependencies: [
                .target(name: "Store"),
            ]
        ),
        .target(
            name: "Store Test Support",
            dependencies: [
                .target(name: "Store"),
                .product(name: "Index Test Support", package: "swift-index"),
            ],
            path: "Tests/Store Support"
        ),
        .testTarget(
            name: "Store Tests",
            dependencies: [
                .target(name: "Store"),
            ]
        ),
        .testTarget(
            name: "Store Protocol Tests",
            dependencies: [
                .target(name: "Store Protocol"),
                .target(name: "Store Test Support"),
            ]
        ),
        .testTarget(
            name: "Store Initialization Tests",
            dependencies: [
                .target(name: "Store Initialization"),
                .target(name: "Store Test Support"),
            ]
        ),
        .testTarget(
            name: "Store Ledgered Tests",
            dependencies: [
                .target(name: "Store Ledgered"),
            ]
        ),
        .testTarget(
            name: "Store Inline Tests",
            dependencies: [
                .target(name: "Store Inline"),
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

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem
}
