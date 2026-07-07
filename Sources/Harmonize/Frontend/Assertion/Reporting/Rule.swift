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
/// identity and remediation guidance instead of just a failure string:
///
/// ```swift
/// viewModels.assertTrue(rule: .init(
///     id: "viewmodels-inherit-base",
///     rationale: "ViewModels must inherit BaseViewModel for lifecycle handling.",
///     fixHint: "Declare the class as `final class MyViewModel: BaseViewModel`."
/// )) { $0.inherits(from: "BaseViewModel") }
/// ```
public struct Rule: Codable, Equatable {
    public enum Severity: String, Codable, Equatable {
        case error
        case warning
    }

    /// Stable identifier for the rule, e.g. `"viewmodels-inherit-base"`.
    public let id: String

    /// How violations should be treated by consumers of the report.
    public let severity: Severity

    /// Why the rule exists — the architectural reasoning.
    public let rationale: String?

    /// How to bring violating code into compliance.
    public let fixHint: String?

    public init(
        id: String,
        severity: Severity = .error,
        rationale: String? = nil,
        fixHint: String? = nil
    ) {
        self.id = id
        self.severity = severity
        self.rationale = rationale
        self.fixHint = fixHint
    }
}
