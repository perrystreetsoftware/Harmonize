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

    /// An array of ``InfixExpression`` representing all infix expression in this body.
    /// An infix expression is commonly represented by a left operand, an operator and a right operand such as `a = b`.
    public let infixExpressions: [InfixExpression]

    public let variables: [Variable]

    /// An array of ``FunctionCall`` objects representing all the top-level function call present in the body.
    /// e.g `someFunc()` is included but `value = getValue()` is part of Assignment. We don't include nested calls for now.
    public let functionCalls: [FunctionCall]
    
    /// An array of ``If`` objects representing all the if-conditions present in the body.
    public let ifs: [If]
    
    /// An array of raw statement type representing the body, with each corresponding to a statement
    /// in the body. Each statement is trimmed of leading/trailing whitespace.
    public let statements: [Statement]
    
    /// An array of ``Switch`` all the switch statements present in the body.
    public let switches: [Switch]
    
    /// An array of ``Guard`` representing all guard statements in this body.
    public let guards: [Guard]
    
    public var description: String {
        node.trimmedDescription
    }
    
    /// An array of ``Closure`` present in this array recursively parsed from its ``FunctionCall``, if any.
    public var closures: [Closure] {
        functionCalls.flatMap(\.inlineClosures)
    }
    
    /// A boolean flag that indicates if self is used in any statement in this body.
    
    /// This doesn't necessarily means that this body is leaking self since
    /// it can be a function's body with a self reference to call another function.
    ///
    /// `hasAnyClosureWithSelfReference` is a proper method to use for this purpose.
    public var hasAnySelfReference: Bool {
        node.tokens(viewMode: .all).contains(where: { $0.tokenKind == .keyword(.`self`) })
    }
    
    /// A boolean flag that indicates if self is used in any closures within this body.
    public var hasAnyClosureWithSelfReference: Bool {
        functionCalls.contains { $0.hasClosureWithSelfReference }
    }

    internal init(node: CodeBlockItemListSyntax, sourceCodeLocation: SourceCodeLocation?) {
        self.node = node
        
        var infixExpressions: [InfixExpression] = []
        var functionCalls: [FunctionCall] = []
        var ifs: [If] = []
        var switches: [Switch] = []
        var guards: [Guard] = []
        var statements: [Statement] = []
        var variables: [Variable] = []

        for child in node {
            statements.append(Statement(node: child))

            if let infixOperator = child.item.as(InfixOperatorExprSyntax.self) {
                infixExpressions.append(InfixExpression(node: infixOperator))
                continue
            }

            if let sourceCodeLocation,
                let variableDeclaration = child.item.as(VariableDeclSyntax.self) {
                variables.append(
                    contentsOf: variableDeclaration.bindings.map {
                        return Variable(
                            parentNode: variableDeclaration,
                            node: $0,
                            parent: nil,
                            sourceCodeLocation: sourceCodeLocation
                        )
                    }
                )
            }

            if let expressionStatement = child.item.as(ExpressionStmtSyntax.self) {
                if let ifNode = expressionStatement.expression.as(IfExprSyntax.self) {
                    ifs.append(If(node: ifNode))
                    continue
                }
                
                if let switchNode = expressionStatement.expression.as(SwitchExprSyntax.self) {
                    switches.append(Switch(node: switchNode))
                    continue
                }
            }
            
            if let guardNode = child.item.as(GuardStmtSyntax.self) {
                guards.append(Guard(node: guardNode))
                continue
            }
            
            if let functionCallNode = child.item.as(FunctionCallExprSyntax.self) {
                functionCalls.append(FunctionCall(node: functionCallNode, sourceCodeLocation: sourceCodeLocation))
                continue
            }
        }
        
        self.infixExpressions = infixExpressions
        self.functionCalls = functionCalls
        self.ifs = ifs
        self.switches = switches
        self.guards = guards
        self.statements = statements
        self.variables = variables
    }

    internal init?(node: CodeBlockItemListSyntax?, sourceCodeLocation: SourceCodeLocation? = nil) {
        guard let node = node else { return nil }
        self.init(node: node, sourceCodeLocation: sourceCodeLocation)
    }
}
