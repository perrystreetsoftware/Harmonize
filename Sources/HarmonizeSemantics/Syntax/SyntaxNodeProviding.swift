//
//  SyntaxNodeProviding.swift
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

import SwiftSyntax

/// Protocol which provides the raw syntax node a declaration provides.
public protocol SyntaxNodeProviding: Equatable, Hashable {
    associatedtype Syntax: SyntaxProtocol

    /// The syntax node representing the declaration in the abstract syntax tree (AST).
    var node: Syntax { get }
}

extension SyntaxNodeProviding {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.node.id == rhs.node.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(node.id)
    }
}
