// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ATLASCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "ATLASCore", targets: ["ATLASCore"])
    ],
    targets: [
        .target(
            name: "ATLASCore",
            path: "ATLAS/Core",
            exclude: [
                // This engine recommends SwiftData-backed ExerciseRecord values
                // and is exercised by the iOS test target, not the pure Swift core.
                "ExerciseSimilarityEngine.swift"
            ]
        ),
        .testTarget(
            name: "ATLASCoreTests",
            dependencies: ["ATLASCore"],
            path: "Tests/ATLASCoreTests"
        )
    ]
)
