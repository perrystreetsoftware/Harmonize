//
//  ReturnClause.swift
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

/// The representation of a declaration's return clause.
public struct ReturnClause: DeclarationDecoration, SyntaxNodeProviding {
    /// The syntax node representing the return clause in the abstract syntax tree (AST).
    public let node: ReturnClauseSyntax
    
    public var description: String {
        node.trimmedDescription
    }
    
    internal init(node: ReturnClauseSyntax) {
        self.node = node
    }
    
    internal init?(node: ReturnClauseSyntax?) {
        guard let node = node else { return nil }
        self.node = node
    }
}

// MARK: - TypeProviding Comformance

extension ReturnClause: TypeProviding {
    /// The type annotation associated with the return clause, if present.
    /// - Returns: A `TypeAnnotation` instance if the return type is available, otherwise `nil`.
    public var typeAnnotation: TypeAnnotation? {
        TypeAnnotation(node: node.type)
    }
}
