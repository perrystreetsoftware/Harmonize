//
//  SyntaxNodeProviding+XCTIssue.swift
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

import HarmonizeSemantics
import SwiftSyntax
import XCTest

internal extension SyntaxNodeProviding {
    func issue(with message: String) -> XCTIssue? {
        guard let sourceCodeProvider = self as? SourceCodeProviding else { return nil }
        
        guard let sourcePath = sourceCodeProvider.sourceCodeLocation.sourceFilePath
        else { return nil }
        
        let locationCoverter = SourceLocationConverter(
            fileName: sourcePath.relativePath,
            tree: sourceCodeProvider.sourceCodeLocation.sourceFileTree
        )
        
        let lineNumber = self.node.startLocation(converter: locationCoverter).line
        
        let sourceCodeLocation = XCTSourceCodeLocation(
            fileURL: sourcePath,
            lineNumber: lineNumber
        )
        
        return XCTIssue(
            type: .assertionFailure,
            compactDescription: message,
            detailedDescription: message,
            sourceCodeContext: .init(location: sourceCodeLocation)
        )
    }
}
