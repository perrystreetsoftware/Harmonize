//
//  Reporter.swift
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

/// The source position of the assertion call itself — i.e. the rule's
/// definition site, as opposed to the violating code's location.
public struct AssertionLocation {
    public let fileID: String
    public let filePath: String
    public let line: Int
    public let column: Int

    public init(fileID: String, filePath: String, line: Int, column: Int) {
        self.fileID = fileID
        self.filePath = filePath
        self.line = line
        self.column = column
    }
}

/// A single rule violation, attributed at the violating source location.
public struct Violation {
    /// The violating declaration or file name.
    public let name: String

    /// The failure message, typically the rule's guidance text.
    public let message: String

    /// The violating source file.
    public let filePath: URL

    /// 1-based line of the violating declaration.
    public let line: Int

    /// 1-based column of the violating declaration.
    public let column: Int

    /// `Module/File.swift`-style identifier of the violating file.
    public let fileID: String

    /// Metadata of the rule that produced this violation, when provided.
    public let rule: Rule?

    public init(
        name: String,
        message: String,
        filePath: URL,
        line: Int,
        column: Int,
        fileID: String,
        rule: Rule? = nil
    ) {
        self.name = name
        self.message = message
        self.filePath = filePath
        self.line = line
        self.column = column
        self.fileID = fileID
        self.rule = rule
    }
}

/// Receives the outcome of Harmonize assertions.
///
/// The default reporter fails the surrounding XCTest or swift-testing test,
/// preserving Harmonize's behavior as a test-target linter. Alternative
/// reporters (e.g. ``JSONReporter``) let the same rules run outside a test
/// process and produce machine-readable violations.
public protocol Reporter {
    /// Reports the violations found by one assertion, along with a
    /// human-readable summary attributed at the assertion call site.
    ///
    /// Only called when at least one element failed the assertion; `violations`
    /// may still be empty if no failing element had a resolvable source location
    /// (`summary` then carries the only record of the failure).
    func report(violations: [Violation], summary: String, at location: AssertionLocation)

    /// Reports a standalone failure attributed at the assertion call site,
    /// such as a strict-mode empty collection or a stale baseline entry.
    func report(failure message: String, at location: AssertionLocation)
}

/// Process-wide access to the active ``Reporter``.
public enum HarmonizeReporting {
    private static let lock = NSLock()
    private static var activeReporter: Reporter = XCTestReporter()

    /// The reporter all assertions deliver their results to.
    /// Defaults to ``XCTestReporter``.
    public static var reporter: Reporter {
        get {
            lock.lock()
            defer { lock.unlock() }
            return activeReporter
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            activeReporter = newValue
        }
    }

    /// Runs `body` with `reporter` temporarily installed, restoring the
    /// previous reporter afterwards.
    public static func withReporter<T>(_ reporter: Reporter, _ body: () throws -> T) rethrows -> T {
        let previous = self.reporter
        self.reporter = reporter
        defer { self.reporter = previous }
        return try body()
    }
}
