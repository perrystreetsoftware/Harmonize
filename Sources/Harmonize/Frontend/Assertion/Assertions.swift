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

#if canImport(Testing)
  import Testing
#endif

/// An experimental extension providing assertions API for `Array` where `Element` conforms to `SyntaxNodeProviding`.
/// These utilities enable behavior-driven assertions on the elements of the array, such as checking conditions, count, and emptiness.
public extension Array where Element: SyntaxNodeProviding {
    /// Asserts that the specified condition is true for all elements in the array while also reporting found issues in the
    /// original source code location, if possible.
    ///
    /// - parameters:
    ///   - message: An optional custom message to display in case of failure. If not provided, a default message will be used.
    ///   - strict: Flag to indicate if the test should run on strict mode, which will fail on empty collection. False by default.
    ///   - baseline: An array of declaration names or filenames that are known violations. Elements matching a baseline entry
    ///     are expected to *fail* the condition; if they pass, a "stale baseline" error is reported so the entry can be removed.
    ///   - fileID: The file ID to which the assertion should be attributed.
    ///   - file: The file path to which the assertion should be attributed.
    ///   - line: The line number to which the assertion should be attributed.
    ///   - column: The line number to which the assertion should be attributed.
    ///   - condition: The test condition assertion.
    ///
    func assertTrue(
        message: String? = nil,
        strict: Bool = false,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column,
        condition: (Element) -> Bool
    ) {
        if strict && isEmpty {
            reportInline(
                message: "Expected true but got empty collection instead.",
                fileID: fileID,
                file: file,
                line: line,
                column: column
            )
            return
        }

        let normalElements = filter { !isInBaseline($0, baseline: baseline) }
        let failingNormalElements = normalElements.filter { !condition($0) }

        report(
            elements: failingNormalElements,
            assertionMessage: "Expected true but was false on \(failingNormalElements.count) elements.",
            additionalMessage: message,
            fileID: fileID,
            file: file,
            line: line,
            column: column
        )

        let baselineElements = filter { isInBaseline($0, baseline: baseline) }
        let staleElements = baselineElements.filter { condition($0) }

        report(
            elements: staleElements,
            assertionMessage: "Stale baseline: \(staleElements.count) element(s) now pass and should be removed from the baseline.",
            additionalMessage: "Stale baseline entry — this element now passes and should be removed from the baseline.",
            fileID: fileID,
            file: file,
            line: line,
            column: column
        )

        reportUnmatchedBaselineEntries(baseline: baseline, fileID: fileID, file: file, line: line, column: column)
    }

    /// Asserts that the specified condition is false for all elements in the array while also reporting found issues in the
    /// original source code location, if possible.
    ///
    /// - parameters:
    ///   - message: An optional custom message to display in case of failure. If not provided, a default message will be used.
    ///   - strict: Flag to indicate if the test should run on strict mode, which will fail on empty collection. False by default.
    ///   - baseline: An array of declaration names or filenames that are known violations. Elements matching a baseline entry
    ///     are expected to *pass* the condition (i.e. return true); if they return false, a "stale baseline" error is reported.
    ///   - fileID: The file ID to which the assertion should be attributed.
    ///   - file: The file path to which the assertion should be attributed.
    ///   - line: The line number to which the assertion should be attributed.
    ///   - column: The line number to which the assertion should be attributed.
    ///   - condition: A closure that takes an element and returns a `Bool` indicating if the condition is met.
    ///
    func assertFalse(
        message: String? = nil,
        strict: Bool = false,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column,
        condition: (Element) -> Bool
    ) {
        if strict && isEmpty {
            reportInline(
                message: "Expected false but got empty collection instead.",
                fileID: fileID,
                file: file,
                line: line,
                column: column
            )
            return
        }

        let normalElements = filter { !isInBaseline($0, baseline: baseline) }
        let matchingNormalElements = normalElements.filter { condition($0) }

        report(
            elements: matchingNormalElements,
            assertionMessage: "Expected false but was true on \(matchingNormalElements.count) elements.",
            additionalMessage: message,
            fileID: fileID,
            file: file,
            line: line,
            column: column
        )

        let baselineElements = filter { isInBaseline($0, baseline: baseline) }
        let staleElements = baselineElements.filter { !condition($0) }

        report(
            elements: staleElements,
            assertionMessage: "Stale baseline: \(staleElements.count) element(s) now fail and should be removed from the baseline.",
            additionalMessage: "Stale baseline entry — this element now fails and should be removed from the baseline.",
            fileID: fileID,
            file: file,
            line: line,
            column: column
        )

        reportUnmatchedBaselineEntries(baseline: baseline, fileID: fileID, file: file, line: line, column: column)
    }
    
    /// Asserts that the array is empty.
    ///
    /// - parameters:
    ///   - message: An optional custom message to display on failure. If not provided, a default message will be used.
    ///   - baseline: An array of declaration names or filenames that are known violations. Elements matching a baseline entry
    ///     are expected to be present and are excluded from the empty check.
    ///   - fileID: The file ID to which the assertion should be attributed.
    ///   - file: The file path to which the assertion should be attributed.
    ///   - line: The line number to which the assertion should be attributed.
    ///   - column: The line number to which the assertion should be attributed.
    /// - warning: This method is experimental and subject to change.
    func assertEmpty(
        message: String? = nil,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let nonBaselineElements = filter { !isInBaseline($0, baseline: baseline) }

        guard !nonBaselineElements.isEmpty else {
            reportUnmatchedBaselineEntries(baseline: baseline, fileID: fileID, file: file, line: line, column: column)
            return
        }

        report(
            elements: nonBaselineElements,
            assertionMessage: "Expected empty collection got \(nonBaselineElements.count) elements instead.",
            additionalMessage: message,
            fileID: fileID,
            file: file,
            line: line,
            column: column
        )

        reportUnmatchedBaselineEntries(baseline: baseline, fileID: fileID, file: file, line: line, column: column)
    }
    
    /// Asserts that the array is not empty.
    ///
    /// - parameters:
    ///   - fileID: The file ID to which the assertion should be attributed.
    ///   - file: The file path to which the assertion should be attributed.
    ///   - line: The line number to which the assertion should be attributed.
    ///   - column: The line number to which the assertion should be attributed.
    /// - warning: This method is experimental and subject to change.
    func assertNotEmpty(
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        guard isEmpty else { return }
        
        let message = "Expected non empty collection got empty instead."
        
        if isRunningSwiftTesting {
            #if canImport(Testing)
            Issue.record(
                .init(rawValue: message),
                sourceLocation: .init(
                    fileID: fileID.description,
                    filePath: file.description,
                    line: Int(line),
                    column: Int(column))
            )
            #else
            XCTFail(
                message,
                file: file,
                line: line
            )
            #endif
        } else {
            XCTFail(
                message,
                file: file,
                line: line
            )
        }
    }
    
    /// Asserts that the array has the specified number of elements.
    ///
    /// - parameters:
    ///   - count: The expected number of elements in the array.
    ///   - fileID: The file ID to which the assertion should be attributed.
    ///   - file: The file path to which the assertion should be attributed.
    ///   - line: The line number to which the assertion should be attributed.
    ///   - column: The line number to which the assertion should be attributed.
    /// - warning: This method is experimental and subject to change.
    func assertCount(
        count: Int,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        guard self.count != count else { return }
        
        guard count > 0 else {
            assertEmpty(fileID: fileID, file: file, line: line, column: column)
            return
        }
        
        let message = "Expected count to be \(count) got \(self.count)."
        
        if isRunningSwiftTesting {
            #if canImport(Testing)
            Issue.record(
                .init(rawValue: message),
                sourceLocation: .init(
                    fileID: fileID.description,
                    filePath: file.description,
                    line: Int(line),
                    column: Int(column))
            )
            #else
            XCTFail(
                message,
                file: file,
                line: line
            )
            #endif
        } else {
            XCTFail(
                message,
                file: file,
                line: line
            )
        }
    }
    
    private func isInBaseline(_ element: Element, baseline: [String]) -> Bool {
        if let named = element as? NamedDeclaration, baseline.contains(named.name) {
            return true
        }
        if let sourceProvider = element as? SourceCodeProviding,
           let fileName = sourceProvider.sourceCodeLocation.sourceFilePath?.lastPathComponent,
           baseline.contains(fileName) {
            return true
        }
        return false
    }

    private func reportUnmatchedBaselineEntries(
        baseline: [String],
        fileID: StaticString,
        file: StaticString,
        line: UInt,
        column: UInt
    ) {
        let unmatched = baseline.filter { entry in !contains { isInBaseline($0, baseline: [entry]) } }
        guard !unmatched.isEmpty else { return }
        let list = unmatched.map { "'\($0)'" }.joined(separator: ", ")
        reportInline(
            message: "Stale baseline: \(unmatched.count) entry/entries no longer match any element and should be removed: \(list)",
            fileID: fileID,
            file: file,
            line: line,
            column: column
        )
    }

    private func report(
        elements: [Element],
        assertionMessage: String,
        additionalMessage: String? = nil,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        var codeIssues: [CodeIssue] = []
        
        for element in elements {
            if let issue = element.toCodeIssue(message: additionalMessage) {
                codeIssues.append(issue)
            }
        }
                
        let loggableViolations = codeIssues.map {
            "(\($0.fileId))\n\($0.name):\($0.line):\($0.column)"
        }.joined(separator: "\n\n")
        
        let testName = additionalMessage ?? assertionMessage
        let inlineMessage = """
        \(testName)
            
        \(elements.count) issues were found:
            
        \(loggableViolations)
        """
        
        reportIssues(codeIssues)
        
        guard elements.isNotEmpty else { return }
        
        reportInline(
            message: inlineMessage,
            fileID: fileID,
            file: file,
            line: line,
            column: column
        )
    }
}
