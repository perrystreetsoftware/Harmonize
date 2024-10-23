//
//  FunctionsTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import HarmonizeSemantics
import XCTest

final class StructsTests: XCTestCase {
    private var sourceSyntax = """
    public struct MyStruct {
        public protocol MyStructProtocol {}
        
        public struct MyStructItem: MyStructProtocol {
            public let prop1: String
            public let prop2: String
        }
        
        public let property1: String
        public let property2: Int
        public let property3: Bool
        public let items: [MyStructItem]
        
        public func someFunction() -> Int { property2 + 2 }
    }

    @dynamicCallable
    public struct AttributedStruct {
        func dynamicallyCall(withArguments args: [Int]) -> Int {
            return args.reduce(0, +)
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
    
    func testParseStructsIncludingNested() throws {
        let structs = visitor.structs
        let structsNames = structs.map { $0.name }
        
        XCTAssertEqual(structs.count, 3)
        XCTAssertEqual(structsNames, ["MyStruct", "MyStructItem", "AttributedStruct"])
    }
    
    func testParseNestedStructs() throws {
        let structs = visitor.structs
        let nestedStructs = structs.filter { $0.parent != nil }
        XCTAssertEqual(nestedStructs.count, 1)
        
        let parent = nestedStructs.first?.parent as! Struct
        XCTAssertEqual(parent.name, "MyStruct")
    }
    
    func testParseInheritanceTypesNames() throws {
        let structs = visitor.structs
        let inheritanceTypes = structs.flatMap { $0.inheritanceTypesNames }
        
        XCTAssertEqual(inheritanceTypes, ["MyStructProtocol"])
    }
    
    func testParseStructsProperties() throws {
        let structs = visitor.structs
        let properties = structs.map { $0.variables }
        
        let names = properties.flatMap { $0.map { $0.name } }
        let types = properties.flatMap { $0.compactMap { $0.typeAnnotation } }.map { $0.name }
        
        XCTAssertEqual(names, ["property1", "property2", "property3", "items", "prop1", "prop2", ])
        XCTAssertEqual(types, ["String", "Int", "Bool", "[MyStructItem]", "String", "String"])
    }
    
    func testParseStructsAttributes() throws {
        let structs = visitor.structs
        let attributes = structs.flatMap { $0.attributes }
        
        XCTAssertEqual(attributes.count, 1)
        XCTAssertEqual(
            attributes.first?.annotation,
            .dynamicCallable
        )
    }
    
    func testParseStructsMemberFunctions() throws {
        let function = visitor.structs.first { $0.name == "MyStruct" }!.functions.first!
        XCTAssertEqual(function.name, "someFunction")
        XCTAssertEqual(function.body?.content, "property2 + 2")
    }

}
