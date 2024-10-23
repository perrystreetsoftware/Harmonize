//
//  ClassesTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import HarmonizeSemantics
import XCTest
import SwiftSyntax

final class ClassesTests: XCTestCase {
    private var sourceSyntax = """
    @objc
    public final class RootClass: NSObject, MyProtocol, @unchecked Sendable {
        var property: String = "x"
        let y: Int = 0
        
        private class NestedClass {
            func foo() {
                let make = 42
            }
        }
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
    
    func testParseClassesIncludingNested() throws {
        let classes = visitor.classes
        let classesNames = classes.map { $0.name }
        
        XCTAssertEqual(classes.count, 2)
        XCTAssertEqual(classesNames, ["RootClass", "NestedClass"])
    }
    
    func testParseInheritanceTypesNames() throws {
        let classes = visitor.classes
        let inheritanceTypes = classes.map { $0.inheritanceTypesNames }
        
        XCTAssertEqual(inheritanceTypes, [["NSObject", "MyProtocol", "Sendable"], []])
    }
    
    func testParseClassesVariables() throws {
        let classes = visitor.classes
        let variables = classes.flatMap { $0.variables }
        let names = variables.map { $0.name }
        let parent = variables.map { ($0.parent as? NamedDeclaration)?.name }
        let values = variables.compactMap { $0.initializerClause }.map { $0.value }
        
        XCTAssertEqual(variables.count, 2)
        XCTAssertEqual(names, ["property", "y"])
        XCTAssertEqual(parent, ["RootClass", "RootClass"])
        XCTAssertEqual(values, ["x", "0"])
    }
    
    func testParseClassesAttributes() throws {
        let classes = visitor.classes
        let attributes = classes.flatMap { $0.attributes }.map { $0.annotation }
        
        XCTAssertEqual(attributes.count, 1)
        XCTAssertEqual(attributes, [.objc])
    }
    
    func testParseClassesMemberFunctions() throws {
        let functions = visitor.classes
            .first { $0.name == "NestedClass" }?.functions ?? []
        
        XCTAssertEqual(functions.count, 1)
        XCTAssertEqual(functions.map { $0.name }, ["foo"])
        XCTAssertEqual(functions.map { $0.body?.content }, ["let make = 42"])
    }
}
