//
//  JSONReporter.swift
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

/// A ``Reporter`` that collects violations as machine-readable entries
/// instead of failing a test.
///
/// Install it around rule evaluation and serialize the result:
///
/// ```swift
/// let reporter = JSONReporter()
/// HarmonizeReporting.withReporter(reporter) {
///     runAllRules()
/// }
/// let json = try reporter.jsonData()
/// ```
public final class JSONReporter: Reporter {
    /// One reported violation or assertion-level failure.
    public struct Entry: Codable, Equatable {
        public enum Kind: String, Codable {
            /// A rule violation attributed to a source declaration or file.
            case violation
            /// A failure attributed to the assertion itself
            /// (strict-mode empty scope, stale baseline entry, aggregate summary is *not* recorded).
            case assertion
        }

        public let kind: Kind
        public let ruleId: String?
        public let severity: Rule.Severity?
        public let name: String?
        public let file: String
        public let line: Int
        public let column: Int
        public let message: String
        public let fixHint: String?
    }

    private let lock = NSLock()
    private var collected: [Entry] = []

    public init() {}

    /// All entries reported so far.
    public var entries: [Entry] {
        lock.lock()
        defer { lock.unlock() }
        return collected
    }

    /// Serializes the collected entries as a JSON array.
    public func jsonData(prettyPrinted: Bool = true) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = prettyPrinted ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
        return try encoder.encode(entries)
    }

    /// Removes all collected entries, e.g. between incremental check requests.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        collected.removeAll()
    }

    public func report(violations: [Violation], summary: String, at location: AssertionLocation) {
        // The summary is a human-readable rollup of the individual violations;
        // machine consumers only need the per-violation entries.
        append(violations.map { violation in
            Entry(
                kind: .violation,
                ruleId: violation.rule?.id,
                severity: violation.rule?.severity,
                name: violation.name,
                file: violation.filePath.relativePath,
                line: violation.line,
                column: violation.column,
                message: violation.message,
                fixHint: violation.rule?.fixHint
            )
        })

        // But if no violation had a resolvable source location, the summary
        // is the only record of the failure — keep it.
        if violations.isEmpty {
            report(failure: summary, at: location)
        }
    }

    public func report(failure message: String, at location: AssertionLocation) {
        append([
            Entry(
                kind: .assertion,
                ruleId: nil,
                severity: nil,
                name: nil,
                file: location.filePath,
                line: location.line,
                column: location.column,
                message: message,
                fixHint: nil
            )
        ])
    }

    private func append(_ entries: [Entry]) {
        guard !entries.isEmpty else { return }
        lock.lock()
        defer { lock.unlock() }
        collected.append(contentsOf: entries)
    }
}
