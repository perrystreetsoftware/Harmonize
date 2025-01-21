//
//  FunctionCallTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import HarmonizeSemantics
import XCTest
import SwiftSyntax

final class FunctionCallTests: XCTestCase {
    private var sourceSyntax = """
    public final class SampleTest: QuickSpec {
        override class func spec() {
            describe("SampleTestCase") {
                beforeEach {
                    TestFactory().withValue(1)
                }

                Given("something") {
                    Then("there is something that will happen") {
                        expect(expectation) == .willHappen
                    }
    
                    When("it happens") {
                        beforeEach {
                            something.onTap()
                        }
                        
                        Then("I see it finally happens") {
                            expect(expectation) == .isHappening
                        }
                    }
                }
            }
    
            SomeTestFactory()
                .callNumberOne()
                .filter { $0 > $1 }
                .callNumberTwo()
        
            simpleFuncCall()
    
            self.execute()
    
            funcCall { } add: { call() }
    
            memberAccess.funcCall { self.execute() }
    
                SomeTestFactory()
                    .map { ($0, 1) }
                    .filter { $0 > $1 }
                    .callNumberTwo()
        }
    
        func execute()
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
    
    private var sampleTestClass: Class {
        visitor.classes.first!
    }
    
    private var specFunction: Function {
        sampleTestClass.functions.first!
    }
    
    override func setUp() {
        visitor.walk(sourceSyntax)
    }
    
    func testParsingTopLevelFunctionCall() {
        let describe = specFunction.functionCalls.first!
        XCTAssertTrue(describe.call == "describe")
    }
    
    func testParsingFunctionCallWithArguments() {
        let describe = specFunction.functionCalls.first!
        let arguments = describe.arguments

        XCTAssertTrue(arguments.count == 1)
        XCTAssertEqual("\"SampleTestCase\"", arguments.first!.value)
    }
    
    func testParsingFunctionCallClosure() {
        let describe = specFunction.functionCalls.first!
        XCTAssertTrue(describe.isClosure)
    }
    
    func testParsingInnerFunctionCalls() {
        let describe = specFunction.functionCalls.first!
        let calls = describe.functionCalls.map(\.call)
        XCTAssertEqual(["beforeEach", "Given"], calls)
    }
    
    func testParsingInlineFunctionCallExpression() {
        let inlineFuncCall = specFunction.functionCalls[1]
        XCTAssertEqual(
            "SomeTestFactory.callNumberOne.filter.callNumberTwo",
            inlineFuncCall.inlineCallExpression
        )
        
        // It represents a tree
        XCTAssertEqual(inlineFuncCall.call, "callNumberTwo")
        
        // It parses inline calls individually
        XCTAssertEqual(inlineFuncCall.inlineCalls.first!.call, "SomeTestFactory")
        XCTAssertEqual(
            ["SomeTestFactory", "callNumberOne", "filter", "callNumberTwo"],
            inlineFuncCall.inlineCalls.map(\.call)
        )
    }
    
    func testParsingFunctionCall() {
        let funcCall = specFunction.functionCalls[2]
        XCTAssertEqual("simpleFuncCall", funcCall.call)
        XCTAssertEqual("simpleFuncCall", funcCall.inlineCallExpression)
        XCTAssertEqual(true, funcCall.inlineCalls.isEmpty)
    }
    
    func testParsingFunctionWithSelfReference() {
        let funcCall = specFunction.functionCalls[3]
        XCTAssertTrue(funcCall.isSelfReference)
    }
    
    func testParsingAdditionalClosures() {
        let funcCall = specFunction.functionCalls[4]
        XCTAssertEqual("call", funcCall.additionalClosures.first!.functionCalls.first!.call)
    }
    
    func testParsingFunctionCallHasClosureWithSelfRef() {
        let funcCall = specFunction.functionCalls[5]
        XCTAssertTrue(funcCall.hasClosureWithSelfReference)
    }
    
    func testParsingFunctionCallInlineClosures() {
        let funcCall = specFunction.functionCalls[6]
        XCTAssertTrue(funcCall.inlineClosures.count == 2)
    }
}
