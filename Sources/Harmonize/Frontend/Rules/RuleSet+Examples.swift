//
//  RuleSet+Examples.swift
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

public extension Rule {
    /// Asserts that this rule's examples demonstrate it, by evaluating the rule against both.
    ///
    /// Rules without examples pass. Rules matching on a specific path or module layout can't
    /// be evaluated against plain source and shouldn't declare examples.
    func assertExamples(
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        guard let examples else { return }

        let bad = result(inSource: examples.badExample, path: examples.path)

        if let message = ignoredScopeMessage(bad, path: examples.path) {
            reportInline(message: message, fileID: fileID, file: file, line: line, column: column)
            return
        }

        if bad.isEmpty {
            reportInline(
                message: """
                Rule '\(id)' does not fire on its own bad example, evaluated at \
                '\(examples.path)'. Either the example doesn't break the rule, or the rule \
                matches on a directory that path is not in, so it never saw the example. \
                Set `examplePath:` to a path within the rule's scope.
                """,
                fileID: fileID,
                file: file,
                line: line,
                column: column
            )
        }

        let unexpected = result(inSource: examples.goodExample, path: examples.path)

        if let message = ignoredScopeMessage(unexpected, path: examples.path) {
            reportInline(message: message, fileID: fileID, file: file, line: line, column: column)
            return
        }

        if !unexpected.isEmpty {
            reportInline(
                message: """
                Rule '\(id)' fires on its own good example (\(unexpected.describedReports)), \
                so the example documents a violation as if it were correct code.
                """,
                fileID: fileID,
                file: file,
                line: line,
                column: column
            )
        }
    }

    /// Asserts that this rule reports at least one violation in the given source.
    ///
    /// A query matching nothing looks the same as a clean codebase, use this while writing a
    /// rule to check it actually fires.
    func assertFires(
        on source: String,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let found = result(inSource: source)

        if let message = ignoredScopeMessage(found, path: Rule.snippetPath) {
            reportInline(message: message, fileID: fileID, file: file, line: line, column: column)
            return
        }

        guard found.isEmpty else { return }

        reportInline(
            message: "Expected rule '\(id)' to report a violation in the given source, but it reported none.",
            fileID: fileID,
            file: file,
            line: line,
            column: column
        )
    }

    /// Asserts that this rule reports no violations in the given source.
    func assertPasses(
        on source: String,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let found = result(inSource: source)

        if let message = ignoredScopeMessage(found, path: Rule.snippetPath) {
            reportInline(message: message, fileID: fileID, file: file, line: line, column: column)
            return
        }

        guard !found.isEmpty else { return }

        reportInline(
            message: """
            Expected rule '\(id)' to report no violations in the given source, but it reported \
            \(found.count): \(found.describedReports).
            """,
            fileID: fileID,
            file: file,
            line: line,
            column: column
        )
    }
}

public extension RuleSet {
    /// Asserts that every rule's examples demonstrate the rule they illustrate.
    static func assertExamples(
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        rules.forEach {
            $0.assertExamples(fileID: fileID, file: file, line: line, column: column)
        }
    }
}

// MARK: - Ignored scope

private extension Rule {
    /// Reports when a rule answered from somewhere other than the source it was given.
    ///
    /// A check that builds its own scope instead of querying the one it receives still works
    /// under ``RuleSet/assertAll(in:)``, but against plain source it reads the project and
    /// every answer here becomes meaningless, in both directions.
    func ignoredScopeMessage(_ result: RuleResult, path: String) -> String? {
        let evaluated = SnippetPath.url(for: path).path
        let elsewhere = result.violations.filter { $0.filePath.path != evaluated }

        guard !elsewhere.isEmpty else { return nil }

        let files = Set(elsewhere.map { $0.filePath.lastPathComponent }).sorted()

        return """
        Rule '\(id)' reported violations in \(files.joined(separator: ", ")) while being evaluated \
        against plain source. Its check builds its own scope instead of using the one it is given, \
        so it can't be evaluated against a snippet. Take the declarations from the `scope` \
        parameter of the check closure.
        """
    }
}
