//
//  Variable.swift
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

public struct Variable: Declaration, SyntaxNodeProviding {
    private let parentNode: VariableDeclSyntax
    
    public let node: PatternBindingSyntax
    
    public let parent: Declaration?
    
    public let sourceCodeLocation: SourceCodeLocation
    
    public var description: String {
        node.trimmedDescription
    }
    
    public var isOptional: Bool {
        typeAnnotation?.isOptional == true
    }
    
    public var isConstant: Bool {
        parentNode.bindingSpecifier.text == "let"
    }
    
    public var isVariable: Bool {
        !isConstant
    }
    
    public var isOfInferredType: Bool {
        typeAnnotation == nil
    }
    
    public var isComputed: Bool {
        getter != nil
    }
    
    public var isStored: Bool {
        !isComputed
    }
    
    internal init(
        parentNode: VariableDeclSyntax,
        node: PatternBindingSyntax,
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

extension Variable: NamedDeclaration,
                    AttributesProviding,
                    ModifiersProviding,
                    ParentDeclarationProviding,
                    AccessorBlocksProviding,
                    TypeProviding,
                    InitializerClauseProviding,
                    SourceCodeProviding {
    public var attributes: [Attribute] {
        parentNode.attributes.attributes
    }
    
    public var modifiers: [Modifier] {
        parentNode.modifiers.modifiers
    }
    
    public var name: String {
        node.pattern.trimmedDescription
    }
        
    public var typeAnnotation: TypeAnnotation? {
        let node = node.typeAnnotation?.type ?? parentNode.bindings.compactMap { $0.typeAnnotation?.type }.first
        return TypeAnnotation(node: node)
    }
    
    public var initializerClause: InitializerClause? {
        node.initializer?.initializerClause
    }
    
    public var accessors: [AccessorBlock] {
        AccessorBlock.accessors(node.accessorBlock)
    }
    
    public var getter: GetterBlock? {
        GetterBlock.getter(node.accessorBlock)
    }
}

// MARK: - Variables Factory

extension Variable {
    static func variables(
        from node: VariableDeclSyntax,
        parent: Declaration?,
        sourceCodeLocation: SourceCodeLocation
    ) -> [Variable] {
        node.bindings.compactMap {
            Variable(
                parentNode: node,
                node: $0,
                parent: parent,
                sourceCodeLocation: sourceCodeLocation
            )
        }
    }
}
