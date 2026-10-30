// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Harmonize",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "Harmonize", targets: ["Harmonize"]),
        .library(name: "HarmonizeSemantics", targets: ["HarmonizeSemantics"]),
        .library(name: "HarmonizeUtils", targets: ["HarmonizeUtils"]),
        .executable(name: "harmonize-skills", targets: ["HarmonizeSkills"]),
        .plugin(name: "HarmonizeSkillsPlugin", targets: ["HarmonizeSkillsPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "601.0.1"..<"605.0.0"),
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
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax")
            ]
        ),
        .target(name: "HarmonizeUtils"),
        .target(
            name: "HarmonizeSkillsCore",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                "Yams"
            ]
        ),
        .executableTarget(name: "HarmonizeSkills", dependencies: ["HarmonizeSkillsCore"]),
        .plugin(
            name: "HarmonizeSkillsPlugin",
            capability: .command(
                intent: .custom(
                    verb: "harmonize-skills",
                    description: "Generates one agent skill (SKILL.md, one reference file per category and per rule) from the rule sources, without a build or a test run"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Writes the generated skills into the configured skills directory")
                ]
            ),
            dependencies: ["HarmonizeSkills"]
        ),
        .testTarget(name: "HarmonizeTests", dependencies: ["Harmonize"]),
        .testTarget(name: "HarmonizeSkillsCoreTests", dependencies: ["HarmonizeSkillsCore"]),
        .testTarget(
            name: "SemanticsTests",
            dependencies: [
                "HarmonizeSemantics",
                .product(name: "SwiftOperators", package: "swift-syntax"),
            ]
        )
    ]
)
