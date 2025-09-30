//
//  FunctionCall.swift
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

/// A struct that represents a function call in Swift code.
public struct FunctionCall: DeclarationDecoration, SyntaxNodeProviding {
    /// The syntax node representing the function call expression in the abstract syntax tree (AST).
    public let node: FunctionCallExprSyntax
    public let sourceCodeLocation: SourceCodeLocation?

    /// The name of the function or expression being called.
    ///
    /// This property extracts and returns the called expression (e.g., the function name or method) in its trimmed form.
    /// For example, in the function call `print("Hello")`, the `call` is `"print"`.
    public var call: String {
        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self) {
            return memberAccess.declName.baseName.text
        } else if let ref = node.calledExpression.as(DeclReferenceExprSyntax.self) {
            return ref.baseName.text
        }
        
        return node.calledExpression.trimmedDescription
    }
    
    /// Returns all nested inline calls present in this function call, if any.
    ///
    /// Given the following code
    /// ```swift
    /// func function() {
    ///     Call()
    ///         .reference
    ///         .call()
    ///         .reference2
    ///         .call()
    /// }
    /// ```
    ///
    /// This property would return `[Call(), "call", "call"]`.
    public var inlineCalls: [FunctionCall] {
        let calls = internalInlineCalls
        return calls.isEmpty ? [] : calls + [self]
    }
    
    /// Returns all closures present in this function call if it is an inlined function call expression, or its single closure if any.
    /// This will return empty if this function has no trailing closure at all.
    public var inlineClosures: [Closure] {
        (internalInlineCalls.map(\.closure) + [closure]).compactMap { $0 }
    }
    
    /// The name of the function or expression called inlined.
    ///
    /// This property returns the complete call expression trimming arguments, closures body and newlines.
    /// ```swift
    /// func function() {
    ///     firstCall()
    ///     reference.secondCall()
    ///     anotherFunction().filter { $0 > $ 1 }
    ///         .map(\.name)
    ///         .doSomething { }
    /// }
    /// ```
    ///
    /// The resulting `inlineCallExpression` for all three function calls above would:
    ///  - 1. firstCall
    ///  - 2. reference.secondCall
    ///  - 3. anotherFunction.filter.map.doSomething
    public var inlineCallExpression: String {
        tokens.map(\.value).joined(separator: ".")
    }
        
    /// The arguments passed to the function call.
    ///
    /// This property returns an array of ``Argument``, each representing an argument passed to the function.
    /// For example, in `greet(name: "John", age: 30)`, the `arguments` would represent `name: "John"` and `age: 30`.
    /// Each `Argument` consists of an optional label and a value.
    public var arguments: [Argument] {
        node.arguments.map {
            Argument(
                label: $0.label?.text,
                value: $0.expression.trimmedDescription
            )
        }
    }
    
    /// The trailing closure of the function call, if present.
    ///
    /// This property returns an optional ``Closure`` representing the trailing closure attached to the function call.
    /// For example, in:
    ///
    /// ```swift
    /// performTask {
    ///     print("Task is running!")
    /// }
    /// ```
    ///
    /// The `closure` would represent the block of code `{ print("Task is running!") }`.
    /// If no trailing closure is present, this property returns `nil`.
    public var closure: Closure? {
        Closure(node: node.trailingClosure, sourceCodeLocation: sourceCodeLocation)
    }
    
    /// The additional trailing closure of the function call, if any.
    public var additionalClosures: [Closure] {
        node.additionalTrailingClosures.compactMap { Closure(node: $0.closure) }
    }
    
    /// - Returns: if the given function call is a trailing closure.
    public var isClosure: Bool {
        closure != nil
    }
    
    /// - Returns: true if the given function call refers to self.
    public var isSelfReference: Bool {
        node.calledExpression.as(MemberAccessExprSyntax.self)?.base?.trimmedDescription == "self"
    }
    
    /// - Returns: true if the given function call has a closure with self reference.
    public var hasClosureWithSelfReference: Bool {
        let hasSelfRefInClosure = closure?.hasSelfReference ?? false
        let hasSelfRefInAdditionalClosure = additionalClosures.contains(where: \.hasSelfReference)
        let hasSelfRefInInlineCalls = internalInlineCalls.contains(where: \.hasClosureWithSelfReference)
        return hasSelfRefInClosure || hasSelfRefInAdditionalClosure || hasSelfRefInInlineCalls
    }
    
    public var tokens: [Token] {
        return node.tokens(viewMode: .all)
            .compactMap { token in
                if case .identifier(let identifier) = token.tokenKind {
                    return Token(value: identifier,
                                 position: token.position.utf8Offset)
                }
                return nil
            }
    }

    public func tokens(startingWith: String) -> [Token] {
        return node.tokens(viewMode: .all)
            .compactMap { token in
                if case .identifier(let identifier) = token.tokenKind,
                   identifier.starts(with: startingWith) {
                    return Token(value: identifier,
                                 position: token.position.utf8Offset)
                }
                return nil
            }
    }

    public var description: String {
        node.trimmedDescription
    }
    
    internal init(node: FunctionCallExprSyntax, sourceCodeLocation: SourceCodeLocation? = nil) {
        self.node = node
        self.sourceCodeLocation = sourceCodeLocation
    }
    
    private var internalInlineCalls: [FunctionCall] {
        FunctionCall.parseInline(node: node)
    }
}

// MARK: - Call, Argument, Token

public extension FunctionCall {
    /// A struct representing a single argument in a function call.
    ///
    /// Each argument consists of an optional label and the value being passed.
    /// For example, in the function call `greet(name: "John")`, the `label` is `name` and the `value` is `"John"`.
    struct Argument {
        /// The label of the argument, if available.
        ///
        /// This is the label specified in the function call (e.g., `name` in `greet(name: "John")`).
        /// If the argument has no label, this property is `nil`.
        public let label: String?
        
        /// The value of the argument as a `String`.
        ///
        /// This represents the value being passed to the function. For example, in `greet(name: "John")`,
        /// the `value` would be `"John"`.
        public let value: String
    }

    /// A struct representing a single token that may be composing a function call.
    ///
    /// For example, in the function call `greet().$someObj.flatMap { }.`, we have two tokens: `$someObjc` and `.flatMap`
    /// We still need to extend this in the future so that it is fully typed since a Token can be another FunctionCall or a reference and so on.
    struct Token: Equatable {
        /// The value of the token as a `String`.
        ///
        /// For example, `$publishedValue` or `.flatMap`
        public let value: String

        // Where in the source this token exists
        public let position: Int
    }
}

// MARK: Capabilities Comformance

extension FunctionCall: FunctionCallsProviding {
    /// An array of function calls present in this function call if it has a trailing closure.
    public var functionCalls: [FunctionCall] {
        closure?.functionCalls ?? []
    }
    
    private static func parseInline(node: FunctionCallExprSyntax) -> [FunctionCall] {
        var results: [FunctionCall] = []
        
        func traverse(node: ExprSyntax?) {
            guard let node = node else { return }
                
            if let funcCall = node.as(FunctionCallExprSyntax.self) {
                results.append(FunctionCall(node: funcCall))
                traverse(node: funcCall.calledExpression)
            } else if let memberAccessExpr = node.as(MemberAccessExprSyntax.self) {
                traverse(node: memberAccessExpr.base)
            }
        }
        
        traverse(node: node.calledExpression)
        return results.reversed()
    }
}
