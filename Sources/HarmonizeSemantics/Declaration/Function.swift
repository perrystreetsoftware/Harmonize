//
//  Function.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import SwiftSyntax

public struct Function: Declaration, SyntaxNodeProviding {
    public let node: FunctionDeclSyntax
    
    public let parent: Declaration?
    
    public let sourceCodeLocation: SourceCodeLocation
    
    public var description: String {
        node.trimmedDescription
    }
    
    public var returnClause: ReturnClause? {
        ReturnClause(node: node.signature.returnClause)
    }
    
    public var genericClause: String? {
        node.genericParameterClause?.trimmedDescription
    }
    
    public var whereClause: String? {
        node.genericWhereClause?.trimmedDescription
    }
    
    internal init(
        node: FunctionDeclSyntax,
        parent: Declaration?,
        sourceCodeLocation: SourceCodeLocation
    ) {
        self.node = node
        self.parent = parent
        self.sourceCodeLocation = sourceCodeLocation
    }
}

// MARK: - Capabilities Comformance

extension Function: NamedDeclaration,
                    AttributesProviding,
                    DeclarationsProviding,
                    ModifiersProviding,
                    ParentDeclarationProviding,
                    ClassesProviding,
                    ProtocolsProviding,
                    EnumsProviding,
                    StructsProviding,
                    BodyProviding,
                    ParametersProviding,
                    FunctionsProviding,
                    FunctionCallsProviding,
                    SourceCodeProviding {
    public var attributes: [Attribute] {
        node.attributes.attributes
    }
    
    public var modifiers: [Modifier] {
        node.modifiers.modifiers
    }
    
    public var name: String {
        node.name.text
    }
    
    public var declarations: [Declaration] {
        DeclarationsCache.shared.declarations(from: node)
    }
    
    public var classes: [Class] {
        declarations.as(Class.self)
    }
    
    public var enums: [Enum] {
        declarations.as(Enum.self)
    }
    
    public var structs: [Struct] {
        declarations.as(Struct.self)
    }
    
    public var protocols: [ProtocolDeclaration] {
        declarations.as(ProtocolDeclaration.self)
    }
    
    public var functions: [Function] {
        declarations.as(Function.self)
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
    
    public var body: Body? {
        Body(node: node.body?.statements)
    }

    public var functionCalls: [FunctionCall] {
        declarations.as(FunctionCall.self)
    }
}
