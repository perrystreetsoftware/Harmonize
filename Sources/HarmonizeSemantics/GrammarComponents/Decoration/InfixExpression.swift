//
//  InfixExpression.swift
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

/// Represents an infix expression in Swift syntax (e.g., `a = b`).
public struct InfixExpression: DeclarationDecoration, SyntaxNodeProviding {
    /// The underlying syntax node for the assignment expression.
    public let node: InfixOperatorExprSyntax
    
    /// The target of the assignment expression (the left operand).
    public var leftOperand: String {
        node.leftOperand.trimmedDescription
    }
    
    public var `operator`: String {
        node.operator.trimmedDescription
    }
    
    /// the assignment value after `=` (the right operand)
    public var rightOperand: RightOperand {
        if let functionCallNode = node.rightOperand.as(FunctionCallExprSyntax.self) {
            return .functionCall(FunctionCall(node: functionCallNode))
        }
        
        if let ref = node.rightOperand.as(DeclReferenceExprSyntax.self) {
            let args = ref.argumentNames?.arguments.map(\.name.text) ?? []
            return .reference(name: ref.baseName.text, arguments: args)
        }
        
        if let stringLiteral = node.rightOperand.as(StringLiteralExprSyntax.self) {
            return .literalStringValue(stringLiteral.segments.trimmedDescription)
        }
        
        if let intLiteral = node.rightOperand.as(IntegerLiteralExprSyntax.self) {
            return .literalIntValueText(intLiteral.literal.text)
        }
        
        if let closureNode = node.rightOperand.as(ClosureExprSyntax.self) {
            return .closure(Closure(node: closureNode))
        }
        
        if let IfNode = node.rightOperand.as(IfExprSyntax.self) {
            return .ifCondition(If(node: IfNode))
        }
        
        return .unsupported(node.rightOperand.trimmedDescription)
    }
    
    public var isAssignment: Bool {
        `operator` == "="
    }
    
    public var description: String {
        node.trimmedDescription
    }
    
    internal init(node: InfixOperatorExprSyntax) {
        self.node = node
    }
}

// MARK: InfixExpression + Operands

extension InfixExpression {
    public enum RightOperand {
        case reference(name: String, arguments: [String])
        case literalStringValue(String)
        case literalIntValueText(String)
        case functionCall(FunctionCall)
        case closure(Closure)
        case ifCondition(If)
        case unsupported(String)
    }
}
