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

/// Machine-readable output that needs no code. One environment variable
/// controls it, so CI, scripts, and AI agents get structured results from a
/// plain `swift test` or `xcodebuild test` run:
///
/// - `HARMONIZE_VIOLATIONS_FILE=<path>`: Harmonize also collects the
///   violations as JSON and writes them to `<path>` when the process exits.
///   The tests fail as usual. A clean run writes an empty array.
/// - `HARMONIZE_VIOLATIONS_FILE=<directory>/`: when the path ends with a
///   slash, each test process writes its own file,
///   `<directory>/violations-<pid>.json`. Use this form when the test workers
///   run in parallel, for example with `swift test --parallel` or with Xcode
///   parallel testing. Each worker is a separate process, and one shared file
///   would keep only the last worker. Clear the directory before the run.
///
/// With `xcodebuild test`, prefix the variable with `TEST_RUNNER_` so that
/// it reaches the test process (`TEST_RUNNER_HARMONIZE_VIOLATIONS_FILE`).
internal enum EnvironmentOutputs {
    static let violationsFileKey = "HARMONIZE_VIOLATIONS_FILE"

    /// The environment of the process. Tests can replace it.
    static var environment: [String: String] = ProcessInfo.processInfo.environment

    /// The collector for the violations file, or nil when the file is not requested.
    static var violationsReporter: JSONReporter?

    /// True after the write at process exit is registered.
    static var exitWriteScheduled = false

    private static let lock = NSLock()

    /// Makes the default reporter for assertions. It is a plain
    /// ``XCTestReporter``. When the violations file is requested, it is a
    /// ``CompositeReporter`` that fails the test and also collects JSON.
    static func makeDefaultReporter(
        environment: [String: String] = EnvironmentOutputs.environment
    ) -> Reporter {
        ensureExitWriteScheduled(environment: environment)
        guard environment[violationsFileKey] != nil else {
            return XCTestReporter()
        }
        let json = JSONReporter()
        violationsReporter = json
        return CompositeReporter([XCTestReporter(), json])
    }

    /// Registers the write at process exit. It does this once per process, and
    /// only when the variable is set. Every project scan calls it, and so does
    /// the default reporter. A passing assertion never touches the reporter,
    /// so the scan is what makes a clean run write its file.
    static func ensureExitWriteScheduled(
        environment: [String: String] = EnvironmentOutputs.environment
    ) {
        lock.lock()
        defer { lock.unlock() }
        guard !exitWriteScheduled, environment[violationsFileKey] != nil else { return }
        exitWriteScheduled = true
        atexit { EnvironmentOutputs.writeOutputs() }
    }

    /// Writes the violations file when it is requested. Harmonize calls it at
    /// process exit. Tests can pass their own environment.
    static func writeOutputs(
        environment: [String: String] = EnvironmentOutputs.environment
    ) {
        guard let path = environment[violationsFileKey] else { return }
        // A clean run may never use the reporter. Write an empty array, so
        // that tools can see the difference between "no violations" and "no run".
        let data = violationsReporter.flatMap { try? $0.jsonData() } ?? Data("[]".utf8)
        write(data, to: outputURL(for: path), label: "violations")
    }

    /// A path that ends with a slash is a directory. Each process then writes
    /// its own file, so parallel test workers do not overwrite each other.
    static func outputURL(for path: String) -> URL {
        let url = URL(fileURLWithPath: path)
        guard path.hasSuffix("/") else { return url }
        return url.appendingPathComponent("violations-\(ProcessInfo.processInfo.processIdentifier).json")
    }

    private static func write(_ data: Data, to url: URL, label: String) {
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url)
        } catch {
            FileHandle.standardError.write(
                Data("Harmonize: failed to write \(label) to \(url.path): \(error)\n".utf8)
            )
        }
    }
}
