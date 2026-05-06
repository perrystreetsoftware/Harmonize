//
//  AssertionsSourceCodeTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import XCTest
import Harmonize
import HarmonizeSemantics

final class AssertionsSourceCodeTests: XCTestCase {
    let productionCode = Harmonize.productionCode().sources()
    let testCode = Harmonize.testCode().sources()

    func testAssertEmpty() throws {
        [SwiftSourceCode]().assertEmpty()
    }

    func testAssertNotEmpty() throws {
        testCode.assertNotEmpty()
    }

    func testAssertTrue() throws {
        testCode.assertTrue { _ in
            true
        }
    }

    func testAssertTrueWithStrictMode() throws {
        testCode.assertTrue(strict: true) { _ in
            true
        }
    }

    func testAssertFalse() throws {
        testCode.assertFalse { _ in
            false
        }
    }

    func testAssertFalseWithStrictMode() throws {
        testCode.assertFalse(strict: true) { _ in
            false
        }
    }

    func testAssertCount() throws {
        productionCode
            .withName("AccessorBlocksProviding.swift")
            .assertCount(count: 1)
    }

    func testAssertTrueWithBaselineSkipsBaselineSourceFile() throws {
        // UseCases.swift fails the condition (no "Repositories" suffix) but is in the baseline,
        // so it is silently skipped. Repositories.swift is not baselined and passes.
        Harmonize.productionCode().on("SampleApp").sources()
            .assertTrue(baseline: ["Models.swift", "UseCases.swift"]) {
                $0.fileName?.hasSuffix("Repositories.swift") == true
            }
    }

    func testAssertFalseWithBaselineSkipsBaselineSourceFile() throws {
        // Repositories.swift passes the condition but is in the baseline,
        // so it is silently skipped. UseCases.swift is not baselined and correctly returns false.
        Harmonize.productionCode().on("SampleApp").sources()
            .assertFalse(baseline: ["Repositories.swift"]) {
                $0.fileName?.hasSuffix("Repositories.swift") == true
            }
    }

    func testAssertEmptyWithBaselineSkipsBaselineSourceFile() throws {
        // UseCases.swift is in the baseline so it is excluded from the empty check.
        // Filtering to only UseCases.swift first means no non-baselined elements remain.
        Harmonize.productionCode().on("SampleApp").sources()
            .filter { $0.fileName == "UseCases.swift" }
            .assertEmpty(baseline: ["UseCases.swift"])
    }
}
