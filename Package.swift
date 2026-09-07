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
        .library(name: "Store Standard Library Integration", targets: ["Store Standard Library Integration"]),
        .library(name: "Store Foundation Library Integration", targets: ["Store Foundation Library Integration"]),
        .library(name: "Store Test Support", targets: ["Store Test Support"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-index.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-difference.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-ordinal.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-cardinal.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-tagged.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Store",
            dependencies: [
                .product(name: "Index", package: "swift-index"),
                .product(name: "Ordinal", package: "swift-ordinal"),
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "Difference", package: "swift-difference"),
                .product(name: "Cardinal", package: "swift-cardinal"),
                .product(name: "Ordinal Standard Library Integration", package: "swift-ordinal"),
            ],
            path: "Sources/Store"
        ),
        .target(
            name: "Store Standard Library Integration",
            dependencies: [
                .target(name: "Store"),
            ],
            path: "Sources/Store Standard Library Integration"
        ),
        .target(
            name: "Store Foundation Library Integration",
            dependencies: [
                .target(name: "Store"),
                .target(name: "Store Standard Library Integration"),
            ],
            path: "Sources/Store Foundation Library Integration"
        ),
        .target(
            name: "Store Test Support",
            dependencies: [
                .target(name: "Store"),
                .product(name: "Index Test Support", package: "swift-index"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Store Tests",
            dependencies: [
                .target(name: "Store"),
                .target(name: "Store Test Support"),
                .product(name: "Difference", package: "swift-difference"),
                .product(name: "Cardinal", package: "swift-cardinal"),
                .product(name: "Cardinal Standard Library Integration", package: "swift-cardinal"),
                .product(name: "Index", package: "swift-index"),
                .product(name: "Ordinal", package: "swift-ordinal"),
                .product(name: "Ordinal Standard Library Integration", package: "swift-ordinal"),
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "Tagged Standard Library Integration", package: "swift-tagged"),
                .target(name: "Store Standard Library Integration"),
                .target(name: "Store Foundation Library Integration"),
            ],
            path: "Tests/Store Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    target.swiftSettings = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableExperimentalFeature("RawLayout"),
    ]
}
