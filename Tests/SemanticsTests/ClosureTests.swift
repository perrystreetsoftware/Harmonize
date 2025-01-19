//
//  ClosureTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import HarmonizeSemantics
import XCTest
import SwiftSyntax

final class ClosuresTests: XCTestCase {
    private var sourceSyntax = """
    public final class Klass {
        private var name: String = ""
    
        public func call() {
            execute { param in self.name.doSomething(param) }
    
            execute { [weak self] param in
                self.name.doSomething(param)
            }
    
            execute { [unowned self] param in self.name.doSomething(param) }
    
            executeWithReturnValue { param -> Bool in param.contains("true") }
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
    
    func testParsesClosures() throws {
        let function = visitor.classes.first!.functions.first!
        XCTAssertTrue(function.functionCalls.allSatisfy(\.isClosure))
    }
    
    func testParsesClosuresParameters() throws {
        let function = visitor.classes.first!.functions.first!
        XCTAssertEqual(
            ["param", "param", "param", "param"],
            function.functionCalls.compactMap(\.closure).flatMap(\.parameters)
        )
    }
    
    func testParsesClosuresReturnClause() throws {
        let function = visitor.classes.first!.functions.first!
        XCTAssertEqual(
            [String(describing: Bool.self)],
            function.functionCalls
                .compactMap { $0.closure?.returnClause?.typeAnnotation?.annotation }
        )
    }
    
    func testParsesIfClosuresHasSelfReferences() throws {
        let function = visitor.classes.first!.functions.first!
        XCTAssertTrue(
            function.functionCalls[0...2].allSatisfy { $0.closure?.hasSelfReference ?? false }
        )
    }
    
    func testParsesCaptures() throws {
        let function = visitor.classes.first!.functions.first!
        let closures = function.functionCalls.compactMap(\.closure)
        
        let capturesSelf = closures.contains { $0.isCapturing(valueOf: "self") }
        let capturesWeakSelf = closures.contains { $0.isCapturingWeak(valueOf: "self") }
        let capturesUnownedSelf = closures.contains { $0.isCapturingUnowned(valueOf: "self") }
        
        XCTAssertTrue(capturesSelf && capturesWeakSelf && capturesUnownedSelf)
    }
}
