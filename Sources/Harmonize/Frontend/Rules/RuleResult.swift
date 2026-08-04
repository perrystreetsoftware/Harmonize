//
//  RuleResult.swift
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

/// Everything a ``Rule`` reported against a scope.
///
/// A rule reported something when either collection is not empty. Failures are the reports
/// that couldn't be attributed to a declaration, such as a strict mode empty scope, a stale
/// baseline entry, or an assertion over files on source that has no file behind it.
public struct RuleResult {
    /// Violations attributed to a declaration or file.
    public let violations: [Violation]

    /// Reports attributed to the assertion itself.
    public let failures: [CollectingReporter.Failure]

    public init(violations: [Violation], failures: [CollectingReporter.Failure]) {
        self.violations = violations
        self.failures = failures
    }

    public var isEmpty: Bool {
        violations.isEmpty && failures.isEmpty
    }

    public var count: Int {
        violations.count + failures.count
    }

    internal var describedReports: String {
        (violations.map(\.name) + failures.map(\.message)).joined(separator: ", ")
    }
}
