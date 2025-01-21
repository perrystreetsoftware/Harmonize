//
//  BodyTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import HarmonizeSemantics
import XCTest
import SwiftSyntax

final class BodyTests: XCTestCase {
    private var sourceSyntax = """
    public final class Klass {
        private static let Defaults = 999

        let value: Int
        let value2: String
        let closure: () -> Int
        let conditionalValue: Int

        public init(value: Int) {
            self.value = value // ref
            self.value = 2 // intLiteral
            value2 = "StringLiteral" // stringLiteral
            value2 = generateRandomNumber() // functionCall
            closure = { 9 }
            conditionalValue = if closure() < 9 { 9 } else { 0 } // ifCondition
            self.value = [1, 2].first ?? 0 // unsupported

            closureElsewhere { [weak self] in
                (self?.value ?? 0) * $0
            }
    
            listenToSomeHeavyData()
    
            if value > 2 {
                performSomeTask()
            }
    
            if closure() > 9 {
                doSomeOtherStuff()
            }
    
            switch value {
                case 9: 
                    print("Cool!")
                case 2:
                    print("Not so cool!")
                default:
                    print("Yeah I know nothing")
            }
        }
        
        func closureElsewhere(f: (Int) -> Void) {
            f(42)
        }
    
        func complexFunc() {
            publisher.filter { $0 }
                .flatMap { procedure() }
                .flatMap { $0 > 1 ? $0.mapped() : self.call() }
                .sink { }
        }
    
        func call() {}
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
    
    func testParsesAssignments() throws {
        let initializer = visitor.classes.first!.initializers.first!
        let assignments = initializer.body!.infixExpressions
        let lhs = assignments.map(\.leftOperand)
        let rhs = assignments.map(\.rightOperand)
        
        let expectedTargets = [
            "self.value",
            "self.value",
            "value2",
            "value2",
            "closure",
            "conditionalValue",
            "self.value"
        ]
        
        XCTAssertEqual(assignments.count, 7)
        XCTAssertEqual(lhs, expectedTargets)
        
        // RightOperand isn't yet equatable
        rhs.enumerated().forEach { index, rhs in
            if case let .literalIntValueText(text) = rhs {
                XCTAssertEqual(text, "2")
            }
            
            if case let .literalStringValue(text) = rhs {
                XCTAssertEqual(text, "StringLiteral")
            }
            
            if case let .functionCall(functionCall) = rhs {
                XCTAssertEqual(functionCall.call, "generateRandomNumber")
            }
            
            if case let .closure(closure) = rhs {
                XCTAssertEqual(closure.body!.description, "9")
            }
            
            if case let .ifCondition(ifCondition) = rhs {
                XCTAssertEqual(ifCondition.conditions.map { $0.asString }, ["closure() < 9"])
            }
            
            if case let .reference(name, _) = rhs {
                XCTAssertEqual(name, "value")
            }
            
            if case let .unsupported(text) = rhs {
                XCTAssertEqual(text, "[1, 2].first ?? 0")
            }
        }
    }
    
    func testParsesFunctionCalls() throws {
        let initializer = visitor.classes.first!.initializers.first!
        let functionCalls = initializer.body!.functionCalls
        
        XCTAssertEqual(functionCalls.count, 2)
        XCTAssertEqual(functionCalls[0].call, "closureElsewhere")
        XCTAssertTrue(functionCalls[0].closure!.isCapturingWeak(valueOf: "self"))
        XCTAssertEqual(functionCalls[1].call, "listenToSomeHeavyData")
    }
    
    func testParsesIfs() throws {
        let initializer = visitor.classes.first!.initializers.first!
        let ifs = initializer.body!.ifs
        
        XCTAssertEqual(ifs.count, 2)
        XCTAssertEqual(ifs[0].conditions.map(\.asString), ["value > 2"])
        XCTAssertEqual(ifs[1].conditions.map(\.asString), ["closure() > 9"])
    }
    
    func testParsesSwitches() throws {
        let initializer = visitor.classes.first!.initializers.first!
        let switches = initializer.body!.switches
        
        XCTAssertEqual(switches.count, 1)
        XCTAssertEqual(switches.first!.cases.count, 3)
    }
    
    func testParsesStatements() throws {
        let initializer = visitor.classes.first!.initializers.first!
        let statements = initializer.body!.statements
        // Statements are more top-level and a raw representation of ifs, switches, assignments etc.
        XCTAssertEqual(statements.count, 12)
    }
    
    func testParsesIfBodyHasSelfReference() throws {
        let function = visitor.classes.first!.functions[1]
        XCTAssertTrue(function.body?.hasAnySelfReference == true)
        XCTAssertTrue(function.body?.hasAnyClosureWithSelfReference == true)
    }
}
