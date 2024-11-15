//
//  FunctionCall.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import SwiftSyntax

/// A struct that represents a function call in Swift code.
public struct FunctionCall: Declaration, SyntaxNodeProviding {
    /// The syntax node representing the function call expression in the abstract syntax tree (AST).
    public let node: FunctionCallExprSyntax
    
    public let parent: Declaration?
    
    public let sourceCodeLocation: SourceCodeLocation
    
    /// The name of the function or expression being called.
    ///
    /// This property extracts and returns the called expression (e.g., the function name or method) in its trimmed form.
    /// For example, in the function call `print("Hello")`, the `call` is `"print"`.
    public var call: String {
        node.calledExpression.trimmedDescription
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
    
    internal init(
        node: FunctionCallExprSyntax,
        parent: Declaration?,
        sourceCodeLocation: SourceCodeLocation
    ) {
        self.node = node
        self.parent = parent
        self.sourceCodeLocation = sourceCodeLocation
    }
}

// MARK: - Argument

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

extension FunctionCall: DeclarationsProviding,
                        FunctionCallsProviding,
                        ParentDeclarationProviding,
                        SourceCodeProviding {
    public var declarations: [Declaration] {
        DeclarationsCache.shared.declarations(from: node)
    }
    
    public var functionCalls: [FunctionCall] {
        declarations.as(FunctionCall.self)
    }
}
