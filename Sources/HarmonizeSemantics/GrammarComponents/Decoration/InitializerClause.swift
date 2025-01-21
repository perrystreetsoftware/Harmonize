//
//  InitializerClause.swift
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
import SwiftParser

/// The representation of a declaration's initializer clause.
public struct InitializerClause: DeclarationDecoration, SyntaxNodeProviding {
    /// The syntax node representing the initializer clause in the abstract syntax tree (AST).
    public let node: InitializerClauseSyntax
    
    public var description: String {
        node.trimmedDescription
    }
    
    /// The value of the initializer clause, representing the content assigned after the `=` sign.
    ///
    /// For example, in the declaration `var prop = "xyz"`, the `value` is `"xyz"`.
    public var value: String {
        let literalValue = node.value.as(StringLiteralExprSyntax.self)?.representedLiteralValue
        return literalValue ?? node.value.trimmedDescription
    }
    
    /// A bool that indicates if this initializer's value is a self reference, such as in `if let self = self`
    ///
    /// - Returns: true if this initializer is a self reference.
    public var isSelfReference: Bool {
        node.value.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind == .keyword(.`self`)
    }
    
    internal init(node: InitializerClauseSyntax) {
        self.node = node
    }
    
    internal init?(node: InitializerClauseSyntax?) {
        guard let node = node else { return nil }
        self.node = node
    }
}
