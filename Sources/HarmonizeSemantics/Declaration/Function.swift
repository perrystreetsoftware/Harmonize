//
//  Function.swift
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
}
