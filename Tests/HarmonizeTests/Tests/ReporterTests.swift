//
//  ReporterTests.swift
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

func makeRule(
    id: String? = nil,
    title: String = "",
    category: String = "",
    disclosure: Rule.Disclosure = .progressive,
    rationale: String = "",
    howToFix: String = "",
    badExample: String = "",
    goodExample: String = "",
    file: StaticString = #filePath
) -> Rule {
    Rule(
        id: id,
        title: title,
        category: category,
        disclosure: disclosure,
        rationale: rationale,
        howToFix: howToFix,
        badExample: badExample,
        goodExample: goodExample,
        file: file
    )
}

final class ReporterTests: XCTestCase {
    private var fileURL: URL!
    private var source: SwiftSourceCode!

    override func setUpWithError() throws {
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReporterTests-\(UUID().uuidString)")
            .appendingPathComponent("Sources/ReporterFixture/BadViewModel.swift")
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try """
        import Foundation

        final class BadViewModel {
            var value: Int = 0
        }
        """.write(to: fileURL, atomically: true, encoding: .utf8)
        source = try XCTUnwrap(SwiftSourceCode(url: fileURL))
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent().deletingLastPathComponent())
    }

    func testJSONReporterCollectsViolationsWithRuleMetadata() throws {
        let rule = makeRule(
            id: "viewmodels-inherit-base",
            title: "ViewModels inherit from BaseViewModel.",
            rationale: "ViewModels must inherit BaseViewModel.",
            howToFix: "Declare the class as `final class BadViewModel: BaseViewModel`."
        )

        let reporter = JSONReporter()
        HarmonizeReporting.withReporter(reporter) {
            source.classes().assertTrue(rule: rule) { _ in false }
        }

        XCTAssertEqual(reporter.entries.count, 1)
        let entry = try XCTUnwrap(reporter.entries.first)
        XCTAssertEqual(entry.kind, .violation)
        XCTAssertEqual(entry.ruleId, "viewmodels-inherit-base")
        XCTAssertEqual(entry.title, "ViewModels inherit from BaseViewModel.")
        XCTAssertEqual(entry.name, "BadViewModel")
        XCTAssertEqual(entry.file, fileURL.relativePath)
        XCTAssertEqual(entry.line, 3)
        XCTAssertEqual(entry.message, "ViewModels must inherit BaseViewModel.")
        XCTAssertEqual(entry.howToFix, "Declare the class as `final class BadViewModel: BaseViewModel`.")
    }

    func testRuleIdDefaultsToTheDeclaringFileNameInKebabCase() throws {
        XCTAssertEqual(makeRule().id, "reporter-tests")
        XCTAssertEqual(makeRule(id: nil, title: "Some rule.").id, "reporter-tests")
        XCTAssertEqual(makeRule(id: "custom-id").id, "custom-id")
    }

    func testFormattedLaysOutEveryProvidedSection() throws {
        let rule = makeRule(
            id: "viewmodels-inherit-base",
            title: "ViewModels inherit from BaseViewModel.",
            rationale: "BaseViewModel owns the lifecycle handling every screen relies on.",
            howToFix: "Declare the class as `final class MyViewModel: BaseViewModel`.",
            badExample: "final class MyViewModel: ObservableObject { }",
            goodExample: "final class MyViewModel: BaseViewModel { }"
        )

        XCTAssertEqual(rule.formatted, """
        RULE: ViewModels inherit from BaseViewModel.

        WHY: BaseViewModel owns the lifecycle handling every screen relies on.

        HOW TO FIX: Declare the class as `final class MyViewModel: BaseViewModel`.

        ❌ BAD:
        final class MyViewModel: ObservableObject { }

        ✅ GOOD:
        final class MyViewModel: BaseViewModel { }
        """)
    }

    func testFormattedFallsBackToTheIdAndSkipsEmptySections() throws {
        XCTAssertEqual(makeRule(id: "no-foundation").formatted, "RULE: no-foundation")
        XCTAssertEqual(
            makeRule(id: "no-foundation", howToFix: "Remove the import.").formatted,
            "RULE: no-foundation\n\nHOW TO FIX: Remove the import."
        )
    }

    func testEveryAssertionCarriesTheRuleMetadata() throws {
        let rule = makeRule(
            id: "viewmodels-inherit-base-everywhere",
            title: "ViewModels inherit from BaseViewModel.",
            rationale: "BaseViewModel owns the lifecycle handling.",
            howToFix: "Inherit from BaseViewModel."
        )

        let reporter = JSONReporter()
        HarmonizeReporting.withReporter(reporter) {
            source.classes().assertTrue(rule: rule) { _ in false }
            [source!].assertFalse(rule: rule) { _ in true }
            source.classes().assertEmpty(rule: rule)
        }

        XCTAssertEqual(reporter.entries.count, 3)
        XCTAssertEqual(reporter.entries.map(\.ruleId), Array(repeating: "viewmodels-inherit-base-everywhere", count: 3))
        XCTAssertEqual(reporter.entries.map(\.message), Array(repeating: "BaseViewModel owns the lifecycle handling.", count: 3))
        XCTAssertEqual(reporter.entries.map(\.howToFix), Array(repeating: "Inherit from BaseViewModel.", count: 3))
    }

    // Exercises the deprecated `message:` overload on purpose.
    func testExplicitMessageWinsOverRationale() throws {
        let reporter = JSONReporter()
        HarmonizeReporting.withReporter(reporter) {
            source.classes().assertTrue(
                message: "Custom message.",
                rule: makeRule(id: "some-rule", rationale: "Rationale.")
            ) { _ in false }
        }

        XCTAssertEqual(reporter.entries.map(\.message), ["Custom message."])
    }

    func testJSONReporterRecordsAssertionLevelFailures() throws {
        let reporter = JSONReporter()
        HarmonizeReporting.withReporter(reporter) {
            source.classes().assertNotEmpty()          // passes: no entry
            [Class]().assertTrue(strict: true) { _ in true }  // strict empty: assertion entry
        }

        XCTAssertEqual(reporter.entries.count, 1)
        let entry = try XCTUnwrap(reporter.entries.first)
        XCTAssertEqual(entry.kind, .assertion)
        XCTAssertNil(entry.ruleId)
        XCTAssertNil(entry.title)
        XCTAssertEqual(entry.message, "Expected true but got empty collection instead.")
        XCTAssertTrue(entry.file.hasSuffix("ReporterTests.swift"))
    }

    func testJSONReporterCollectsSourceCodeAssertions() throws {
        let reporter = JSONReporter()
        HarmonizeReporting.withReporter(reporter) {
            [source!].assertFalse(rule: makeRule(id: "no-foundation")) { file in
                file.imports().contains { $0.name == "Foundation" }
            }
        }

        XCTAssertEqual(reporter.entries.count, 1)
        let entry = try XCTUnwrap(reporter.entries.first)
        XCTAssertEqual(entry.kind, .violation)
        XCTAssertEqual(entry.ruleId, "no-foundation")
        XCTAssertNil(entry.title)
        XCTAssertEqual(entry.name, "BadViewModel.swift")
        XCTAssertEqual(entry.line, 1)
    }

    func testPassingAssertionsProduceNoEntries() throws {
        let reporter = JSONReporter()
        HarmonizeReporting.withReporter(reporter) {
            source.classes().assertTrue { _ in true }
            source.classes().assertNotEmpty()
            source.classes().assertCount(count: 1)
        }

        XCTAssertTrue(reporter.entries.isEmpty)
    }

    func testWithReporterRestoresPreviousReporter() throws {
        let previous = HarmonizeReporting.reporter
        HarmonizeReporting.withReporter(JSONReporter()) {
            XCTAssertTrue(HarmonizeReporting.reporter is JSONReporter)
        }
        XCTAssertTrue(type(of: HarmonizeReporting.reporter) == type(of: previous))
    }

    func testJSONSerializationRoundTrips() throws {
        let reporter = JSONReporter()
        HarmonizeReporting.withReporter(reporter) {
            source.classes().assertEmpty(rule: makeRule(id: "no-classes"))
        }

        let data = try reporter.jsonData()
        let decoded = try JSONDecoder().decode([JSONReporter.Entry].self, from: data)
        XCTAssertEqual(decoded, reporter.entries)
        XCTAssertEqual(decoded.first?.ruleId, "no-classes")
    }

    func testARuleWithoutARationaleStillShowsTheFullRule() throws {
        let rule = makeRule(id: "no-rationale", title: "Title.", howToFix: "Fix.")

        let reporter = JSONReporter()
        HarmonizeReporting.withReporter(reporter) {
            source.classes().assertTrue(rule: rule) { _ in false }
        }

        let entry = try XCTUnwrap(reporter.entries.first)
        XCTAssertEqual(entry.message, "Title.")
        let violation = Violation(name: "X", message: entry.message, filePath: fileURL, line: 1, column: 1, fileID: "M/X.swift", rule: rule)
        XCTAssertEqual(violation.displayMessage, "RULE: Title.\n\nHOW TO FIX: Fix.")

        XCTAssertEqual(makeRule(id: "bare").defaultMessage, "bare")
    }

    func testDisplayMessageShowsTheFullRuleWhenNoExplicitMessageWasGiven() throws {
        let rule = makeRule(id: "r", title: "Title.", rationale: "Why.", howToFix: "Fix.", badExample: "bad", goodExample: "good")
        let defaulted = Violation(name: "X", message: "Why.", filePath: fileURL, line: 1, column: 1, fileID: "M/X.swift", rule: rule)
        let explicit = Violation(name: "X", message: "Custom.", filePath: fileURL, line: 1, column: 1, fileID: "M/X.swift", rule: rule)

        XCTAssertEqual(defaulted.displayMessage, rule.formatted)
        XCTAssertTrue(defaulted.displayMessage.contains("HOW TO FIX: Fix."))
        XCTAssertEqual(explicit.displayMessage, "Custom.")
    }
}
