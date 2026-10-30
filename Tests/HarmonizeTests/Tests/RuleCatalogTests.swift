//
//  RuleCatalogTests.swift
//  Harmonize
//
//  Copyright 2026 Perry Street Software Inc.

//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at

//  http://www.apache.org/licenses/LICENSE-2.0

//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import HarmonizeSemantics
import XCTest
@testable import Harmonize

final class RuleCatalogTests: XCTestCase {
    private var fileURL: URL!
    private var source: SwiftSourceCode!

    override func setUpWithError() throws {
        RuleCatalog.reset()
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("RuleCatalogTests-\(UUID().uuidString)")
            .appendingPathComponent("Sources/CatalogFixture/GoodViewModel.swift")
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try """
        import Foundation

        final class GoodViewModel: BaseViewModel {
            let value: Int = 0
        }
        """.write(to: fileURL, atomically: true, encoding: .utf8)
        source = try XCTUnwrap(SwiftSourceCode(url: fileURL))
    }

    override func tearDown() {
        RuleCatalog.reset()
        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent().deletingLastPathComponent())
    }

    func testPassingAssertionRegistersItsRule() throws {
        let rule = makeRule(
            id: "viewmodels-inherit-base",
            title: "ViewModels must inherit from BaseViewModel.",
            category: "viewmodel",
            rationale: "Lifecycle handling lives in the base class.",
            howToFix: "Declare the class as `final class MyViewModel: BaseViewModel`.",
            badExample: "final class MyViewModel {}",
            goodExample: "final class MyViewModel: BaseViewModel {}"
        )

        HarmonizeReporting.withReporter(JSONReporter()) {
            source.classes().assertTrue(rule: rule) { $0.inherits(from: "BaseViewModel") }
        }

        XCTAssertEqual(RuleCatalog.entries.count, 1)
        let entry = try XCTUnwrap(RuleCatalog.entries.first)
        XCTAssertEqual(entry.rule, rule)
        XCTAssertTrue(entry.definedIn.hasSuffix("RuleCatalogTests.swift"))
    }

    func testFailingAssertionsAlsoRegisterAcrossAssertionKinds() throws {
        let reporter = JSONReporter()
        HarmonizeReporting.withReporter(reporter) {
            source.classes().assertFalse(rule: makeRule(id: "no-final-classes")) { _ in true }
            source.classes().assertEmpty(rule: makeRule(id: "no-classes-at-all"))
            [source!].assertTrue(rule: makeRule(id: "files-import-foundation")) { file in
                file.imports().contains { $0.name == "Foundation" }
            }
        }

        XCTAssertEqual(
            RuleCatalog.entries.map(\.rule.id),
            ["no-final-classes", "no-classes-at-all", "files-import-foundation"]
        )
        XCTAssertEqual(reporter.entries.count, 2)
    }

    func testRegistrationIsIdempotentAndSuffixesCollidingIds() throws {
        let first = RuleCatalog.register(makeRule(id: "some-rule", rationale: "First."), definedIn: "Rules.swift")
        let conflicting = RuleCatalog.register(makeRule(id: "some-rule", rationale: "Second."), definedIn: "Rules.swift")
        let reEvaluated = RuleCatalog.register(makeRule(id: "some-rule", rationale: "First."), definedIn: "Rules.swift")

        XCTAssertEqual(first.id, "some-rule")
        XCTAssertEqual(conflicting.id, "some-rule-2")
        XCTAssertEqual(reEvaluated.id, "some-rule")
        XCTAssertEqual(RuleCatalog.entries.map(\.rule.id), ["some-rule", "some-rule-2"])
    }

    func testIdDerivesFromDefiningFileName() throws {
        let rule = makeRule(rationale: "Derived id.")
        XCTAssertEqual(rule.id, "rule-catalog-tests")
    }

    func testDerivedIdFlowsSuffixedIntoViolations() throws {
        let reporter = JSONReporter()
        HarmonizeReporting.withReporter(reporter) {
            source.classes().assertTrue(rule: makeRule(rationale: "First rule.")) { _ in false }
            source.classes().assertTrue(rule: makeRule(rationale: "Second rule.")) { _ in false }
        }

        XCTAssertEqual(reporter.entries.map(\.ruleId), ["rule-catalog-tests", "rule-catalog-tests-2"])
        XCTAssertEqual(RuleCatalog.entries.map(\.rule.id), ["rule-catalog-tests", "rule-catalog-tests-2"])
    }

    func testCatalogJSONRoundTrips() throws {
        RuleCatalog.register(
            makeRule(
                id: "some-rule",
                title: "Some title.",
                category: "tests",
                badExample: "bad",
                goodExample: "good"
            ),
            definedIn: "SomeRule.swift"
        )

        let decoded = try JSONDecoder().decode([RuleCatalog.Entry].self, from: RuleCatalog.jsonData())
        XCTAssertEqual(decoded, RuleCatalog.entries)
        XCTAssertEqual(decoded.first?.rule.category, "tests")
        XCTAssertEqual(decoded.first?.rule.goodExample, "good")
        XCTAssertEqual(decoded.first?.rule.disclosure, .progressive)
    }

    private enum FixtureCategory: String, RuleCategory {
        case viewmodel
        var categoryName: String { rawValue }
        var categoryDescription: String { "Rules for ViewModels." }
    }

    func testTypedCategoryAndDisclosureRoundTrip() throws {
        RuleCatalog.register(
            Rule(
                id: "typed-rule",
                title: "",
                category: FixtureCategory.viewmodel,
                disclosure: .deferred,
                rationale: "",
                howToFix: "",
                badExample: "",
                goodExample: ""
            ),
            definedIn: "TypedRule.swift"
        )

        let decoded = try JSONDecoder().decode([RuleCatalog.Entry].self, from: RuleCatalog.jsonData())
        XCTAssertEqual(decoded.first?.rule.category, "viewmodel")
        XCTAssertEqual(decoded.first?.rule.disclosure, .deferred)
    }

    func testCompositeReporterForwardsToAllChildren() throws {
        let first = JSONReporter()
        let second = JSONReporter()

        HarmonizeReporting.withReporter(CompositeReporter([first, second])) {
            source.classes().assertTrue(rule: makeRule(id: "always-fails")) { _ in false }
            [Class]().assertTrue(strict: true) { _ in true }
        }

        XCTAssertEqual(first.entries, second.entries)
        XCTAssertEqual(first.entries.map(\.kind), [.violation, .assertion])
    }

    func testDefaultReporterIsPlainXCTestWithoutEnvironment() {
        let reporter = EnvironmentOutputs.makeDefaultReporter(environment: [:])
        XCTAssertTrue(reporter is XCTestReporter)
    }

    func testDefaultReporterCollectsJSONWhenViolationsFileRequested() throws {
        let previousViolationsReporter = EnvironmentOutputs.violationsReporter
        defer { EnvironmentOutputs.violationsReporter = previousViolationsReporter }

        let reporter = EnvironmentOutputs.makeDefaultReporter(
            environment: [EnvironmentOutputs.violationsFileKey: "/tmp/unused.json"]
        )

        XCTAssertTrue(reporter is CompositeReporter)
        XCTAssertNotNil(EnvironmentOutputs.violationsReporter)
    }

    func testWriteOutputsWritesViolationsAndCatalogFiles() throws {
        let outputDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("RuleCatalogTests-Outputs-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: outputDirectory) }

        let violationsURL = outputDirectory.appendingPathComponent("violations.json")
        let catalogURL = outputDirectory.appendingPathComponent("catalog.json")

        let previousViolationsReporter = EnvironmentOutputs.violationsReporter
        defer { EnvironmentOutputs.violationsReporter = previousViolationsReporter }

        let json = JSONReporter()
        EnvironmentOutputs.violationsReporter = json
        HarmonizeReporting.withReporter(json) {
            source.classes().assertTrue(rule: makeRule(id: "always-fails", howToFix: "Fix it.")) { _ in false }
        }

        EnvironmentOutputs.writeOutputs(environment: [
            EnvironmentOutputs.violationsFileKey: violationsURL.path,
            EnvironmentOutputs.catalogFileKey: catalogURL.path,
        ])

        let violations = try JSONDecoder().decode(
            [JSONReporter.Entry].self,
            from: Data(contentsOf: violationsURL)
        )
        XCTAssertEqual(violations.map(\.ruleId), ["always-fails"])
        XCTAssertEqual(violations.first?.howToFix, "Fix it.")

        let catalog = try JSONDecoder().decode(
            [RuleCatalog.Entry].self,
            from: Data(contentsOf: catalogURL)
        )
        XCTAssertEqual(catalog.map(\.rule.id), ["always-fails"])
    }
}
