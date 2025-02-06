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
}
