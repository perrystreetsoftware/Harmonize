//
//  Switch.swift
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

/// A struct representing a `switch` expression in Swift code.
///
/// The `Switch` struct encapsulates the syntax node of a `switch` expression (`SwitchExprSyntax`)
/// and provides an API to access its description, cases, and related metadata.
public struct Switch: DeclarationDecoration, SyntaxNodeProviding {
    /// The syntax node representing the `switch` expression in the abstract syntax tree (AST).
    public let node: SwitchExprSyntax

    /// A description of the `switch` expression, trimmed of leading/trailing whitespace.
    ///
    /// For example:
    /// ```swift
    /// switch value {
    /// case 1: print("One")
    /// default: break
    /// }
    /// ```
    /// The description would be `"switch value { case 1: print(\"One\"); default: break }"`.
    public var description: String {
        node.trimmedDescription
    }
    
    /// An array of cases present in the `switch` expression.
    ///
    /// Each case is represented by the `Switch.Case` struct, which provides details
    /// such as the pattern, attribute, and body.
    ///
    /// Conditional compilation blocks (`#if`) are currently unsupported and will be ignored.
    public var cases: [Case] {
        node.cases.compactMap { $0.as(SwitchCaseSyntax.self) }
            .map(Case.init(node:))
    }
    
    internal init(node: SwitchExprSyntax) {
        self.node = node
    }
    
    internal init?(node: SwitchExprSyntax?) {
        guard let node else { return nil }
        self.node = node
    }
}

// MARK: Case

extension Switch {
    /// A struct representing a single case in a `switch` expression.
    ///
    /// The `Switch.Case` struct provides access to details about a case, such as its pattern,
    /// optional attribute, and body of statements.
    public struct Case: DeclarationDecoration, SyntaxNodeProviding {
        /// The syntax node representing the case in the abstract syntax tree (AST).
        public let node: SwitchCaseSyntax
        
        /// A description of the case, trimmed of leading/trailing whitespace.
        ///
        /// For example:
        /// ```swift
        /// case .one: print("One")
        /// ```
        /// The description would be `"case .one: print(\"One\")"`.
        public var description: String {
            node.trimmedDescription
        }
        
        /// An optional attribute associated with the case, such as `@unknown`.
        public var attribute: Attribute? {
            Attribute(node: node.attribute)
        }
        
        /// Indicates whether the case is a `default` case.
        public var isDefault: Bool {
            return if case .default(_) = node.label {
                true
            } else {
                false
            }
        }
        
        public init(node: SwitchCaseSyntax) {
            self.node = node
        }
    }
}

// MARK: Switch.Case + BodyProviding

extension Switch.Case: BodyProviding {
    public var body: Body? {
        Body(node: node.statements)
    }
}

// MARK: Switch.Case + Item

extension Switch.Case {
    /// An enumeration representing the different patterns that can be used in a `switch` case.
    /// Each pattern corresponds to a specific type of case item in the `switch` expression.
    public enum Item: Equatable {
        /// A case with a literal expression, such as `case 1`.
        case literalExpression(String)
                
        /// A case with a named member, such as `case .one`.
        case namedMember(String)
        
        /// A case with a type check, such as `case is String`.
        case isType(String)
        
        /// A value-binding case with a single member, such as `case let .one(x)`.
        case valueBindingWithMember(keyword: String, name: String, elements: [String])
        
        /// A nested value-binding case, such as `case let (x, y)` with detailed bindings.
        case nestedValueBinding(name: String, elements: [String: String])
        
        /// A value-binding case with multiple elements, such as `case let (x, y)`.
        case valueBinding(keyword: String, elements: [String])
        
        /// A case with a tuple pattern, such as `case (x, y)`.
        case tuplePattern(elements: [String])
        
        /// A case with an unsupported pattern.
        case unsupportedPattern(SwitchCaseItemSyntax)
        
        // MARK: Initializer
        
        public init(node: SwitchCaseItemSyntax) {
            let pattern = node.pattern
            
            if let expressionPattern = pattern.as(ExpressionPatternSyntax.self) {
                    self = .literalExpression(expressionPattern.description)
            } else if let identifierPattern = pattern.as(IdentifierPatternSyntax.self) {
                self = .namedMember(identifierPattern.identifier.text)
            } else if let isTypePattern = pattern.as(IsTypePatternSyntax.self) {
                self = .isType(isTypePattern.type.description)
            } else if let valueBindingPattern = pattern.as(ValueBindingPatternSyntax.self) {
                let keyword = valueBindingPattern.bindingSpecifier.text
                if let identifierPattern = valueBindingPattern.pattern.as(IdentifierPatternSyntax.self) {
                    self = .valueBindingWithMember(
                        keyword: keyword,
                        name: identifierPattern.identifier.text,
                        elements: []
                    )
                } else if let tuplePattern = valueBindingPattern.pattern.as(TuplePatternSyntax.self) {
                    let elements = tuplePattern.elements.map(\.pattern.trimmedDescription)
                    self = .valueBinding(keyword: keyword, elements: elements)
                } else {
                    self = .unsupportedPattern(node)
                }
            } else if let tuplePattern = pattern.as(TuplePatternSyntax.self) {
                let elements = tuplePattern.elements.map(\.trimmedDescription)
                self = .tuplePattern(elements: elements)
            } else {
                self = .unsupportedPattern(node)
            }
        }
    }
}
