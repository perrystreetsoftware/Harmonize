// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Harmonize",
    platforms: [.macOS(.v13), .iOS(.v13)],
    products: [
        .library(name: "Harmonize", targets: ["Harmonize"]),
        .library(name: "HarmonizeSemantics", targets: ["HarmonizeSemantics"]),
        .library(name: "HarmonizeUtils", targets: ["HarmonizeUtils"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.1"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.3")
    ],
    targets: [
        .target(
            name: "Harmonize",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                "Yams",
                "HarmonizeSemantics",
                "HarmonizeUtils"
            ]
        ),
        .target(
            name: "HarmonizeSemantics",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]
        ),
        .target(name: "HarmonizeUtils"),
        .testTarget(name: "HarmonizeTests", dependencies: ["Harmonize"]),
        .testTarget(
            name: "SemanticsTests",
            dependencies: [
                "HarmonizeSemantics",
                .product(name: "SwiftOperators", package: "swift-syntax"),
            ]
        )
    ]
)
