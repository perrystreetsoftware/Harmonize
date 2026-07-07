//
//  XCTestReporter.swift
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
import HarmonizeUtils
import XCTest

#if canImport(Testing)
import Testing
#endif

internal var isRunningSwiftTesting: Bool {
    #if canImport(Testing)
    return Test.current != nil
    #else
    return false
    #endif
}

/// The default ``Reporter``: fails the surrounding test.
///
/// Each violation is recorded at the violating source location (so IDEs and CI
/// annotate the offending file), plus one aggregate failure at the assertion
/// call site. Works under both XCTest and swift-testing.
public struct XCTestReporter: Reporter {
    public init() {}

    public func report(violations: [Violation], summary: String, at location: AssertionLocation) {
        violations.forEach(record(violation:))
        report(failure: summary, at: location)
    }

    public func report(failure message: String, at location: AssertionLocation) {
        if isRunningSwiftTesting {
            #if canImport(Testing)
            Issue.record(
                .init(rawValue: message),
                sourceLocation: SourceLocation(
                    fileID: location.fileID,
                    filePath: location.filePath,
                    line: location.line,
                    column: location.column
                )
            )
            return
            #endif
        }

        location.filePath.withStaticString {
            XCTFail(message, file: $0, line: UInt(location.line))
        }
    }

    private func record(violation: Violation) {
        if isRunningSwiftTesting {
            #if canImport(Testing)
            Issue.record(
                .init(rawValue: violation.message),
                sourceLocation: SourceLocation(
                    fileID: violation.fileID,
                    filePath: violation.filePath.relativePath,
                    line: violation.line,
                    column: violation.column
                )
            )
            return
            #endif
        }

        violation.filePath.relativePath.withStaticString {
            XCTFail(violation.message, file: $0, line: UInt(violation.line))
        }
    }
}
