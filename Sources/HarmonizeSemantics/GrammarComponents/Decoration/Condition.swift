//
//  Condition.swift
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

/// A struct that represents a `condition` statement in Swift code, usually present in `if`,  `guard` etc.
/// This might not support all possible condition statement and if it doesn't it will fallback to `.asString` value.
public struct Condition: DeclarationDecoration, SyntaxNodeProviding {
    public let node: ConditionElementSyntax
    
    /// An typed enum with all the possible condition statement expression types.
    public var value: Value {
        return if let optionalBinding = node.condition.as(OptionalBindingConditionSyntax.self) {
            .optionalBinding(.init(node: optionalBinding))
        } else if let comparison = node.condition.as(InfixOperatorExprSyntax.self) {
            .comparison(.init(node: comparison))
        } else if let booleanExpression = node.condition.as(MemberAccessExprSyntax.self) {
            .booleanExpression(booleanExpression.trimmedDescription)
        } else if let operatorBoolExpression = node.condition.as(PrefixOperatorExprSyntax.self) {
            .booleanExpression(operatorBoolExpression.trimmedDescription)
        } else {
            .asString(node.condition.description)
        }
    }
    
    /// An optional value that returns non nil if this condition is a optional binding statement.
    ///
    /// - Returns: The value in cases like `if let..` or `guard let...`. Nil otherwise.
    public var asOptionalBinding: OptionalBinding? {
        return if case .optionalBinding(let optionalBinding) = value {
            optionalBinding
        } else {
            nil
        }
    }
    
    /// An optional value that returns non nil if this condition is a comparison between a left and right operand.
    ///
    /// - Returns: The value in cases like `a > b`. Nil otherwise.
    public var asComparison: InfixExpression? {
        return if case .comparison(let infixExpression) = value {
            infixExpression
        } else {
            nil
        }
    }
    
    /// - Returns: The raw value as a string.
    public var asString: String {
        return switch value {
        case let .asString(string):
            string
        case let .booleanExpression(string):
            string
        case let .comparison(comparison):
            comparison.description
        case let .optionalBinding(binding):
            binding.description
        }
    }
    
    /// A boolean flag that indicates if this condition is an optional binding and the binding target is self.
    public var isBindingToSelf: Bool {
        return asOptionalBinding?.isBindingSelf ?? false
    }
    
    /// A boolean flag that indicates if this condition is an optional binding.
    public var isOptionalBinding: Bool {
        switch value {
        case .optionalBinding(_):
            true
        default:
            false
        }
    }
    
    /// A boolean flag that indicates if this condition is a boolean expression.
    public var isBooleanExpression: Bool {
        switch value {
        case .booleanExpression(_):
            true
        default:
            false
        }
    }
    
    /// A boolean flag that indicates if this condition is a comparison.
    public var isComparison: Bool {
        switch value {
        case .comparison(_):
            true
        default:
            false
        }
    }
    
    public var description: String {
        node.trimmedDescription
    }
    
    init(node: ConditionElementSyntax) {
        self.node = node
    }
}

// MARK: Condition + Value, OptionalBinding

extension Condition {
    /// A struct representing the possible cases for a condition.
    public enum Value {
        case optionalBinding(OptionalBinding)
        case comparison(InfixExpression)
        case booleanExpression(String)
        case asString(String)
    }
    
    /// A struct representing an optional binding condition in a Swift declaration.
    ///
    /// This struct is designed to capture the details of an optional binding condition, such as the type of binding (`let`, `var`, `inout`),
    /// the associated type annotation, and whether the binding references `self`.
    public struct OptionalBinding: DeclarationDecoration, SyntaxNodeProviding {
        /// The syntax node representing the optional binding condition in the abstract syntax tree (AST).
        public let node: OptionalBindingConditionSyntax
        
        public var description: String {
            node.trimmedDescription
        }
        
        /// The name of the binding variable.
        ///
        /// This property extracts the name of the variable being bound in the optional binding, such as `"abc"` in `guard let abc = ...`.
        public var name: String {
            if let identifier = node.pattern.as(IdentifierPatternSyntax.self) {
                return identifier.identifier.text
            }
            
            return node.pattern.trimmedDescription
        }
        
        /// A boolean indicating whether the binding is a `let` binding.
        ///
        /// This property returns `true` if the optional binding uses the `let` keyword, as in `guard let abc = someValue`.
        public var isLet: Bool {
            node.bindingSpecifier.tokenKind == .keyword(.let)
        }
        
        /// A boolean indicating whether the binding is a `var` binding.
        ///
        /// This property returns `true` if the optional binding uses the `var` keyword, as in `guard var abc = someValue`.
        public var isVar: Bool {
            node.bindingSpecifier.tokenKind == .keyword(.var)
        }
        
        /// A boolean indicating whether the binding is an `inout` binding.
        ///
        /// This property returns `true` if the optional binding uses the `inout` keyword, as in `guard let abc = &someValue`.
        public var isInOut: Bool {
            node.bindingSpecifier.tokenKind == .keyword(.inout)
        }
        
        /// A boolean indicating if the optional binding contains a self-binding reference.
        ///
        /// This property returns `true` if the left or right operand of the binding is a reference to `self`,
        /// which is common in patterns like `guard let self = self` or `guard let abc = self`.
        ///
        /// - Returns: `true` if the left or right operand is `self`, `false` otherwise.
        public var isBindingSelf: Bool {
            node.pattern.as(IdentifierPatternSyntax.self)?.identifier.tokenKind == .keyword(.`self`) || initializerClause?.isSelfReference == true
        }
        
        /// Initializes a new `OptionalBinding` from the given syntax node.
        ///
        /// This initializer creates an `OptionalBinding` instance from an `OptionalBindingConditionSyntax` node.
        ///
        /// - Parameter node: The syntax node representing the optional binding condition.
        /// - Returns: A new instance of `OptionalBinding` initialized with the given node.
        public init(node: OptionalBindingConditionSyntax) {
            self.node = node
        }
    }
}

// MARK: Condition.OptionalBinding + Providers Comformance

extension Condition.OptionalBinding: TypeProviding, InitializerClauseProviding {
    /// The type annotation associated with the optional binding, if any.
    public var typeAnnotation: TypeAnnotation? {
        TypeAnnotation(node: node.typeAnnotation?.type)
    }
    
    /// The initializer clause associated with the optional binding, if any.
    ///
    /// This property returns an `InitializerClause` that represents the initializer part of the binding, such as the right-hand side
    /// expression in `guard let abc = someValue`.
    public var initializerClause: InitializerClause? {
        InitializerClause(node: node.initializer)
    }
}
