//
//  CollectingReporter.swift
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

/// A ``Reporter`` that accumulates results in memory instead of failing a test.
///
/// Unlike ``JSONReporter`` it keeps the domain types, allowing a ``Rule`` to inspect its
/// own results.
public final class CollectingReporter: Reporter {
    /// A failure attributed to the assertion call site rather than to a declaration.
    public struct Failure: Equatable {
        public let message: String
        public let location: AssertionLocation

        public init(message: String, location: AssertionLocation) {
            self.message = message
            self.location = location
        }
    }

    private let lock = NSLock()
    private var collectedViolations: [Violation] = []
    private var collectedFailures: [Failure] = []

    public init() {}

    public var violations: [Violation] {
        lock.lock()
        defer { lock.unlock() }
        return collectedViolations
    }

    public var failures: [Failure] {
        lock.lock()
        defer { lock.unlock() }
        return collectedFailures
    }

    public var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return collectedViolations.isEmpty && collectedFailures.isEmpty
    }

    public func report(violations: [Violation], summary: String, at location: AssertionLocation) {
        lock.lock()
        defer { lock.unlock() }
        collectedViolations.append(contentsOf: violations)

        // No violation had a resolvable source location, so the summary is the only record.
        if violations.isEmpty {
            collectedFailures.append(Failure(message: summary, location: location))
        }
    }

    public func report(failure message: String, at location: AssertionLocation) {
        lock.lock()
        defer { lock.unlock() }
        collectedFailures.append(Failure(message: message, location: location))
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        collectedViolations.removeAll()
        collectedFailures.removeAll()
    }
}

// MARK: - Equatable

extension AssertionLocation: Equatable {
    public static func == (lhs: AssertionLocation, rhs: AssertionLocation) -> Bool {
        lhs.fileID == rhs.fileID
            && lhs.filePath == rhs.filePath
            && lhs.line == rhs.line
            && lhs.column == rhs.column
    }
}
