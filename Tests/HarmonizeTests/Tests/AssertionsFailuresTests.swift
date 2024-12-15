//
//  AssertionsFailures.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import XCTest
import HarmonizeSemantics
import Harmonize

final class AssertionsFailuresTests: XCTestCase {
    override var testRunClass: AnyClass? {
        return Self.ExpectedFailureTestCaseRun.self
    }
    
    private let testCode = Harmonize.testCode().on("SampleApp")
    private let productionCode = Harmonize.productionCode().on("SampleApp")
    
    func testAssertEmptyFailsBecauseCollectionIsNotEmpty() throws {
        testCode.classes().assertEmpty()
    }
    
    func testAssertNotEmptyFailsBecauseCollectionIsEmpty() throws {
        [Class]().assertNotEmpty()
    }
    
    func testAssertTrueFailsBecauseConditionIsFalse() throws {
        testCode.classes().assertTrue { _ in
            false
        }
    }
    
    func testAssertFalseFailsBecauseConditionIsTrue() throws {
        testCode.classes().assertFalse { _ in
            true
        }
    }
    
    func testAssertCountFailsBecauseCollectionIsEmpty() throws {
        [Class]().assertCount(count: 3)
    }
}

internal extension AssertionsFailuresTests {
    /// Adapted from original source:
    /// https://medium.com/@matthew_healy/cuteasserts-dev-blog-1-wait-how-do-you-test-that-a-test-failed-37419eb33b49
    final class ExpectedFailureTestCaseRun: XCTestCaseRun {
        private var failed = false
        
        override func record(_ issue: XCTIssue) {
            failed = true
        }
        
        override func stop() {
            defer {
                failed = false
                super.stop()
            }
            
            guard failed else {
                super.record(.init(type: .assertionFailure, compactDescription: "Expected to fail but assertion passed."))
                return
            }
        }
    }
}
