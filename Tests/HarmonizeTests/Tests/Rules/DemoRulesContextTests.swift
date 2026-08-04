//
//  DemoRulesContextTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2026. All Rights Reserved.
//

import Foundation
import Harmonize
import XCTest

/// The shape of the tests a project adopting a catalog would write.
///
/// ```bash
/// HARMONIZE_UPDATE_CONTEXT=1 swift test --filter DemoRulesContextTests
/// ```
final class DemoRulesContextTests: XCTestCase {
    private static let contextPath = "Tests/Fixtures/GeneratedContext/DEMO_RULES.md"

    func testAgentInstructionsAreInSyncWithTheRules() {
        DemoRules.syncContext(
            at: Self.contextPath,
            title: "Demo Architecture Rules"
        )
    }

    func testRuleExamplesInThoseInstructionsAreAccurate() {
        DemoRules.assertExamples()
    }

    func testCatalogIsValid() {
        DemoRules.assertRulesAreValid()
    }
}
