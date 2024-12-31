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
}
