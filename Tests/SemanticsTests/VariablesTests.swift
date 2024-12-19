//
//  VariablesTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import HarmonizeSemantics
import XCTest

final class VariablesTests: XCTestCase {
    private var sourceSyntax = """
    var property = "a"
    let immutable: String = "string"
    public var nullable: String? = nil

    var inlineProperty1: Int = 2, inlineProperty2: String? = "b"

    class ExampleClass {
        var a, b, c, d: Double
        
        init(a: Double, b: Double, c: Double, d: Double) {
            self.a = a
            self.b = b
            self.c = c
            self.d = d
        }
    }

    class MyClassType {
        private let value: Int
        
        init(value: Int) {
            self.value = value
        }
    }

    class Main {
        private let myType: MyClassType = MyClassType(value: 2)
        private let myType2: MyClassType
        
        init() {
            self.myType2 = MyClassType(value: 3)
        }
    }

    class Properties {
        private var example1: String = ""
        public var example2: String = ""
        internal var example3: String = ""
        fileprivate var example4: String = ""
        open var example5: String = ""
        public weak var example6: Properties?
        unowned var example7: Properties?
        fileprivate lazy var example8: String = { "" }()
        final let example9: String = ""
        @available(*, renamed: "example11") @objc static let example10: Int = 0
        var example11: Int { 9 }
        var example12: Int = 2
        var example13: Int {
            get {
                print("a")
                return example12
            }
            set { example12 = newValue }
        }
    }

    class MyViewModel: ObservableObject {
        @Published public var state: Int = 0
        @Published public private(set) var locked: Bool = false
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
    
    func testParseVariablesWithOptionalTypes() throws {
        let optionalVariables = visitor.variables.filter { $0.isOptional }
        XCTAssertEqual(optionalVariables.count, 4)
    }
    
    func testParseSingleLineMultipleVariables() throws {
        let exampleClass = visitor.classes.first { $0.name == "ExampleClass" }!
        let variables = exampleClass.variables
        
        XCTAssertEqual(
            variables.map { $0.name },
            ["a", "b", "c", "d"]
        )
    }
    
    func testSingleLineMultipleVariablesAreOfTheSameType() throws {
        let exampleClass = visitor.classes.first { $0.name == "ExampleClass" }!
        let variables = exampleClass.variables
        
        XCTAssert(
            variables.map { $0.typeAnnotation?.name }.allSatisfy { $0 == "Double" }
        )
    }
    
    func testParseCustomTypeVariables() throws {
        let mainClass = visitor.classes.first { $0.name == "Main" }!
        let variables = mainClass.variables
        
        XCTAssertEqual(
            variables.map { $0.typeAnnotation?.name },
            ["MyClassType", "MyClassType"]
        )
    }
    
    func testParseCustomTypeVariablesInitializer() throws {
        let mainClass = visitor.classes.first { $0.name == "Main" }!
        let variables = mainClass.variables
        
        XCTAssertEqual(
            variables.map { $0.initializerClause?.value },
            ["MyClassType(value: 2)", nil]
        )
    }
    
    func testParseVariablesModifiers() throws {
        let variables = visitor.variables.filter { ($0.parent as? Class)?.name == "Properties" }
        
        let modifiers = variables.map { $0.modifiers }
        
        let expectedModifiers: [[Modifier]] = [
            [.private],
            [.public],
            [.internal],
            [.fileprivate],
            [.open],
            [.public, .weak],
            [.unowned],
            [.fileprivate, .lazy],
            [.final],
            [.static],
            [],
            [],
            []
        ]
        
        XCTAssertEqual(modifiers, expectedModifiers)
    }
    
    func testParseVariablesAttributes() throws {
        let variables = visitor.variables
        let attributes = variables.flatMap { $0.attributes }.map { $0.annotation }
        
        XCTAssertEqual(attributes, [.available, .objc, .published, .published])
    }
    
    func testParseVariablesAccessorsBodyContent() throws {
        let variables = visitor.variables
        let accessors = variables.flatMap { $0.accessors }.map { $0.body?.content }

        let accessor1 = """
        print("a")
        return example12
        """
        let accessor2 = "example12 = newValue"
        XCTAssertEqual(accessors.count, 2)
        XCTAssertEqual(accessors, [accessor1, accessor2])
    }

    func testParseVariablesAccessorsBodyLines() throws {
        let variables = visitor.variables
        let bodies = variables.flatMap { $0.accessors }.compactMap { $0.body }

        XCTAssertEqual(bodies[0].functionCalls.count, 1)
        XCTAssertEqual(bodies[0].statements.count, 2)
        XCTAssertEqual(bodies[1].assignments.count, 1)
    }

    func testParseVariablesGetterBody() throws {
        let variables = visitor.variables
        let getter = variables.compactMap { $0.getter?.body?.content }

        XCTAssertEqual(getter.count, 1)
        XCTAssertEqual(getter, ["9"])
    }
    
    func testParseVariablesAccessorsModifier() throws {
        let variables = visitor.variables
        let accessors = variables.flatMap { $0.accessors }.map { $0.modifier }
        
        XCTAssertEqual(accessors.count, 2)
        XCTAssertEqual(accessors, [.get, .set])
    }
    
    func testParseVariablesWrapper() throws {
        let variables = visitor.variables.filter { ($0.parent as? Class)?.name == "MyViewModel" }
        let attributes = variables.flatMap { $0.attributes }

        XCTAssertEqual(attributes.count, 2)
        XCTAssertEqual(attributes.map { $0.annotation }, [.published, .published])
    }
    
    func testParseVariablesAccessorsModifiers() throws {
        let variables = visitor.variables
            .filter { ($0.parent as? Class)?.name == "MyViewModel" }
        
        let modifiers = variables.flatMap { $0.modifiers }.map { $0}
        
        XCTAssertEqual(modifiers.count, 3)
        XCTAssertEqual(modifiers, [.public, .public, .privateSet])
    }
}
