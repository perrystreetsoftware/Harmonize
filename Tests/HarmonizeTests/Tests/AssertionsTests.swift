//
//  Assertions.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import XCTest
import Harmonize
import HarmonizeSemantics

final class AssertionsTests: XCTestCase {
    let productionCode = Harmonize.productionCode().on("SampleApp")
    let testCode = Harmonize.testCode().on("SampleApp")
    
    func testAssertEmpty() throws {
        [Class]().assertEmpty()
    }
    
    func testAssertNotEmpty() throws {
        testCode.classes().assertNotEmpty()
    }
    
    func testAssertTrue() throws {
        testCode.classes().assertTrue { _ in
            true
        }
    }
    
    func testAssertTrueWithStrictMode() throws {
        testCode.classes().assertTrue(strict: true) { _ in
            true
        }
    }
    
    func testAssertFalse() throws {
        testCode.classes().assertFalse { _ in
            false
        }
    }
    
    func testAssertFalseWithStrictMode() throws {
        testCode.classes().assertFalse(strict: true) { _ in
            false
        }
    }
    
    func testAssertCount() throws {
        productionCode.classes().assertCount(count: 4)
    }

    func testAssertTrueWithBaselineSkipsBaselineEntryByName() throws {
        // UserConverter and UserRepository fail the condition (no "Fetch" prefix) but are
        // in the baseline, so they are silently skipped rather than reported as failures.
        // FetchUserUseCase and FetchUserDataInternalUseCase are not baselined and pass.
        productionCode.classes().assertTrue(baseline: ["UserConverter", "UserRepository"]) {
            $0.name.starts(with: "Fetch")
        }
    }

    func testAssertTrueWithBaselineSkipsBaselineEntryByFilename() throws {
        // FetchUserUseCase, FetchUserDataInternalUseCase, and UserConverter (in UseCases.swift)
        // fail the condition but are suppressed by the filename baseline.
        // UserRepository (in Repositories.swift) is not baselined and passes the condition,
        // confirming non-baselined elements are still evaluated normally.
        productionCode.classes().assertTrue(baseline: ["UseCases.swift"]) {
            $0.name.hasSuffix("Repository")
        }
    }

    func testAssertFalseWithBaselineSkipsBaselineEntryByName() throws {
        // FetchUserUseCase and FetchUserDataInternalUseCase pass the condition (name starts with "Fetch")
        // but are in the baseline, so they are silently skipped rather than reported as failures.
        // UserConverter and UserRepository are not baselined and correctly return false.
        productionCode.classes().assertFalse(baseline: ["FetchUserUseCase", "FetchUserDataInternalUseCase"]) {
            $0.name.starts(with: "Fetch")
        }
    }

    func testAssertEmptyWithBaselineSkipsBaselineEntries() throws {
        // FetchUserUseCase and FetchUserDataInternalUseCase are in the baseline so they are
        // excluded from the empty check. UserConverter and UserRepository are not baselined
        // and would cause a failure — so we filter to only the Fetch classes first.
        productionCode.classes()
            .filter { $0.name.starts(with: "Fetch") }
            .assertEmpty(baseline: ["FetchUserUseCase", "FetchUserDataInternalUseCase"])
    }
}
