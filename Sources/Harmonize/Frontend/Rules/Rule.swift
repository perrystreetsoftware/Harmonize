//
//  Rule.swift
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

/// An architectural rule composed by its metadata and the query that enforces it.
///
/// Declaring a rule as a value allows it to be listed, documented and evaluated against
/// any scope, instead of only existing while a test runs.
///
/// ```swift
/// let viewModelsInheritBase = Rule(
///     id: "viewmodels-inherit-base",
///     summary: "Every ViewModel must inherit from BaseViewModel.",
///     why: "BaseViewModel owns subscription cancellation, a ViewModel that opts out leaks.",
///     howToFix: "Declare the type as `final class MyViewModel: BaseViewModel`.",
///     badExample: "final class ProfileViewModel {}",
///     goodExample: "final class ProfileViewModel: BaseViewModel {}"
/// ) { scope in
///     scope.classes()
///         .withNameEndingWith("ViewModel")
///         .assertTrue { $0.inherits(from: "BaseViewModel") }
/// }
/// ```
///
/// The `check` closure receives the scope rather than building one, so the same rule runs
/// against the project, a folder, or an inline snippet.
///
/// Assertions within `check` inherit this rule's metadata, there is no need to pass `rule:`
/// to each one.
///
/// A rule may also carry no query at all, being just the metadata for a standalone assertion:
///
/// ```swift
/// viewModels.assertTrue(rule: Rule(id: "viewmodels-inherit-base", why: "...")) { ... }
/// ```
public struct Rule {
    public enum Severity: String, Codable, Equatable {
        case error
        case warning
    }

    /// A pair of code samples demonstrating the rule.
    ///
    /// These are verified by ``RuleSet/assertExamples(fileID:file:line:column:)``, which
    /// evaluates the rule against both and fails when `badExample` does not trigger it or
    /// `goodExample` does.
    public struct Examples: Codable, Equatable {
        /// Swift source that breaks the rule.
        public let badExample: String

        /// Swift source that follows the rule.
        public let goodExample: String

        /// The path both examples stand at while being evaluated.
        ///
        /// A rule matching on a directory only sees its examples when their path contains it,
        /// e.g. `"Sources/Screens/ProfileScreen.swift"` for a rule scoped to `Screens`.
        public let path: String

        public init(badExample: String, goodExample: String, path: String = Rule.snippetPath) {
            self.badExample = badExample
            self.goodExample = goodExample
            self.path = path
        }
    }

    /// The path given to plain source when a rule is evaluated against a snippet.
    public static let snippetPath = "Snippet.swift"

    /// Stable identifier for the rule, e.g. `"viewmodels-inherit-base"`.
    public let id: String

    /// One line statement of what the rule checks.
    public let summary: String?

    /// How violations should be treated by consumers of the report.
    public let severity: Severity

    /// Why the rule exists, the reasoning behind it.
    public let why: String?

    /// How to bring violating code into compliance.
    public let howToFix: String?

    /// Breaking and following samples, when the rule provides them.
    public let examples: Examples?

    /// The query that enforces the rule within a given scope.
    public let check: (HarmonizeScope) -> Void

    /// Creates a rule.
    ///
    /// - parameters:
    ///   - id: Stable identifier, e.g. `"viewmodels-inherit-base"`.
    ///   - summary: One line statement of what the rule checks.
    ///   - severity: How consumers should treat violations. `.error` by default.
    ///   - why: The reasoning behind the rule.
    ///   - howToFix: How to bring violating code into compliance.
    ///   - examples: Breaking and following samples.
    ///   - check: The query that enforces the rule. Omit it for metadata only rules.
    public init(
        id: String,
        summary: String? = nil,
        severity: Severity = .error,
        why: String? = nil,
        howToFix: String? = nil,
        examples: Examples? = nil,
        check: @escaping (HarmonizeScope) -> Void = { _ in }
    ) {
        self.id = id
        self.summary = summary
        self.severity = severity
        self.why = why
        self.howToFix = howToFix
        self.examples = examples
        self.check = check
    }

    /// Creates a rule with its examples given as a pair of snippets.
    ///
    /// - parameters:
    ///   - id: Stable identifier, e.g. `"viewmodels-inherit-base"`.
    ///   - summary: One line statement of what the rule checks.
    ///   - severity: How consumers should treat violations. `.error` by default.
    ///   - why: The reasoning behind the rule.
    ///   - howToFix: How to bring violating code into compliance.
    ///   - badExample: Swift source that breaks the rule.
    ///   - goodExample: Swift source that follows the rule.
    ///   - examplePath: The path both examples stand at. Give a rule that matches on a
    ///     directory a path containing it, otherwise its examples fall outside its own scope.
    ///   - check: The query that enforces the rule within a given scope.
    public init(
        id: String,
        summary: String? = nil,
        severity: Severity = .error,
        why: String? = nil,
        howToFix: String? = nil,
        badExample: String,
        goodExample: String,
        examplePath: String = Rule.snippetPath,
        check: @escaping (HarmonizeScope) -> Void
    ) {
        self.init(
            id: id,
            summary: summary,
            severity: severity,
            why: why,
            howToFix: howToFix,
            examples: Examples(badExample: badExample, goodExample: goodExample, path: examplePath),
            check: check
        )
    }
}

// MARK: - Reporting

public extension Rule {
    /// Everything the rule has to say about a violation, used as the failure message when an
    /// assertion supplies none.
    var formatted: String {
        var parts: [String] = []

        if let summary { parts.append("RULE: \(summary)") }
        if let why { parts.append("WHY: \(why)") }
        if let howToFix { parts.append("HOW TO FIX: \(howToFix)") }
        if let examples {
            parts.append("❌ BAD:\n\(examples.badExample)")
            parts.append("✅ GOOD:\n\(examples.goodExample)")
        }

        return parts.isEmpty ? id : parts.joined(separator: "\n\n")
    }
}

// MARK: - CustomStringConvertible

extension Rule: CustomStringConvertible {
    /// Swift Testing names the cases of a parameterized test after each argument's description.
    /// Without this the whole struct is printed for every case.
    public var description: String { id }
}

// MARK: - Evaluation

public extension Rule {
    /// Evaluates the rule against the given scope, reporting to the active ``Reporter``.
    func evaluate(in scope: HarmonizeScope) {
        RuleContext.with(self) {
            check(scope)
        }
    }

    /// Evaluates the rule against the given scope and returns what it found, leaving the
    /// active ``Reporter`` untouched.
    func result(in scope: HarmonizeScope) -> RuleResult {
        let reporter = CollectingReporter()
        HarmonizeReporting.withReporter(reporter) {
            evaluate(in: scope)
        }
        return RuleResult(violations: reporter.violations, failures: reporter.failures)
    }

    /// Evaluates the rule against plain Swift source.
    ///
    /// The source is given a path so rules asserting over files have something to point at. A
    /// rule matching on a directory needs a path containing it to see the source at all.
    ///
    /// - parameters:
    ///   - source: The Swift source to evaluate against.
    ///   - path: The path given to the source. No file needs to exist there.
    func result(inSource source: String, path: String = Rule.snippetPath) -> RuleResult {
        result(in: Harmonize.on(source: source, path: path))
    }

    /// The violations this rule reports against the given scope.
    func violations(in scope: HarmonizeScope) -> [Violation] {
        result(in: scope).violations
    }
}
