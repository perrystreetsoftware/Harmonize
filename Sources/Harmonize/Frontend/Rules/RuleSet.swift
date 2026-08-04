//
//  RuleSet.swift
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

/// A named set of ``Rule``.
///
/// ```swift
/// enum AppRules: RuleSet {
///     static let rules: [Rule] = [
///         .viewModelsInheritBase,
///         .domainDoesNotImportUIKit
///     ]
/// }
///
/// final class ArchitectureTests: XCTestCase {
///     func testArchitecture() { AppRules.assertAll() }
/// }
/// ```
///
/// A set can also be written as documentation for AI agents through
/// ``markdownContext(title:intro:)``.
public protocol RuleSet {
    static var rules: [Rule] { get }
}

// MARK: - Evaluation

public extension RuleSet {
    /// Evaluates every rule against the project's production code, failing the surrounding
    /// test for each violation.
    ///
    /// - parameter file: The call site, used to resolve the project root.
    static func assertAll(_ file: StaticString = #file) {
        assertAll(in: Harmonize.productionCode(file))
    }

    /// Evaluates every rule against the given scope, failing the surrounding test for each
    /// violation.
    static func assertAll(in scope: HarmonizeScope) {
        rules.forEach { $0.evaluate(in: scope) }
    }

    /// Evaluates every rule against the given scope and returns the violations, leaving the
    /// active ``Reporter`` untouched.
    static func violations(in scope: HarmonizeScope) -> [Violation] {
        rules.flatMap { $0.violations(in: scope) }
    }

    static func rule(id: String) -> Rule? {
        rules.first { $0.id == id }
    }
}

// MARK: - Validation

public extension RuleSet {
    /// Asserts that the rule ids are unique and not empty, and that every rule says what it
    /// checks and why.
    ///
    /// A rule with no summary or reasoning still fails CI but explains nothing, and shows up as
    /// an empty section in the generated documentation.
    static func assertRulesAreValid(
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        var seen: Set<String> = []
        var duplicates: Set<String> = []

        for rule in rules where !seen.insert(rule.id).inserted {
            duplicates.insert(rule.id)
        }

        if !duplicates.isEmpty {
            reportInline(
                message: """
                Duplicate rule id(s): \(duplicates.sorted().map { "'\($0)'" }.joined(separator: ", ")). \
                Ids identify violations in reports and in the generated documentation, so they must be unique.
                """,
                fileID: fileID,
                file: file,
                line: line,
                column: column
            )
        }

        let unnamed = rules.filter { $0.id.isBlank }
        if unnamed.isNotEmpty {
            reportInline(
                message: "\(unnamed.count) rule(s) have an empty id.",
                fileID: fileID,
                file: file,
                line: line,
                column: column
            )
        }

        let undocumented = rules.filter { $0.summary.isBlank && $0.why.isBlank }

        if undocumented.isNotEmpty {
            reportInline(
                message: """
                \(undocumented.count) rule(s) have no summary and no reasoning: \
                \(undocumented.map { "'\($0.id)'" }.joined(separator: ", ")).
                """,
                fileID: fileID,
                file: file,
                line: line,
                column: column
            )
        }
    }
}

// MARK: - Blank

private extension Optional where Wrapped == String {
    var isBlank: Bool {
        self?.isBlank ?? true
    }
}

private extension String {
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
