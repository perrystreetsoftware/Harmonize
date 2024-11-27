//
//  EnumCase.swift
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

public struct EnumCase: Declaration, SyntaxNodeProviding {
    internal let parentNode: EnumCaseDeclSyntax
    
    public let node: EnumCaseElementSyntax
    
    public let parent: Declaration?
    
    public let sourceCodeLocation: SourceCodeLocation
    
    public var description: String {
        node.trimmedDescription
    }
    
    internal init(
        parentNode: EnumCaseDeclSyntax,
        node: EnumCaseElementSyntax,
        parent: Declaration?,
        sourceCodeLocation: SourceCodeLocation
    ) {
        self.parentNode = parentNode
        self.node = node
        self.parent = parent
        self.sourceCodeLocation = sourceCodeLocation
    }
}

// MARK: - Capabilities Comformance

extension EnumCase: NamedDeclaration,
                    AttributesProviding,
                    ModifiersProviding,
                    ParentDeclarationProviding,
                    InitializerClauseProviding,
                    ParametersProviding,
                    SourceCodeProviding {
    public var attributes: [Attribute] {
        parentNode.attributes.attributes
    }
    
    public var modifiers: [Modifier] {
        parentNode.modifiers.modifiers
    }
    
    public var name: String {
        node.name.text
    }
    
    public var initializerClause: InitializerClause? {
        node.rawValue?.initializerClause
    }
    
    public var parameters: [Parameter] {
        node.parameterClause?.parameters.compactMap {
            Parameter(
                node: $0._syntaxNode,
                parent: parent,
                sourceCodeLocation: sourceCodeLocation
            )
        } ?? []
    }
}

// MARK: - EnumCase Factory

extension EnumCase {
    static func cases(
        from node: EnumCaseDeclSyntax,
        parent: Declaration?,
        sourceCodeLocation: SourceCodeLocation
    ) -> [EnumCase] {
        node.elements.compactMap {
            Self(
                parentNode: node,
                node: $0,
                parent: parent,
                sourceCodeLocation: sourceCodeLocation
            )
        }
    }
}
