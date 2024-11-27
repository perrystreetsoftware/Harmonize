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

/// An experimental extension providing assertions API for `Array` where `Element` conforms to `SyntaxNodeProviding`.
/// These utilities enable behavior-driven assertions on the elements of the array, such as checking conditions, count, and emptiness.
public extension Array where Element: SyntaxNodeProviding {
    /// Asserts that the specified condition is true for all elements in the array while also reporting found issues in the
    /// original source code location. This is an experimental feature and may not function properly.
    ///
    /// - parameters:
    ///   - message: An optional custom message to display on failure. If not provided, a default message will be used.
    ///   - showErrorAtSource: Flag to indicate if the assertion should show the error in the original source code.
    ///   - file: The file path to use in the assertion. Defaults to the calling file.
    ///   - line: The line number to use in the assertion. Defaults to the calling line.
    ///   - condition: A closure that takes an element and returns a `Bool` indicating if the condition is met.
    /// - warning: This method will try report all issues in the original source code location when available.
    func assertTrue(
        message: String? = nil,
        showErrorAtSource: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line,
        condition: (Element) -> Bool
    ) {
        let issues = elements(matching: { !condition($0) }).toXCTIssues(message: message)
        guard !issues.isEmpty else { return }
        
        fail(
            issues: issues,
            testMessage: message ?? "Expected true but was false on \(issues.count) elements.",
            showIssueAtSource: showErrorAtSource,
            file: file,
            line: line
        )
    }
    
    /// Asserts that the specified condition is false for all elements in the array while also reporting found issues in the
    /// original source code location. This is an experimental feature and may not function properly.
    ///
    /// - parameters:
    ///   - message: An optional custom message to display on failure. If not provided, a default message will be used.
    ///   - showErrorAtSource: Flag to indicate if the assertion should show the error in the original source code.
    ///   - file: The file path to use in the assertion. Defaults to the calling file.
    ///   - line: The line number to use in the assertion. Defaults to the calling line.
    ///   - condition: A closure that takes an element and returns a `Bool` indicating if the condition is met.
    /// - warning: This method will try report all issues in the original source code location when available.
    func assertFalse(
        message: String? = nil,
        showErrorAtSource: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line,
        condition: (Element) -> Bool
    ) {
        let issues = elements(matching: { condition($0) }).toXCTIssues(message: message)
        guard !issues.isEmpty else { return }
        
        fail(
            issues: issues,
            testMessage: message ?? "Expected false but was true on \(issues.count) elements.",
            showIssueAtSource: showErrorAtSource,
            file: file,
            line: line
        )
    }
    
    /// Asserts that the array is empty.
    ///
    /// - parameters:
    ///   - message: An optional custom message to display on failure. If not provided, a default message will be used.
    ///   - showErrorAtSource: Flag to indicate if the assertion should show the error in the original source code.
    ///   - file: The file path to use in the assertion. Defaults to the calling file.
    ///   - line: The line number to use in the assertion. Defaults to the calling line.
    /// - warning: This method is experimental and subject to change.
    func assertEmpty(
        message: String? = nil,
        showErrorAtSource: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard !isEmpty else { return }
        
        let issues = toXCTIssues(message: message)
        
        fail(
            issues: issues,
            testMessage: message ?? "Expected empty collection got \(issues.count) elements instead.",
            showIssueAtSource: showErrorAtSource,
            file: file,
            line: line
        )
    }
    
    /// Asserts that the array is not empty.
    ///
    /// - parameters:
    ///   - file: The file path to use in the assertion. Defaults to the calling file.
    ///   - line: The line number to use in the assertion. Defaults to the calling line.
    /// - warning: This method is experimental and subject to change.
    func assertNotEmpty(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard isEmpty else { return }
        XCTFail(
            "Expected non empty collection got empty instead.",
            file: file,
            line: line
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
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard self.count != count else { return }
        
        guard count > 0 else {
            assertEmpty()
            return
        }
        
        XCTFail(
            "Assertion failed expecting count \(count) got \(self.count).",
            file: file,
            line: line
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
