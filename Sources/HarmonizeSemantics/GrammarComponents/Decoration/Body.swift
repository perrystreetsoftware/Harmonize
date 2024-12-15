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

    /// An array of `Assignment` objects representing all assignments in the body of the declaration.
    public let assignments: [Assignment]
    
    /// An array of `FunctionCall` objects representing all the top-level function call present in the body.
    /// e.g `someFunc()` is included but `value = getValue()` is part of Assignment. We don't include nested calls for now.
    public let functionCalls: [FunctionCall]
    
    /// An array of `If` objects representing all the if-conditions present in the body.
    public let ifs: [If]
    
    /// An array of raw statement type representing the body, with each corresponding to a statement
    /// in the body. Each statement is trimmed of leading/trailing whitespace.
    public let statements: [Statement]
    
    /// An array of `Switch` all the switch statements present in the body.
    public let switches: [Switch]
    
    public var description: String {
        node.trimmedDescription
    }

    internal init(node: CodeBlockItemListSyntax) {
        self.node = node
        
        var assignments: [Assignment] = []
        var functionCalls: [FunctionCall] = []
        var ifs: [If] = []
        var switches: [Switch] = []
        var statements: [Statement] = []
        
        for child in node {
            if let infixOperator = child.item.as(InfixOperatorExprSyntax.self) {
                assignments.append(Assignment(node: infixOperator))
                continue
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
            
            if let functionCallNode = child.item.as(FunctionCallExprSyntax.self) {
                functionCalls.append(FunctionCall(node: functionCallNode))
                continue
            }
            
            statements.append(Statement(node: child))
        }
        
        self.assignments = assignments
        self.functionCalls = functionCalls
        self.ifs = ifs
        self.switches = switches
        self.statements = statements
    }

    internal init?(node: CodeBlockItemListSyntax?) {
        guard let node = node else { return nil }
        self.init(node: node)
    }
}
