//
//  Assertions.swift
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
import HarmonizeSemantics
import SwiftSyntax
import XCTest

public extension Array where Element: SwiftSourceCode {
    func assertTrue(
        message: String? = nil,
        strict: Bool = false,
        file: StaticString = #filePath,
        condition: (Element) -> Bool
    ) {
        if strict && isEmpty {
            XCTFail("Expected true but got empty collection instead.", file: file)
            return
        }

        let issues = elements(matching: { !condition($0) }).toXCTIssues(message: message)
        guard !issues.isEmpty else { return }

        fail(
            issues: issues,
            testMessage: message ?? "Expected true but was false on \(issues.count) elements.",
            file: file
        )
    }

    func assertFalse(
        message: String? = nil,
        strict: Bool = false,
        file: StaticString = #filePath,
        condition: (Element) -> Bool
    ) {
        if strict && isEmpty {
            XCTFail("Expected true but got empty collection instead.", file: file)
            return
        }

        let issues = elements(matching: { condition($0) }).toXCTIssues(message: message)
        guard !issues.isEmpty else { return }

        fail(
            issues: issues,
            testMessage: message ?? "Expected true but was false on \(issues.count) elements.",
            file: file
        )
    }

    func assertEmpty(
        message: String? = nil,
        showErrorAtSource: Bool = true,
        file: StaticString = #filePath
    ) {
        guard !isEmpty else { return }

        let issues = toXCTIssues(message: message)

        fail(
            issues: issues,
            testMessage: message ?? "Expected empty collection got \(issues.count) elements instead.",
            showIssueAtSource: showErrorAtSource,
            file: file
        )
    }
    /// Asserts that the array is not empty.
    ///
    /// - parameters:
    ///   - file: The file path to use in the assertion. Defaults to the calling file.
    ///   - line: The line number to use in the assertion. Defaults to the calling line.
    /// - warning: This method is experimental and subject to change.
    func assertNotEmpty(
        file: StaticString = #filePath
    ) {
        guard isEmpty else { return }
        XCTFail(
            "Expected non empty collection got empty instead.",
            file: file
        )
    }

    /// Asserts that the array has the specified number of elements.
    ///
    /// - parameters:
    ///   - count: The expected number of elements in the array.
    ///   - file: The file path to use in the assertion. Defaults to the calling file.
    ///   - line: The line number to use in the assertion. Defaults to the calling line.
    /// - warning: This method is experimental and subject to change.
    func assertCount(
        count: Int,
        file: StaticString = #filePath
    ) {
        guard self.count != count else { return }

        guard count > 0 else {
            assertEmpty()
            return
        }

        XCTFail(
            "Assertion failed expecting count \(count) got \(self.count).",
            file: file
        )
    }

    private func elements(matching: (Element) -> Bool) -> [Element] {
        filter(matching)
    }

    private func toXCTIssues(message: String? = nil) -> [(String, XCTIssue)] {
        compactMap {
            let name = ($0 as? NamedDeclaration)?.name ?? String(describing: $0)
            guard let issue = $0.issue(with: message ?? "\(name) did not match a test requirement.") else { return nil }

            return (name, issue)
        }
    }
}
