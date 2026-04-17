// swift-tools-version: 6.2

import PackageDescription

let sharedSwiftSettings: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

let package = Package(
    name: "AnjiBridge",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "AnkiKit", targets: ["AnkiKit"]),
        .library(name: "AnkiProto", targets: ["AnkiProto"]),
        .library(name: "AnkiBackend", targets: ["AnkiBackend"]),
        .library(name: "AnkiServices", targets: ["AnkiServices"]),
        .library(name: "AnkiClients", targets: ["AnkiClients"]),
        .library(name: "AnkiSync", targets: ["AnkiSync"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.28.0"),
    ],
    targets: [
        // MARK: - Rust Bridge (prebuilt XCFramework)
        .binaryTarget(
            name: "AnkiRustLib",
            path: "AnkiRust.xcframework"
        ),

        // MARK: - Protobuf Types
        .target(
            name: "AnkiProto",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ],
            swiftSettings: sharedSwiftSettings
        ),

        // MARK: - Rust FFI Wrapper
        .target(
            name: "AnkiBackend",
            dependencies: [
                "AnkiRustLib",
                "AnkiProto",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
            ],
            swiftSettings: sharedSwiftSettings
        ),

        // MARK: - Domain Types
        .target(
            name: "AnkiKit",
            swiftSettings: sharedSwiftSettings
        ),

        // MARK: - Backend Service Layer
        .target(
            name: "AnkiServices",
            dependencies: [
                "AnkiKit",
                "AnkiBackend",
                "AnkiProto",
                "AnkiSync",
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "Logging", package: "swift-log"),
            ],
            swiftSettings: sharedSwiftSettings
        ),

        // MARK: - App-Facing Client Layer
        .target(
            name: "AnkiClients",
            dependencies: [
                "AnkiKit",
                "AnkiServices",
                "AnkiSync",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "Logging", package: "swift-log"),
            ],
            swiftSettings: sharedSwiftSettings
        ),

        // MARK: - Credential Storage
        .target(
            name: "AnkiSync",
            dependencies: [
                "AnkiKit",
            ],
            swiftSettings: sharedSwiftSettings
        ),

        // MARK: - Tests
        .testTarget(
            name: "AnkiKitTests",
            dependencies: ["AnkiKit"],
            swiftSettings: sharedSwiftSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)
