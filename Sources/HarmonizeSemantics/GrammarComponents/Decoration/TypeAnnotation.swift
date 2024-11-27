//
//  TypeAnnotation.swift
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

/// Represents a Swift type annotation, such as `String`, `Int`, `Bool`, or a created type.
/// This also supports optional types and can provide a formatted annotation string for both optional and non-optional types.
public struct TypeAnnotation: DeclarationDecoration, SyntaxNodeProviding {
    /// The syntax node representing the type annotation in the abstract syntax tree (AST).
    public let node: TypeSyntax
    
    /// The name of the Swift type. This could be a standard type like `String`, `Int`, or a created type.
    /// For optional types, the `?` is included in the name (e.g., `String?`).
    public var name: String {
        node.trimmedDescription
    }
    
    /// A boolean value indicating whether the type is optional (`true` if the type is an optional, otherwise `false`).
    public var isOptional: Bool {
        node.is(OptionalTypeSyntax.self)
    }
    
    /// A computed property that returns the full annotation for the type.
    /// - If the type is optional, the annotation is formatted as `Optional<T>` (removing any `?` from the name).
    /// - For non-optional types, the annotation is simply the type name.
    public var annotation: String {
        isOptional ? "Optional<\(name.replacingOccurrences(of: "?", with: ""))>" : name
    }
    
    public var description: String {
        node.trimmedDescription
    }
    
    internal init(node: TypeSyntax) {
        self.node = node
    }
    
    internal init?(node: TypeSyntax?) {
        guard let node = node else { return nil }
        self.node = node
    }
}
