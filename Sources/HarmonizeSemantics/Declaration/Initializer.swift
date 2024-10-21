//
//  Initializer.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import SwiftSyntax

public struct Initializer: Declaration, SyntaxNodeProviding {
    public let node: InitializerDeclSyntax
    
    public let parent: Declaration?
    
    public let sourceCodeLocation: SourceCodeLocation
    
    public var description: String {
        node.trimmedDescription
    }
    
    internal init(
        node: InitializerDeclSyntax,
        parent: Declaration?,
        sourceCodeLocation: SourceCodeLocation
    ) {
        self.node = node
        self.parent = parent
        self.sourceCodeLocation = sourceCodeLocation
    }
}

// MARK: - Capabilities Comformance

extension Initializer: AttributesProviding,
                       BodyProviding,
                       DeclarationsProviding,
                       ModifiersProviding,
                       ParentDeclarationProviding,
                       ParametersProviding,
                       VariablesProviding,
                       FunctionsProviding,
                       SourceCodeProviding,
                       FunctionCallsProviding {
    public var attributes: [Attribute] {
        node.attributes.attributes
    }

    public var body: String? {
        node.body?.statements.toString()
    }
    
    public var modifiers: [Modifier] {
        node.modifiers.modifiers
    }
    
    public var declarations: [Declaration] {
        DeclarationsCache.shared.declarations(from: node)
    }
    
    public var parameters: [Parameter] {
        node.signature.parameterClause.parameters.compactMap {
            Parameter(
                node: $0._syntaxNode,
                parent: self,
                sourceCodeLocation: sourceCodeLocation
            )
        }
    }
    
    public var variables: [Variable] {
        declarations.as(Variable.self)
    }
    
    public var functions: [Function] {
        declarations.as(Function.self)
    }
    
    public var functionCalls: [FunctionCall] {
        declarations.as(FunctionCall.self)
    }
}
