//
//  FunctionCallTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import HarmonizeSemantics
import Harmonize
import XCTest

final class FunctionCallTests: XCTestCase {
    let sampleCode = Harmonize.on("Filters/FunctionCalls")
    
    func testFunctionCallInvokes() throws {
        // e.g every spec must have a `describe`
        sampleCode.classes()
            .functions()
            .withName("spec")
            .assertTrue {
                $0.invokes("beforeEach")
            }
    }
    
    func testFunctionCallInvokesIncludingClosures() {
        // e.g every `describe` must call `TestFactory().withValue(1)` on its `beforeEach`
        // so `invokes` must be able to do a nested check here.
        sampleCode.classes()
            .functions()
            .withName("spec")
            .assertTrue {
                $0.invokes("TestFactory().withValue", includeClosures: true) &&
                $0.invokes("something.onTap", includeClosures: true)
            }
    }
    
    func testFunctionCallClosures() {
        sampleCode.classes()
            .functions()
            .withName("spec")
            .withClosures(named: "beforeEach") { closure in
                closure.invokes("nonExistentCall()")
            }
            .assertEmpty()
    }
    
    func testBodyNestedFunctionCallClosures() {
        sampleCode.classes()
            .functions()
            .withName("spec")
            .assertTrue(message: "Every beforeEach must call setUp()") { function in
                function.closures(named: "beforeEach")
                    .allSatisfy { $0.invokes("setUp()") }
            }
    }
}
