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

internal func reportIssues(_ issues: [CodeIssue]) {
    func useXCT(issue: CodeIssue) {
        issue.filePath.relativePath.withStaticString {
            XCTFail(issue.message, file: $0, line: UInt(issue.line))
        }
    }
    
    issues.forEach { issue in
        if isRunningSwiftTesting {
            #if canImport(Testing)
            Issue.record(
                .init(rawValue: issue.message),
                sourceLocation: SourceLocation(
                    fileID: issue.fileId,
                    filePath: issue.filePath.relativePath,
                    line: issue.line,
                    column: issue.column
                )
            )
            #else
            useXCT(issue: issue)
            #endif
        } else {
            useXCT(issue: issue)
        }
    }
}

internal func reportInline(
    message: String,
    fileID: StaticString = #fileID,
    file: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) {
    if isRunningSwiftTesting {
        #if canImport(Testing)
        Issue.record(
            .init(rawValue: message),
            sourceLocation: SourceLocation(
                fileID: fileID.description,
                filePath: file.description,
                line: Int(line),
                column: Int(column)
            )
        )
        #else
        XCTFail(message, file: file, line: line)
        #endif
    } else {
        XCTFail(message, file: file, line: line)
    }
}
