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
    
    func testAssertTrueFailsBecauseStrictModeIsEnabled() throws {
        [Class]().assertTrue(strict: true) { _ in
            true
        }
    }
    
    func testAssertFalseFailsBecauseConditionIsTrue() throws {
        testCode.classes().assertFalse { _ in
            true
        }
    }
    
    func testAssertFalseFailsBecauseStrictModeIsEnabled() throws {
        [Class]().assertFalse(strict: true) { _ in
            false
        }
    }
    
    func testAssertCountFailsBecauseCollectionIsEmpty() throws {
        [Class]().assertCount(count: 3)
    }

    func testAssertTrueWithBaselineFailsBecauseBaselineEntryIsStale() throws {
        // FetchUserUseCase is in the baseline but it passes the condition,
        // which means it's a stale baseline entry and should be reported.
        productionCode.classes().assertTrue(baseline: ["FetchUserUseCase"]) { _ in
            true
        }
    }

    func testAssertFalseWithBaselineFailsBecauseBaselineEntryIsStale() throws {
        // UserConverter is in the baseline but it returns false from the condition,
        // which means it's a stale baseline entry and should be reported.
        productionCode.classes().assertFalse(baseline: ["UserConverter"]) { _ in
            false
        }
    }

    func testAssertEmptyWithBaselineFailsBecauseNonBaselinedElementIsPresent() throws {
        // UserConverter is not in the baseline so it is not excluded from the empty check,
        // causing the assertion to fail.
        productionCode.classes()
            .filter { !$0.name.starts(with: "Fetch") }
            .assertEmpty(baseline: ["UserRepository"])
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
