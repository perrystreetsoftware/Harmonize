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
    ///   - fileID: The file ID to which the assertion should be attributed.
    ///   - file: The file path to which the assertion should be attributed.
    ///   - line: The line number to which the assertion should be attributed.
    ///   - column: The line number to which the assertion should be attributed.
    ///   - condition: The test condition assertion.
    ///
    func assertTrue(
        message: String? = nil,
        strict: Bool = false,
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
        
        let matchingElements = filter { !condition($0) }
        
        report(
            elements: matchingElements,
            assertionMessage: "Expected true but was false on \(matchingElements.count) elements.",
            additionalMessage: message,
            fileID: fileID,
            file: file,
            line: line,
            column: column
        )
    }
    
    /// Asserts that the specified condition is false for all elements in the array while also reporting found issues in the
    /// original source code location, if possible.
    ///
    /// - parameters:
    ///   - message: An optional custom message to display in case of failure. If not provided, a default message will be used.
    ///   - strict: Flag to indicate if the test should run on strict mode, which will fail on empty collection. False by default.
    ///   - fileID: The file ID to which the assertion should be attributed.
    ///   - file: The file path to which the assertion should be attributed.
    ///   - line: The line number to which the assertion should be attributed.
    ///   - column: The line number to which the assertion should be attributed.
    ///   - condition: A closure that takes an element and returns a `Bool` indicating if the condition is met.
    ///
    func assertFalse(
        message: String? = nil,
        strict: Bool = false,
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
        
        let matchingElements = filter { condition($0) }
        
        report(
            elements: matchingElements,
            assertionMessage: "Expected false but was true on \(matchingElements.count) elements.",
            additionalMessage: message,
            fileID: fileID,
            file: file,
            line: line,
            column: column
        )
    }
    
    /// Asserts that the array is empty.
    ///
    /// - parameters:
    ///   - message: An optional custom message to display on failure. If not provided, a default message will be used.
    ///   - showErrorAtSource: Flag to indicate if the assertion should show the error in the original source code.
    ///   - fileID: The file ID to which the assertion should be attributed.
    ///   - file: The file path to which the assertion should be attributed.
    ///   - line: The line number to which the assertion should be attributed.
    ///   - column: The line number to which the assertion should be attributed.
    /// - warning: This method is experimental and subject to change.
    func assertEmpty(
        message: String? = nil,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        guard !isEmpty else { return }
        
        report(
            elements: self,
            assertionMessage: "Expected empty collection got \(count) elements instead.",
            additionalMessage: message,
            fileID: fileID,
            file: file,
            line: line,
            column: column
        )
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
