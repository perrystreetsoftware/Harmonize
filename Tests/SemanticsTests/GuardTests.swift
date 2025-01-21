//
//  GuardTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import HarmonizeSemantics
import XCTest
import SwiftSyntax

final class GuardTests: XCTestCase {
    private var sourceSyntax = """
    public final class Klass {
        private var name: String = ""
        private var optional: String? = nil
    
        public func call() {
            guard !name.isEmpty else { 
                printError()
                return
            }
    
            closure { [weak self] in 
                guard let self else { return }
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
    
    func testParsesGuards() throws {
        let function = visitor.classes.first!.functions.first!
        XCTAssertTrue(function.guards().count == 1)
    }
    
    func testParsesGuardConditions() throws {
        let function = visitor.classes.first!.functions.first!
        let guarde = function.guards().first!
        
        XCTAssertTrue(guarde.conditions[0].isBooleanExpression)
    }
    
    func testParsesGuardElseBody() throws {
        let function = visitor.classes.first!.functions.first!
        let `guard` = function.guards().first!
        
        XCTAssertTrue(`guard`.body?.functionCalls.count == 1)
    }
    
    func testParsesGuardBinding() throws {
        let function = visitor.classes.first!.functions.first!
        let closure = function.functionCalls.first!.closure!
        
        XCTAssertTrue(closure.hasSelfReference)
        XCTAssertTrue(closure.guards().first!.conditions[0].isBindingToSelf)
    }
}
