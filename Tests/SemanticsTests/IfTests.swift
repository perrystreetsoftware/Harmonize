//
//  IfTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import HarmonizeSemantics
import XCTest
import SwiftSyntax

final class IfTests: XCTestCase {
    private var sourceSyntax = """
    public final class Klass {
        private var name: String = ""
        private var optional: String? = nil
    
        public func call() {
            if name.isEmpty {
                printError()
            } else if name.count { $0.isLetter } > 10 {
                self.anotherCall()
            } else {
                self.execute()
            }
    
            if let optional {
                self.execute()
            }
    
            closure { [weak self] in 
                if let self = self {
                
                }
            }
        }
    
        public func anotherCall() {}
        public func execute() {}
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
    
    func testParsesIfs() throws {
        let function = visitor.classes.first!.functions.first!
        XCTAssertTrue(function.ifs().count == 2)
    }
    
    func testParsesIfsConditions() throws {
        let function = visitor.classes.first!.functions.first!
        let `if` = function.ifs().first!
        XCTAssertTrue(`if`.conditions[0].isBooleanExpression)
    }
    
    func testParsesElseIf() throws {
        let function = visitor.classes.first!.functions.first!
        let elseIf = function.ifs().first!.elseIf!
        
        XCTAssertTrue(elseIf.conditions[0].isComparison == true)
        XCTAssertTrue(elseIf.functionCalls.count == 1)
    }
    
    func testParsesElse() throws {
        let function = visitor.classes.first!.functions.first!
        let `else` = function.ifs().first!.elseIf!.else!
        
        XCTAssertTrue(`else`.functionCalls.count == 1)
    }
    
    func testParsesOptionalBinding() throws {
        let function = visitor.classes.first!.functions.first!
        let `if` = function.ifs()[1]
        
        XCTAssertTrue(!`if`.isBindingToSelf)
        XCTAssertTrue(`if`.conditions.first!.isOptionalBinding)
    }
    
    func testParsesBindingToSelf() throws {
        let function = visitor.classes.first!.functions.first!
        let closure = function.functionCalls.first { $0.isClosure }!.closure!
        
        let `if` = closure.ifs()[0]
        
        XCTAssertTrue(`if`.isBindingToSelf)
    }
}
