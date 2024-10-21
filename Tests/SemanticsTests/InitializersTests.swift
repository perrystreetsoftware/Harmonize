//
//  FunctionsTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import HarmonizeSemantics
import XCTest

final class InitializersTests: XCTestCase {
    private var sourceSyntax = """
    protocol Proto {
        init(param1: String, param2: String)
    }

    class InitializableProgram: Proto {
        required init(param1: String, param2: String) {}
        
        @objc init() {
            func hold() {}
            
            execute()
        }
        
        private func execute() {
            // run...
        }
    }

    struct Structure {
        var property: String
        
        init(property: String) {
            self.property = property
            
            var _ = "bar"
        }
        
        dynamic private init(property: String, value: Int) {
            self.property = property
        }
    }
    
    class ViewModel {
        @Published public var state: Int
        
        init(stateHandler: StateHandler) {
            self.state = 0
            stateHandler.$state.map { $0 * 2 }.assign(to: &$state)
            produceSideEffect()
        }
    
        func produceSideEffect() {
            // do something....
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
    
    func testParseInitializers() throws {
        let initializers = visitor.initializers
        XCTAssertEqual(initializers.count, 6)
    }
    
    func testParseInitializerModifiers() throws {
        let initializers = visitor.initializers
        let modifiers = initializers.flatMap { $0.modifiers }
        
        XCTAssertEqual(
            modifiers,
            [.required, .dynamic, .private]
        )
    }
    
    func testParseInitializerAttributes() throws {
        let initializers = visitor.initializers
        let attributes = initializers.flatMap { $0.attributes }.map { $0.annotation }
        
        XCTAssertEqual(
            attributes,
            [.objc]
        )
    }
    
    func testParseInitializersParams() throws {
        let initializers = visitor.initializers
        let params = initializers.flatMap { $0.parameters }
            .map { $0.name }
        
        XCTAssertEqual(params, ["param1", "param2", "param1", "param2", "property", "property", "value", "stateHandler"])
    }
    
    
    func testParseInitializersFunctions() throws {
        let initializers = visitor.initializers
        let functions = initializers.flatMap { $0.functions }
            .map { $0.name }
        
        XCTAssertEqual(functions, ["hold"])
    }
    
    func testParseInitializersProperties() throws {
        let initializers = visitor.initializers
        let variable = initializers.flatMap { $0.variables }.first
        
        XCTAssertEqual(variable?.name, "_")
        XCTAssertEqual(variable?.isOfInferredType, true)
        XCTAssertEqual(variable?.initializerClause?.value, "bar")
    }
    
    func testParseInitializersFunctionCalls() throws {
        let initializers = visitor.initializers
        let functionCalls = initializers.flatMap(\.functionCalls)
        
        XCTAssertEqual(functionCalls.count, 3)
    }
}
