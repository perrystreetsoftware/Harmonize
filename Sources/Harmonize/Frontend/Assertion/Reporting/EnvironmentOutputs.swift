//
//  EnvironmentOutputs.swift
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

/// Machine-readable output that needs no code. Two environment variables
/// control it, so CI, scripts and AI agents get structured results from a
/// plain `swift test` or `xcodebuild test` run:
///
/// - `HARMONIZE_VIOLATIONS_FILE=<path>`: Harmonize also collects the
///   violations as JSON and writes them to `<path>` when the process exits.
///   The tests fail as usual.
/// - `HARMONIZE_RULE_CATALOG_FILE=<path>`: Harmonize writes every evaluated
///   ``Rule`` as a JSON catalog to `<path>` when the process exits, with or
///   without violations.
///
/// With `xcodebuild test`, prefix each variable with `TEST_RUNNER_` so that
/// it reaches the test process (for example `TEST_RUNNER_HARMONIZE_VIOLATIONS_FILE`).
internal enum EnvironmentOutputs {
    static let violationsFileKey = "HARMONIZE_VIOLATIONS_FILE"
    static let catalogFileKey = "HARMONIZE_RULE_CATALOG_FILE"

    /// The collector for the violations file, or nil when the file is not requested.
    static var violationsReporter: JSONReporter?

    /// Makes the default reporter for assertions. It is a plain
    /// ``XCTestReporter``. When the violations file is requested, it is a
    /// ``CompositeReporter`` that fails the test and also collects JSON.
    static func makeDefaultReporter(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Reporter {
        ensureExitWriteScheduled()
        guard environment[violationsFileKey] != nil else {
            return XCTestReporter()
        }
        let json = JSONReporter()
        violationsReporter = json
        return CompositeReporter([XCTestReporter(), json])
    }

    /// Registers the write at process exit. It does this once per process, and
    /// only when one of the output variables is set.
    static func ensureExitWriteScheduled() {
        _ = scheduledOnce
    }

    private static let scheduledOnce: Void = {
        let environment = ProcessInfo.processInfo.environment
        guard environment[violationsFileKey] != nil || environment[catalogFileKey] != nil else {
            return
        }
        atexit { EnvironmentOutputs.writeOutputs() }
    }()

    /// Writes the requested outputs. Harmonize calls it at process exit. Tests
    /// can pass their own environment.
    static func writeOutputs(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        if let path = environment[violationsFileKey] {
            // A clean run may never use the reporter. Write an empty array, so
            // that tools can see the difference between "no violations" and "no run".
            let data = violationsReporter.flatMap { try? $0.jsonData() } ?? Data("[]".utf8)
            write(data, to: path, label: "violations")
        }
        if let path = environment[catalogFileKey] {
            write(try? RuleCatalog.jsonData(), to: path, label: "rule catalog")
        }
    }

    private static func write(_ data: Data?, to path: String, label: String) {
        guard let data else {
            FileHandle.standardError.write(Data("Harmonize: failed to encode \(label) JSON.\n".utf8))
            return
        }
        let url = URL(fileURLWithPath: path)
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url)
        } catch {
            FileHandle.standardError.write(
                Data("Harmonize: failed to write \(label) to \(path): \(error)\n".utf8)
            )
        }
    }
}
