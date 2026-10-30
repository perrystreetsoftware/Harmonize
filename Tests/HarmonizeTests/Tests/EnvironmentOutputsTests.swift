//
//  EnvironmentOutputsTests.swift
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

final class EnvironmentOutputsTests: XCTestCase {
    private var fileURL: URL!
    private var source: SwiftSourceCode!

    override func setUpWithError() throws {
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("EnvironmentOutputsTests-\(UUID().uuidString)")
            .appendingPathComponent("Sources/OutputsFixture/GoodViewModel.swift")
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
        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent().deletingLastPathComponent())
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

    func testWriteOutputsWritesTheViolationsFile() throws {
        let outputDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EnvironmentOutputsTests-Outputs-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let violationsURL = outputDirectory.appendingPathComponent("nested/violations.json")

        let previousViolationsReporter = EnvironmentOutputs.violationsReporter
        defer { EnvironmentOutputs.violationsReporter = previousViolationsReporter }

        let json = JSONReporter()
        EnvironmentOutputs.violationsReporter = json
        HarmonizeReporting.withReporter(json) {
            source.classes().assertTrue(
                rule: makeRule(id: "always-fails", title: "Classes never pass.", howToFix: "Fix it.")
            ) { _ in false }
        }

        EnvironmentOutputs.writeOutputs(environment: [
            EnvironmentOutputs.violationsFileKey: violationsURL.path,
        ])

        let violations = try JSONDecoder().decode(
            [JSONReporter.Entry].self,
            from: Data(contentsOf: violationsURL)
        )
        XCTAssertEqual(violations.map(\.ruleId), ["always-fails"])
        XCTAssertEqual(violations.first?.title, "Classes never pass.")
        XCTAssertEqual(violations.first?.howToFix, "Fix it.")
        XCTAssertEqual(violations.first?.name, "GoodViewModel")
    }

    func testWriteOutputsWritesAnEmptyArrayForACleanRun() throws {
        let outputDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EnvironmentOutputsTests-Clean-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let violationsURL = outputDirectory.appendingPathComponent("violations.json")

        let previousViolationsReporter = EnvironmentOutputs.violationsReporter
        defer { EnvironmentOutputs.violationsReporter = previousViolationsReporter }
        EnvironmentOutputs.violationsReporter = nil

        EnvironmentOutputs.writeOutputs(environment: [
            EnvironmentOutputs.violationsFileKey: violationsURL.path,
        ])

        let violations = try JSONDecoder().decode(
            [JSONReporter.Entry].self,
            from: Data(contentsOf: violationsURL)
        )
        XCTAssertTrue(violations.isEmpty)
    }

    func testAProjectScanSchedulesTheExitWriteWhenTheVariableIsSet() throws {
        let previousEnvironment = EnvironmentOutputs.environment
        let previousScheduled = EnvironmentOutputs.exitWriteScheduled
        defer {
            EnvironmentOutputs.environment = previousEnvironment
            EnvironmentOutputs.exitWriteScheduled = previousScheduled
        }

        EnvironmentOutputs.exitWriteScheduled = false
        EnvironmentOutputs.environment = [:]
        _ = Harmonize.on("Fixtures/SwiftTesting")
        XCTAssertFalse(EnvironmentOutputs.exitWriteScheduled, "nothing to schedule without the variable")

        EnvironmentOutputs.environment = [EnvironmentOutputs.violationsFileKey: "/tmp/unused.json"]
        _ = Harmonize.productionCode()
        XCTAssertTrue(EnvironmentOutputs.exitWriteScheduled, "a scan schedules the write before any assertion runs")
    }

    func testADirectoryPathGivesEachProcessItsOwnFile() throws {
        let outputDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EnvironmentOutputsTests-Dir-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let directoryPath = outputDirectory.path + "/"

        XCTAssertEqual(EnvironmentOutputs.outputURL(for: "/tmp/violations.json").path, "/tmp/violations.json")
        XCTAssertEqual(
            EnvironmentOutputs.outputURL(for: directoryPath).lastPathComponent,
            "violations-\(ProcessInfo.processInfo.processIdentifier).json"
        )

        let previousViolationsReporter = EnvironmentOutputs.violationsReporter
        defer { EnvironmentOutputs.violationsReporter = previousViolationsReporter }
        EnvironmentOutputs.violationsReporter = nil

        EnvironmentOutputs.writeOutputs(environment: [EnvironmentOutputs.violationsFileKey: directoryPath])

        let files = try FileManager.default.contentsOfDirectory(atPath: outputDirectory.path)
        XCTAssertEqual(files, ["violations-\(ProcessInfo.processInfo.processIdentifier).json"])
    }

    func testWriteOutputsDoesNothingWithoutTheVariable() throws {
        let outputDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EnvironmentOutputsTests-None-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: outputDirectory) }

        EnvironmentOutputs.writeOutputs(environment: [:])

        XCTAssertFalse(FileManager.default.fileExists(atPath: outputDirectory.path))
    }
}
