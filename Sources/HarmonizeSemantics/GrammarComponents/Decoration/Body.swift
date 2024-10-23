//
//  Body.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
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

    /// An array of strings representing the body, with each string corresponding to a line
    /// (i.e., statement) in the body. Each statement is trimmed of leading/trailing whitespace.
    public var lines: [String] {
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
