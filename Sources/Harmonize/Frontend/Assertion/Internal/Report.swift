//
//  Report.swift
//  Harmonize
//
//  Copyright 2024 Perry Street Software Inc.

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

/// Records that an assertion carrying rule metadata ran, so the rule appears
/// in the ``RuleCatalog`` even when nothing violates it. Returns the rule
/// under its effective id (the catalog may suffix colliding derived ids), so
/// violations report the same id the catalog lists.
internal func registerRule(_ rule: Rule?, definedIn file: StaticString) -> Rule? {
    guard let rule else { return nil }
    return RuleCatalog.register(rule, definedIn: file.description)
}

/// Delivers one assertion's violations plus its aggregate summary to the
/// active ``Reporter``.
internal func reportViolations(
    _ issues: [CodeIssue],
    summary: String,
    rule: Rule?,
    fileID: StaticString,
    file: StaticString,
    line: UInt,
    column: UInt
) {
    HarmonizeReporting.reporter.report(
        violations: issues.map { $0.toViolation(rule: rule) },
        summary: summary,
        at: assertionLocation(fileID: fileID, file: file, line: line, column: column)
    )
}

/// Delivers a standalone failure at the assertion call site to the active ``Reporter``.
internal func reportInline(
    message: String,
    fileID: StaticString = #fileID,
    file: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) {
    HarmonizeReporting.reporter.report(
        failure: message,
        at: assertionLocation(fileID: fileID, file: file, line: line, column: column)
    )
}

private func assertionLocation(
    fileID: StaticString,
    file: StaticString,
    line: UInt,
    column: UInt
) -> AssertionLocation {
    AssertionLocation(
        fileID: fileID.description,
        filePath: file.description,
        line: Int(line),
        column: Int(column)
    )
}

internal extension CodeIssue {
    func toViolation(rule: Rule?) -> Violation {
        Violation(
            name: name,
            message: message,
            filePath: filePath,
            line: line,
            column: column,
            fileID: fileId,
            rule: rule
        )
    }
}
