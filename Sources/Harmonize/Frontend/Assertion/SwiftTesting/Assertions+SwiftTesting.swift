//
//  Assertions+SwiftTesting.swift
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
import Testing

/// An experimental extension providing Swift Testing Assertions API for `Array` where `Element` conforms to `SyntaxNodeProviding`.
/// These utilities enable behavior-driven assertions on the elements of the array, such as checking conditions, count, and emptiness.
///
/// Please note that while the recommended assertion for Swift Testing is ``#expect`` we are unable to use it right now
/// because Harmonize record issues at the source code location and this would not be possible with only ``#expect``
public extension Array where Element: SyntaxNodeProviding {
    /// Expect that all elements in the array match the given condition while also reporting found issues in the
    /// original source code location. This is an experimental feature and may not function properly.
    ///
    /// - parameters:
    ///   - additionalMessage: An optional custom message to display on failure. If not provided, a default message will be used.
    ///   - strict: Flag to indicate if the test should run on strict mode, which will fail on empty collection. False by default.
    ///   - sourceLocation: Source location where this method is being call.
    ///   - condition: A closure that takes an element and returns a `Bool` indicating if the condition is met.
    /// - warning: This method will try report all issues in the original source code location when available.
    func expectAll(
        additionalMessage: String? = nil,
        strict: Bool = false,
        sourceLocation: Testing.SourceLocation = #_sourceLocation,
        condition: (Element) -> Bool
    ) {
        if strict && isEmpty {
            Issue.record(
                "there are no elements in the array.",
                sourceLocation: sourceLocation
            )
            return
        }
        
        let issues = filter { !condition($0) }
        
        report(
            issues: issues,
            testMessage: "\(issues.count) elements didn't match the test requirement.",
            sourceLocation: sourceLocation
        )
    }
    
    /// Expect that no elements in the array match the given condition while also reporting found issues in the
    /// original source code location. This is an experimental feature and may not function properly.
    ///
    /// - parameters:
    ///   - additionalMessage: An optional custom message to display on failure. If not provided, a default message will be used.
    ///   - strict: Flag to indicate if the test should run on strict mode, which will fail on empty collection. False by default.
    ///   - sourceLocation: Source location where this method is being call.
    ///   - condition: A closure that takes an element and returns a `Bool` indicating if the condition is met.
    /// - warning: This method will try report all issues in the original source code location when available.
    func expectNone(
        additionalMessage: String? = nil,
        strict: Bool = false,
        sourceLocation: Testing.SourceLocation = #_sourceLocation,
        condition: (Element) -> Bool
    ) {
        expectAll(
            additionalMessage: additionalMessage,
            strict: strict,
            sourceLocation: sourceLocation,
            condition: { element in !condition(element) }
        )
    }
    
    /// Expect no elements in the array while also reporting existing elements in the
    /// original source code location. This is an experimental feature and may not function properly.
    ///
    /// - parameters:
    ///   - additionalMessage: An optional custom message to display on failure. If not provided, a default message will be used.
    ///   - strict: Flag to indicate if the test should run on strict mode, which will fail on empty collection. False by default.
    ///   - sourceLocation: Source location where this method is being call.
    ///   - condition: A closure that takes an element and returns a `Bool` indicating if the condition is met.
    /// - warning: This method will try report all issues in the original source code location when available.
    func expectEmpty(
        additionalMessage: String? = nil,
        sourceLocation: Testing.SourceLocation = #_sourceLocation
    ) {
        guard isNotEmpty else { return }
        report(
            issues: self,
            additionalMessage: additionalMessage,
            testMessage: "\(count) elements were found in the array.",
            sourceLocation: sourceLocation
        )
    }
    
    /// Expect elements in the array
    ///
    /// - parameters:
    ///   - additionalMessage: An optional custom message to display on failure. If not provided, a default message will be used.
    ///   - strict: Flag to indicate if the test should run on strict mode, which will fail on empty collection. False by default.
    ///   - sourceLocation: Source location where this method is being call.
    ///   - condition: A closure that takes an element and returns a `Bool` indicating if the condition is met.
    /// - warning: This method will try report all issues in the original source code location when available.
    func expectNotEmpty(
        additionalMessage: String? = nil,
        sourceLocation: Testing.SourceLocation = #_sourceLocation
    ) {
        #expect(
            isNotEmpty,
            .init(stringLiteral: additionalMessage ?? "there are no elements in the array."),
            sourceLocation: sourceLocation
        )
    }
    
    private func report(
        issues: [Element],
        additionalMessage: String? = nil,
        testMessage: String,
        issueFallbackMessage: String = "did not match a test requirement.",
        sourceLocation: Testing.SourceLocation = #_sourceLocation
    ) {
        var issuesLocation: [SwiftSyntax.SourceLocation] = []
        var recordables: [Testing.Issue] = []
        
        for issue in issues {
            let name = (issue as? NamedDeclaration)?.name ?? String(describing: issue)
            
            let message = additionalMessage ?? "\(name) \(issueFallbackMessage)"
            
            guard
                let sourceCodeLocationProvider = (issue as? SourceCodeProviding),
                let sourcePath = sourceCodeLocationProvider.sourceCodeLocation.sourceFilePath
            else {
                recordables.append(.record(.init(rawValue: message), sourceLocation: sourceLocation))
                continue
            }
            
            let locationCoverter = SourceLocationConverter(
                fileName: sourcePath.relativePath,
                tree: sourceCodeLocationProvider.sourceCodeLocation.sourceFileTree
            )
            
            let startLocation = issue.node.startLocation(converter: locationCoverter)
            issuesLocation.append(startLocation)
            
            let record = Issue.record(
                .init(stringLiteral: message),
                sourceLocation: .init(
                    fileID: fileId(for: sourcePath),
                    filePath: sourcePath.relativePath,
                    line: startLocation.line,
                    column: startLocation.column
                )
            )
            
            recordables.append(record)
        }
        
        guard recordables.isNotEmpty else { return }
        
        let violations = issuesLocation
            .map { "\($0.file):\($0.line):\($0.column) (\($0))" }
            .joined(separator: "\n\n")
        
        let loggableIssues = issues.map {
            ($0 as? NamedDeclaration)?.name ?? String(describing: $0)
        }.joined(separator: "\n\n")
        
        let loggableViolations = violations.isEmpty ? loggableIssues : violations
        
        let testName = additionalMessage ?? testMessage
                
        Issue.record(
            """
            \(testName)
            
            \(issues.count) issues were found:
            
            \(loggableViolations)
            """,
            sourceLocation: sourceLocation
        )
    }
    
    // We will try to guess the fileId for the given file path based on the Sources file.
    // This might work fine for Swift packages and for non SPM projects it will return the two last path component if possible.
    private func fileId(for url: URL) -> String {
        let components = url.pathComponents
        
        guard
            let sources = components.firstIndex(of: "Sources"),
            sources + 1 < components.count
        else {
            return "UnknownModule/\(url.lastPathComponent)"
        }
        
        let moduleName = components[sources + 1]
        let fileName = url.lastPathComponent
        
        return "\(moduleName)/\(fileName)"
    }
}
