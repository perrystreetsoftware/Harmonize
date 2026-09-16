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

/// Metadata describing an architectural rule.
///
/// Attach a `Rule` to an assertion so violations carry machine-readable
/// identity and remediation guidance instead of just a failure string.
/// When no explicit `message` is passed to the assertion, the failure text is
/// ``message``, which lays out every provided field:
///
/// ```swift
/// viewModels.assertTrue(rule: .init(
///     description: "ViewModels inherit from BaseViewModel.",
///     rationale: "BaseViewModel owns the lifecycle and cancellable handling every screen relies on.",
///     fixHint: "Declare the class as `final class MyViewModel: BaseViewModel`.",
///     badExample: "final class MyViewModel: ObservableObject { }",
///     goodExample: "final class MyViewModel: BaseViewModel { }"
/// )) { $0.inherits(from: "BaseViewModel") }
/// ```
public struct Rule: Codable, Equatable {
    public enum Severity: String, Codable, Equatable {
        case error
        case warning
    }

    /// Stable identifier for the rule. Defaults to the name of the file that declares
    /// the rule, without its extension, e.g. `ViewModelsInheritBaseViewModel`.
    public let id: String

    /// How violations should be treated by consumers of the report.
    public let severity: Severity

    /// One-line statement of what the rule requires, shown as the headline of ``message``.
    public let description: String?

    /// Why the rule exists — the architectural reasoning.
    public let rationale: String?

    /// How to bring violating code into compliance.
    public let fixHint: String?

    /// A short snippet that violates the rule.
    public let badExample: String?

    /// A short snippet that satisfies the rule.
    public let goodExample: String?

    /// - parameters:
    ///   - id: Stable identifier for the rule. When nil, the name of the declaring file is used,
    ///     so a file that declares more than one rule should give each an explicit id.
    ///   - fileID: The file that declares the rule; used to derive the default `id`.
    public init(
        id: String? = nil,
        severity: Severity = .error,
        description: String? = nil,
        rationale: String? = nil,
        fixHint: String? = nil,
        badExample: String? = nil,
        goodExample: String? = nil,
        fileID: StaticString = #fileID
    ) {
        self.id = id ?? Rule.defaultId(from: fileID)
        self.severity = severity
        self.description = description
        self.rationale = rationale
        self.fixHint = fixHint
        self.badExample = badExample
        self.goodExample = goodExample
    }

    /// The human-readable failure text for this rule: the ``description`` (or ``id``)
    /// followed by each provided section — why, how to fix, and the bad and good examples.
    public var message: String {
        let sections: [String?] = [
            "RULE: \(description ?? id)",
            rationale.map { "WHY: \($0)" },
            fixHint.map { "HOW TO FIX: \($0)" },
            badExample.map { "❌ BAD:\n\($0)" },
            goodExample.map { "✅ GOOD:\n\($0)" },
        ]

        return sections.compactMap { $0 }.joined(separator: "\n\n")
    }

    private static func defaultId(from fileID: StaticString) -> String {
        let fileName = fileID.description.split(separator: "/").last.map(String.init) ?? fileID.description
        guard let dot = fileName.lastIndex(of: ".") else { return fileName }
        return String(fileName[..<dot])
    }
}
