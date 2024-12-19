//
//  FunctionsTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import HarmonizeSemantics
import XCTest

final class FunctionsTests: XCTestCase {
    private var sourceSyntax = """
    func noArgLabelsFunction(_ p1: String, _ p2: String) {
        
    }

    func argLabelsFunction(p1: String, p2: String) {
        func nestedFunction() -> String {
            p1 + p2
        }
    }

    func customArgLabelsFunction(param1 p1: String, param2: String) {
        
    }

    func mixedLabeledArgsFunction(p1: String, _ p2: String) {
        
    }

    func variadic(args: String...) {
        
    }

    func noLabelVariadic(_ args: String...) {
        
    }

    func noLabelAtAll(_:String) {
    }

    func withReturnClause() -> String {
        let cal = "cal"
        noLabelAtAll(cal)
        return "return"
    }

    func withPublished() -> AnyPublisher<Void, Never> {
        $foo.flatMap { _ -> AnyPublisher<Void, Never> in
            Just(()).eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }

    func withGenericVariance<T, R>(_ t: T, _ f: (T) -> R) -> R {
        f(t)
    }

    func withWhereClause<T>(_ t: T) -> Int where T: Sendable {
        42
    }

    func withParametersInitializers(param: String = "Value") -> Int {
        42
    }

    func withParametersAttributes(f: @autoclosure () -> Void) -> Int {
        f()
        return 42
    }

    public func fetchAllTheThings() async -> Int {
        return 42
    }

    private func privateFunc() {}
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
    
    func testParseTopLevelFunctionsOnly() throws {
        let functions = visitor.functions
        let functionNames = functions.map { $0.name }
        
        XCTAssertEqual(functions.count, 16)
        XCTAssertEqual(
            functionNames, 
            [
                "noArgLabelsFunction",
                "argLabelsFunction",
                "nestedFunction",
                "customArgLabelsFunction",
                "mixedLabeledArgsFunction",
                "variadic",
                "noLabelVariadic",
                "noLabelAtAll",
                "withReturnClause",
                "withPublished",
                "withGenericVariance",
                "withWhereClause",
                "withParametersInitializers",
                "withParametersAttributes",
                "fetchAllTheThings",
                "privateFunc"
            ]
        )
    }

    func testParseFunctionReturnClauses() throws {
        let functions = visitor.functions
        let returnClauses = functions.map { $0.returnClause?.typeAnnotation?.name }
        
        XCTAssertEqual(
            returnClauses,
            [
                nil,
                nil,
                "String",
                nil,
                nil,
                nil,
                nil,
                nil,
                "String",
                "AnyPublisher<Void, Never>",
                "R",
                "Int",
                "Int",
                "Int",
                "Int",
                nil
            ]
        )
    }
    
    func testParseFunctionParametersWithNoArgLabels() throws {
        let function = named("noArgLabelsFunction")
        let parameters = function.parameters
        let labels = parameters.map { $0.label }
        XCTAssertEqual(labels, ["_", "_"])
    }
    
    func testParseFunctionParametersWithArgLabels() throws {
        let function = named("argLabelsFunction")
        let parameters = function.parameters
        let labels = parameters.map { $0.label }
        XCTAssertEqual(labels, ["p1", "p2"])
    }
    
    func testParseFunctionParametersWithCustomArgLabels() throws {
        let function = named("customArgLabelsFunction")
        let parameters = function.parameters
        
        let labels = parameters.map { $0.label }
        let names = parameters.map { $0.name }
        
        XCTAssertEqual(labels, ["param1", "param2"])
        XCTAssertEqual(names, ["p1", "param2"])
    }
    
    func testParseFunctionParametersWithMixedArgLabels() throws {
        let function = named("mixedLabeledArgsFunction")
        let parameters = function.parameters
        
        let labels = parameters.map { $0.label }
        let names = parameters.map { $0.name }
        
        XCTAssertEqual(labels, ["p1", "_"])
        XCTAssertEqual(names, ["p1", "p2"])
    }
    
    func testParseVariadicFunctionParameters() throws {
        let variadicArg = named("variadic").parameters.first!
        let noLabelVariadicArg = named("noLabelVariadic").parameters.first!
        
        XCTAssertEqual(variadicArg.name, "args")
        XCTAssertEqual(variadicArg.label, "args")
        XCTAssertEqual(variadicArg.typeAnnotation?.name, "String")
        XCTAssertEqual(variadicArg.isVariadic, true)
        XCTAssertEqual(noLabelVariadicArg.label, "_")
    }
    
    func testParseFunctionParametersWithNoNameAndLabels() throws {
        let unnamedParam = named("noLabelAtAll").parameters.first!
        XCTAssertEqual(unnamedParam.name, "_")
        XCTAssertEqual(unnamedParam.label, "_")
        XCTAssertEqual(unnamedParam.typeAnnotation?.name, "String")
    }
    
    func testParseFunctionParametersWithReturnClause() throws {
        let returnClause = named("withReturnClause").returnClause
        XCTAssertEqual(returnClause?.typeAnnotation?.name, "String")
    }
    
    func testParseFunctionParametersWithGenericClause() throws {
        let genericClause = named("withGenericVariance").genericClause
        XCTAssertEqual(genericClause, "<T, R>")
    }
    
    func testParseFunctionParametersWithWhereClause() throws {
        let whereClause = named("withWhereClause").whereClause
        XCTAssertEqual(whereClause, "where T: Sendable")

    }
    
    func testParseFunctionParametersWithInitializer() throws {
        let param = named("withParametersInitializers").parameters.first!
        XCTAssertEqual(param.initializerClause?.value, "Value")
    }
    
    func testParseFunctionParametersWithAttributes() throws {
        let attributedParam = named("withParametersAttributes").parameters.first!
        XCTAssertEqual(attributedParam.attributes.first!.annotation, .autoclosure)
    }
    
    func testParseFunctionModifiers() throws {
        let asyncfunc = named("fetchAllTheThings")
        let privateFunc = named("privateFunc")
        
        XCTAssertEqual(asyncfunc.modifiers, [.public])
        XCTAssertEqual(privateFunc.modifiers, [.private])
    }
    
    func testParseFunctionBodyContent() throws {
        let functionBody = named("withReturnClause").body?.content
        let content = """
        let cal = "cal"
        noLabelAtAll(cal)
        return "return"
        """
        XCTAssertEqual(functionBody, content)
    }

    func testParseFunctionBody() throws {
        let functionBody = named("withReturnClause").body!
        let statements = functionBody.statements
        let functionCall = functionBody.functionCalls.first!
        
        XCTAssertEqual(
            statements.map(\.description),
            [
                "let cal = \"cal\"",
                "noLabelAtAll(cal)",
                "return \"return\""
            ]
        )
        XCTAssertEqual(functionCall.call, "noLabelAtAll")
    }

    func testParseFunctionBodyFunctionCalls() throws {
        let function = named("withReturnClause")
        XCTAssertEqual(function.invokes("noLabelAtAll"), true)
    }

    func testTokens() throws {
        let function = named("withPublished")
        let fooTokens = function.functionCalls.first!.tokens(startingWith: "$foo")
        let flatMapTokens = function.functionCalls.first!.tokens(startingWith: "flatMap")

        XCTAssertEqual(fooTokens.count, 1)
        XCTAssertEqual(fooTokens.first?.value, "$foo")
        XCTAssertEqual(fooTokens.first?.position, 591)
        XCTAssertEqual(flatMapTokens.count, 1)
        XCTAssertEqual(flatMapTokens.first?.value, "flatMap")
        XCTAssertEqual(flatMapTokens.first?.position, 601)
    }

    private func named(_ name: String) -> Function {
        visitor.functions.first { $0.name == name }!
    }
}
