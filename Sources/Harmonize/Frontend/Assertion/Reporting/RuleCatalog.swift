//
//  RuleCatalog.swift
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

/// A process-wide registry of every ``Rule`` that the current run evaluated.
///
/// An assertion registers its rule when it runs, with or without violations.
/// One run of the rule suite then gives a complete, machine-readable catalog
/// of the architectural rules of the project. Tools and AI agents can read
/// the catalog to learn the rules before they write code.
///
/// Set the `HARMONIZE_RULE_CATALOG_FILE` environment variable to a file path.
/// Harmonize then writes the catalog as JSON when the process exits:
///
/// ```sh
/// HARMONIZE_RULE_CATALOG_FILE=harmonize-rules.json swift test
/// ```
public enum RuleCatalog {
    /// One catalog record: the rule and the file that defines it.
    public struct Entry: Codable, Equatable {
        /// The rule metadata that the assertion received.
        public let rule: Rule

        /// The absolute path of the source file that defines the assertion.
        /// Tools use it to open the implementation of the rule.
        public let definedIn: String

        public init(rule: Rule, definedIn: String) {
            self.rule = rule
            self.definedIn = definedIn
        }
    }

    private static let lock = NSLock()
    private static var entriesById: [String: Entry] = [:]
    private static var insertionOrder: [String] = []

    /// All registered rules, in the order of their first registration.
    public static var entries: [Entry] {
        lock.lock()
        defer { lock.unlock() }
        return insertionOrder.compactMap { entriesById[$0] }
    }

    /// Records a rule evaluation and returns the rule with its effective id.
    ///
    /// A second registration of the same rule changes nothing. A different
    /// rule with the same id gets the suffix `-2`, `-3` and so on, in the
    /// order of registration. This happens when two rules in one file use
    /// the derived id. The returned rule carries the new id, so the violations
    /// agree with the catalog. The function is safe to call from more than
    /// one thread.
    @discardableResult
    public static func register(_ rule: Rule, definedIn: String) -> Rule {
        EnvironmentOutputs.ensureExitWriteScheduled()
        lock.lock()
        defer { lock.unlock() }

        var candidate = rule
        var suffix = 2
        while let existing = entriesById[candidate.id] {
            if existing.rule.sameContent(as: candidate) && existing.definedIn == definedIn {
                return existing.rule
            }
            candidate = rule.withId("\(rule.id)-\(suffix)")
            suffix += 1
        }

        entriesById[candidate.id] = Entry(rule: candidate, definedIn: definedIn)
        insertionOrder.append(candidate.id)
        return candidate
    }

    /// Serializes the catalog as a JSON array of ``Entry``.
    public static func jsonData(prettyPrinted: Bool = true) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = prettyPrinted ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
        return try encoder.encode(entries)
    }

    /// Removes all registered rules, for example between incremental runs.
    public static func reset() {
        lock.lock()
        defer { lock.unlock() }
        entriesById.removeAll()
        insertionOrder.removeAll()
    }
}
