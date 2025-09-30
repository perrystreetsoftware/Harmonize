//
//  Initializer.swift
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
                       SourceCodeProviding {
    public var attributes: [Attribute] {
        node.attributes.attributes
    }

    public var body: Body? {
        Body(node: node.body?.statements, sourceCodeLocation: sourceCodeLocation)
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
}
