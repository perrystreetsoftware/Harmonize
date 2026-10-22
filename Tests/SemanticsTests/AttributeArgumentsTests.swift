//
//  AttributeArgumentsTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2026. All Rights Reserved.
//

import Foundation
import HarmonizeSemantics
import XCTest
import SwiftSyntax

/// swift-syntax 602 parses several attributes as a plain argument list (swiftlang/swift-syntax#3028),
/// so their arguments differ between 601 and 602+.
final class AttributeArgumentsTests: XCTestCase {
    private var sourceSyntax = """
    @convention(c) func convention() {}
    @_semantics("foo") func semantics() {}
    @_private(sourceFile: "X.swift") func privateImport() {}
    @_expose(Cxx, "name") func expose() {}
    @_unavailableFromAsync(message: "m") func unavailableFromAsync() {}
    @abi(func abiName()) func abi() {}
    @specialized(where T == Int) func specialized<T>(_ value: T) {}
    """.parsed()

    private lazy var visitor = {
        DeclarationsCollector(
            sourceCodeLocation: SourceCodeLocation(
                sourceFilePath: nil,
                sourceFileTree: sourceSyntax
            )
        )
    }()

    override func setUp() {
        visitor.walk(sourceSyntax)
    }

    private func arguments(of function: String) -> [String] {
        let attribute = visitor.functions.first { $0.name == function }?.attributes.first
        return attribute?.arguments.map { [$0.label, $0.value].compactMap { $0 }.joined(separator: ": ") } ?? []
    }

    func testConventionArguments() throws {
        XCTAssertEqual(arguments(of: "convention"), ["c"])
    }

    func testArgumentsParsedAsArgumentList() throws {
        #if canImport(SwiftSyntax602)
        XCTAssertEqual(arguments(of: "semantics"), ["foo"])
        XCTAssertEqual(arguments(of: "privateImport"), ["sourceFile: X.swift"])
        XCTAssertEqual(arguments(of: "expose"), ["Cxx", "name"])
        XCTAssertEqual(arguments(of: "unavailableFromAsync"), ["message: m"])
        #else
        XCTAssertEqual(arguments(of: "semantics"), ["\"foo\""])
        XCTAssertEqual(arguments(of: "privateImport"), ["sourceFile"])
        XCTAssertEqual(arguments(of: "expose"), ["Cxx, \"name\""])
        XCTAssertEqual(arguments(of: "unavailableFromAsync"), [])
        #endif
    }

    func testABIArguments() throws {
        #if canImport(SwiftSyntax602)
        XCTAssertEqual(arguments(of: "abi"), ["func abiName()"])
        #endif
    }

    func testSpecializedArguments() throws {
        #if canImport(SwiftSyntax603)
        XCTAssertEqual(arguments(of: "specialized"), ["where T == Int"])
        #endif
    }
}
