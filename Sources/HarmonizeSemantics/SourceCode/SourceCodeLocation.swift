//
//  SourceCodeLocation.swift
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
import SwiftSyntax

/// Represents the original file/location a given node belongs to.
/// This doesn't know about the exact location of a node.
public struct SourceCodeLocation {
    /// The file path to the source code file, if any.
    public let sourceFilePath: URL?
    
    /// The parsed original source file syntax tree.
    public let sourceFileTree: SourceFileSyntax
    
    public init(
        sourceFilePath: URL?,
        sourceFileTree: SourceFileSyntax
    ) {
        self.sourceFilePath = sourceFilePath
        self.sourceFileTree = sourceFileTree
    }
}
