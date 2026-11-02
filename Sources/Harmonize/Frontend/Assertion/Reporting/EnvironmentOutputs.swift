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
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

/// Machine-readable output that needs no code. One environment variable
/// controls it, so CI, scripts, and AI agents get structured results from a
/// plain `swift test` or `xcodebuild test` run:
///
/// - `HARMONIZE_VIOLATIONS_FILE=<path>`: Harmonize also collects the
///   violations as JSON and writes them to `<path>` when the process exits.
///   The tests fail as usual. A clean run writes an empty array. One run can
///   have more than one test process: `swift test` runs Swift Testing tests in
///   a second process, and `swift test --parallel` starts several workers.
///   The processes of one run share a parent process. Harmonize records that
///   parent in `<path>.run` and adds the entries of each process to the file.
///   A process from a different run replaces the file. Delete the file before
///   a run. The parent is a heuristic: a parent that stays alive across runs,
///   for example an interactive shell that starts the test bundle directly,
///   keeps its id, and a stale file then keeps old entries.
/// - `HARMONIZE_VIOLATIONS_FILE=<directory>/`: when the path ends with a
///   slash, each test process writes its own file,
///   `<directory>/violations-<pid>.json`. Use this form when you want one
///   file per test process. Clear the directory before the run.
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
        environment: [String: String] = EnvironmentOutputs.environment,
        runIdentifier: String = currentRunIdentifier
    ) {
        guard let path = environment[violationsFileKey] else { return }
        // A clean run may never use the reporter. Write an empty array, so
        // that tools can see the difference between "no violations" and "no run".
        var entries = violationsReporter?.entries ?? []
        let url = outputURL(for: path)

        if path.hasSuffix("/") {
            write(encode(entries), to: url, label: "violations")
            return
        }

        // One file for the whole run. Another process of the same run may have
        // written it already, so merge under a lock.
        let markerURL = URL(fileURLWithPath: path + ".run")
        withFileLock(at: path + ".lock") {
            let sameRun = (try? String(contentsOf: markerURL, encoding: .utf8)) == runIdentifier
            if sameRun,
               let data = try? Data(contentsOf: url),
               let existing = try? JSONDecoder().decode([JSONReporter.Entry].self, from: data) {
                entries = existing + entries
            }
            write(encode(entries), to: url, label: "violations")
            write(Data(runIdentifier.utf8), to: markerURL, label: "run marker")
        }
    }

    /// The processes of one test run share a parent: the `swift test` driver
    /// or the test runner. Its id identifies the run.
    static var currentRunIdentifier: String {
        String(getppid())
    }

    private static func encode(_ entries: [JSONReporter.Entry]) -> Data {
        guard !entries.isEmpty else { return Data("[]".utf8) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(entries)) ?? Data("[]".utf8)
    }

    private static func withFileLock(at path: String, _ body: () -> Void) {
        let descriptor = open(path, O_CREAT | O_RDWR, 0o644)
        guard descriptor >= 0 else {
            body()
            return
        }
        flock(descriptor, LOCK_EX)
        body()
        flock(descriptor, LOCK_UN)
        close(descriptor)
    }

    /// A path that ends with a slash is a directory. Each process then writes
    /// its own file, so parallel test workers do not overwrite each other.
    static func outputURL(for path: String) -> URL {
        let url = URL(fileURLWithPath: path)
        guard path.hasSuffix("/") else { return url }
        return url.appendingPathComponent("violations-\(ProcessInfo.processInfo.processIdentifier).json")
    }

    private static func createDirectory(for url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    private static func write(_ data: Data, to url: URL, label: String) {
        do {
            try createDirectory(for: url)
            try data.write(to: url)
        } catch {
            FileHandle.standardError.write(
                Data("Harmonize: failed to write \(label) to \(url.path): \(error)\n".utf8)
            )
        }
    }
}
