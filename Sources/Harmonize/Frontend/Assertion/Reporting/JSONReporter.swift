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
/// Install it for the rule evaluation, then serialize the result:
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
            /// A failure of the assertion itself, for example an empty scope in
            /// strict mode or a stale baseline entry. The reporter does not record
            /// the summary text of a violation report.
            case assertion
        }

        /// A rule violation or a failure of the assertion itself.
        public let kind: Kind
        /// The id of the rule, or nil for an assertion without rule metadata.
        public let ruleId: String?
        /// The title of the rule, or nil when the rule has no title.
        public let title: String?
        /// The name of the violating declaration or file, or nil for an assertion failure.
        public let name: String?
        /// The path of the violating file, or of the assertion for an assertion failure.
        public let file: String
        public let line: Int
        public let column: Int
        /// The rationale of the rule. The title or the id when the rationale is
        /// empty. The failure text for an assertion failure.
        public let message: String
        /// How to correct the violation, or nil when the rule gives no fix.
        public let howToFix: String?
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

    /// Removes all collected entries, for example between incremental runs.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        collected.removeAll()
    }

    public func report(violations: [Violation], summary: String, at location: AssertionLocation) {
        // The summary repeats the violations in one text. Machine consumers
        // need only the entries, one per violation.
        append(violations.map { violation in
            Entry(
                kind: .violation,
                ruleId: violation.rule?.id,
                title: violation.rule.flatMap { $0.title.isEmpty ? nil : $0.title },
                name: violation.name,
                file: violation.filePath.relativePath,
                line: violation.line,
                column: violation.column,
                message: violation.message,
                howToFix: violation.rule.flatMap { $0.howToFix.isEmpty ? nil : $0.howToFix }
            )
        })

        // When no violation has a source location, the summary is the only
        // record of the failure. Keep it.
        if violations.isEmpty {
            report(failure: summary, at: location)
        }
    }

    public func report(failure message: String, at location: AssertionLocation) {
        append([
            Entry(
                kind: .assertion,
                ruleId: nil,
                title: nil,
                name: nil,
                file: location.filePath,
                line: location.line,
                column: location.column,
                message: message,
                howToFix: nil
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
