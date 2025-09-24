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
import IssueReporting

internal func reportIssues(_ issues: [CodeIssue]) {
    issues.forEach { issue in
        issue.fileId.withStaticString { fileID in
            issue.filePath.relativePath.withStaticString { filePath in
                IssueReporting.reportIssue(
                    issue.message,
                    fileID: fileID,
                    filePath: filePath,
                    line: UInt(issue.line),
                    column: UInt(issue.column)
                )
            }
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
    IssueReporting.reportIssue(
        message,
        fileID: fileID,
        filePath: file,
        line: line,
        column: column
    )
}
