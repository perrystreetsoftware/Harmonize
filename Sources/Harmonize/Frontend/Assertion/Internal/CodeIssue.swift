//
//  CodeIssue.swift
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

internal struct CodeIssue {
    let name: String
    let message: String
    let line: Int
    let column: Int
    let filePath: URL
    
    var fileId: String {
        let components = filePath.pathComponents
        
        guard
            let sources = components.firstIndex(of: "Sources"),
            sources + 1 < components.count
        else {
            return "UnknownModule/\(filePath.lastPathComponent)"
        }
        
        let moduleName = components[sources + 1]
        let fileName = filePath.lastPathComponent
        
        return "\(moduleName)/\(fileName)"
    }
}

internal extension SwiftSourceCode {
    func toCodeIssue(message: String?) -> CodeIssue? {
        guard let sourcePath = filePath else { return nil }
        
        let name = fileName ?? "UnknownFile"
        let message = message ?? "\(name) didn't match the test requirement."

        return CodeIssue(
            name: name,
            message: message,
            line: 1,
            column: 1,
            filePath: sourcePath
        )
    }
}

internal extension SyntaxNodeProviding {
    func toCodeIssue(message: String?) -> CodeIssue? {
        let name = (self as? NamedDeclaration)?.name ?? String(describing: self)
        let message = message ?? "\(name) didn't match the test requirement."
        
        guard let sourceCodeProvider = self as? SourceCodeProviding else { return nil }
        
        guard let sourcePath = sourceCodeProvider.sourceCodeLocation.sourceFilePath
        else { return nil }
        
        let locationCoverter = SourceLocationConverter(
            fileName: sourcePath.relativePath,
            tree: sourceCodeProvider.sourceCodeLocation.sourceFileTree
        )
        
        let location = self.node.startLocation(converter: locationCoverter)
        
        return CodeIssue(
            name: name,
            message: message,
            line: location.line,
            column: location.column,
            filePath: sourcePath
        )
    }
}
