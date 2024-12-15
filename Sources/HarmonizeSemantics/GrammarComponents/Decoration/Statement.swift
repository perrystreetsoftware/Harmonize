//
//  Statement.swift
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

/// A representation of a raw fallback statement within a code body.
///
/// The `Statement` struct is used to capture unsupported or unrecognized semantic elements
/// found within a code body. This includes elements like variable declarations, which are
/// intentionally excluded from being directly supported in the `Body` type since they are
/// already categorized and accessible through their parent context (e.g via `.variables()`).
///
/// For example, if a variable declaration appears in the code block, it will be represented
/// as a `Statement` in cases where it cannot be semantically resolved into a more specific type.
public struct Statement: DeclarationDecoration, SyntaxNodeProviding {
    /// The underlying syntax node for the statement.
    public var node: CodeBlockItemSyntax
    
    /// A textual description of the statement, trimmed for readability.
    public var description: String {
        node.trimmedDescription
    }
    
    internal init(node: CodeBlockItemSyntax) {
        self.node = node
    }
}
