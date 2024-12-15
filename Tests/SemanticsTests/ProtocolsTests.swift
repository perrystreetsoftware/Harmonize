//
//  ProtocolTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import HarmonizeSemantics
import XCTest

final class ProtocolTests: XCTestCase {
    private var sourceSyntax = """
    protocol DataRepresentable {
        var property: String { get }
        func someMethod()
    }

    @objc protocol Configurable {
        @objc optional func optionalMethod()
    }

    protocol NetworkRequestable: Configurable {
        func someMethod()
    }

    protocol ClassOnlyProtocol: AnyObject {
        func someMethod()
    }

    class NestedProtocolInClass {
        protocol NamedDelegate {
            var name: String { get set }
        }
    }

    struct NestedProtocolInStruct {
        protocol NamedDelegate {
            var name: String { get set }
        }
    }

    @rethrows // unsupported
    @objc
    protocol Throwable {
        
    }
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
    
    func testParseProtocols() throws {
        let protocols = visitor.protocols
        let names = protocols.map { $0.name }
        
        XCTAssertEqual(protocols.count, 7)
        XCTAssertEqual(
            names,
            [
                "DataRepresentable",
                "Configurable",
                "NetworkRequestable",
                "ClassOnlyProtocol",
                "NamedDelegate",
                "NamedDelegate",
                "Throwable"
            ]
        )
    }
    
    func testParseProtocolsProperties() throws {
        let protocols = visitor.protocols
        let properties = protocols.flatMap { $0.variables }
        
        XCTAssertEqual(properties.count, 3)
        XCTAssertEqual(properties.map { $0.name }, ["property", "name", "name"])
    }
    
    func testParseNestedProtocols() throws {
        let protocols = visitor.protocols
        XCTAssertEqual(protocols.count, 7)
    }
    
    func testParseNestedClassesProtocols() throws {
        let nestedProtocol = visitor.protocols.first { $0.parent != nil }!
        
        XCTAssertEqual(nestedProtocol.name, "NamedDelegate")
        
        let parent = nestedProtocol.parent as! Class
        XCTAssertEqual(parent.name, "NestedProtocolInClass")
    }
    
    func testParseNestedStructsProtocols() throws {
        let nestedProtocol = visitor.protocols.last { $0.parent != nil }!
        
        XCTAssertEqual(nestedProtocol.name, "NamedDelegate")
        
        let parent = nestedProtocol.parent as! Struct
        XCTAssertEqual(parent.name, "NestedProtocolInStruct")
    }
    
    func testParseProtocolsAttributes() throws {
        let attributedProtocols = visitor.protocols.filter { !$0.attributes.isEmpty }
        XCTAssertEqual(attributedProtocols.count, 2)
        XCTAssertEqual(
            attributedProtocols.flatMap { $0.attributes }.map { $0.name },
            ["objc", "rethrows", "objc"]
        )
    }
    
    func testParseProtocolMemberFunctions() throws {
        let function = visitor.protocols.first { $0.name == "NetworkRequestable" }!
            .functions.first!
        
        XCTAssertEqual(function.name, "someMethod")
        XCTAssertEqual(function.body, nil)
        XCTAssertEqual(function.returnClause, nil)
        XCTAssertTrue(function.parameters.isEmpty)
    }
}
