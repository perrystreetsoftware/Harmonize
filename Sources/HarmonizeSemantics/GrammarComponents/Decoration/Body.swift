//
//  Body.swift
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

/// A struct that represents the body of a declaration.
public struct Body: DeclarationDecoration, SyntaxNodeProviding {
    /// The syntax node representing the type annotation in the abstract syntax tree (AST).
    public let node: CodeBlockItemListSyntax

    /// The content of the body, represented as a single string.
    /// This is the concatenation of all statements inside the `CodeBlockSyntax`.
    ///
    /// For example, in a function:
    /// ```swift
    /// func greet() {
    ///     print("Hello, World!")
    /// }
    /// ```
    /// The `content` is `"print(\"Hello, World!\")"`.
    public var content: String {
        node.toString()
    }

    /// An array of strings representing the body, with each string corresponding to a statement
    /// in the body. Each statement is trimmed of leading/trailing whitespace.
    public var statements: [String] {
        node.map(\.trimmedDescription)
    }

    public var description: String {
        node.trimmedDescription
    }

    internal init(node: CodeBlockItemListSyntax) {
        self.node = node
    }

    internal init?(node: CodeBlockItemListSyntax?) {
        guard let node = node else { return nil }
        self.node = node
    }
}
