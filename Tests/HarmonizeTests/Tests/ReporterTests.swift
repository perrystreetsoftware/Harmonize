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
        let rule = Rule(
            id: "viewmodels-inherit-base",
            severity: .error,
            rationale: "ViewModels must inherit BaseViewModel.",
            fixHint: "Declare the class as `final class BadViewModel: BaseViewModel`."
        )

        let reporter = JSONReporter()
        HarmonizeReporting.withReporter(reporter) {
            source.classes().assertTrue(rule: rule) { _ in false }
        }

        XCTAssertEqual(reporter.entries.count, 1)
        let entry = try XCTUnwrap(reporter.entries.first)
        XCTAssertEqual(entry.kind, .violation)
        XCTAssertEqual(entry.ruleId, "viewmodels-inherit-base")
        XCTAssertEqual(entry.severity, .error)
        XCTAssertEqual(entry.name, "BadViewModel")
        XCTAssertEqual(entry.file, fileURL.relativePath)
        XCTAssertEqual(entry.line, 3)
        XCTAssertEqual(entry.message, "ViewModels must inherit BaseViewModel.")
        XCTAssertEqual(entry.fixHint, "Declare the class as `final class BadViewModel: BaseViewModel`.")
    }

    func testExplicitMessageWinsOverRationale() throws {
        let reporter = JSONReporter()
        HarmonizeReporting.withReporter(reporter) {
            source.classes().assertTrue(
                message: "Custom message.",
                rule: Rule(id: "some-rule", rationale: "Rationale.")
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
        XCTAssertEqual(entry.message, "Expected true but got empty collection instead.")
        XCTAssertTrue(entry.file.hasSuffix("ReporterTests.swift"))
    }

    func testJSONReporterCollectsSourceCodeAssertions() throws {
        let reporter = JSONReporter()
        HarmonizeReporting.withReporter(reporter) {
            [source!].assertFalse(rule: Rule(id: "no-foundation")) { file in
                file.imports().contains { $0.name == "Foundation" }
            }
        }

        XCTAssertEqual(reporter.entries.count, 1)
        let entry = try XCTUnwrap(reporter.entries.first)
        XCTAssertEqual(entry.kind, .violation)
        XCTAssertEqual(entry.ruleId, "no-foundation")
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
            source.classes().assertEmpty(rule: Rule(id: "no-classes", severity: .warning))
        }

        let data = try reporter.jsonData()
        let decoded = try JSONDecoder().decode([JSONReporter.Entry].self, from: data)
        XCTAssertEqual(decoded, reporter.entries)
        XCTAssertEqual(decoded.first?.severity, .warning)
    }
}
