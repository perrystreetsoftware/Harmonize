//
//  Fail.swift
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

import XCTest

internal func fail(
    issues: [(String, XCTIssue)],
    testMessage: String,
    showIssueAtSource: Bool = true,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let issuesLocation = issues.compactMap {
        if let location = $1.sourceCodeContext.location {
            return ($0, location)
        }
        
        return nil
    }
    
    let violations = issuesLocation
        .map { "\($1.fileURL):\($1.lineNumber) (\($0))" }
        .joined(separator: "\n\n")
    
    let detailedTestMessage = """
    \(testMessage)

    Found \(issues.count) violations:
    
    \(violations))
    """
    
    XCTFail(detailedTestMessage, file: file, line: line)
    
    guard showIssueAtSource else { return }
    
    issues.forEach { name, issue in
        if let location = issue.sourceCodeContext.location {
            location.fileURL.relativePath.withStaticString {
                XCTFail(
                    issue.compactDescription,
                    file: $0,
                    line: UInt(location.lineNumber)
                )
            }
        }
    }
}
