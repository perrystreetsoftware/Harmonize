//
//  Parameter.swift
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

public struct Parameter: Declaration, SyntaxNodeProviding {
    public let node: Syntax
    
    public let parent: Declaration?
    
    public let sourceCodeLocation: SourceCodeLocation
    
    public var description: String {
        node.trimmedDescription
    }
    
    /// Indicates whether the parameter is variadic, meaning it accepts a variable number of arguments.
    /// A variadic parameter is one that ends with an ellipsis (`...`), allowing the function to accept
    /// multiple value for the parameter.
    ///
    /// - Returns: `true` if the parameter is variadic, allowing multiple arguments; otherwise, `false`.
    public var isVariadic: Bool {
        functionParameter?.ellipsis != nil
    }
    
    internal init?(
        node: Syntax,
        parent: Declaration?,
        sourceCodeLocation: SourceCodeLocation
    ) {
        self.parent = parent
        self.sourceCodeLocation = sourceCodeLocation
        
        if let node = node.as(FunctionParameterSyntax.self) {
            self.node = node._syntaxNode
            return
        }
        
        if let node = node.as(EnumCaseParameterSyntax.self) {
            self.node = node._syntaxNode
            return
        }
        
        return nil
    }
}

// MARK: - Capabilities Comformance

extension Parameter: NamedDeclaration,
                     AttributesProviding,
                     ModifiersProviding,
                     ParentDeclarationProviding,
                     TypeProviding,
                     InitializerClauseProviding,
                     SourceCodeProviding {
    private var functionParameter: FunctionParameterSyntax? {
        node.as(FunctionParameterSyntax.self)
    }
    
    private var enumCaseParameter: EnumCaseParameterSyntax? {
        node.as(EnumCaseParameterSyntax.self)
    }
    
    public var attributes: [Attribute] {
        node.typeAttributes + (functionParameter?.attributes.attributes ?? [])
    }
    
    public var modifiers: [Modifier] {
        functionParameter?.modifiers.modifiers ?? []
    }
    
    public var name: String {
        node.name
    }
    
    public var label: String {
        node.label
    }
    
    public var typeAnnotation: TypeAnnotation? {
        TypeAnnotation(node: functionParameter?.type ?? enumCaseParameter?.type)
    }
    
    public var initializerClause: InitializerClause? {
        let value = functionParameter?.defaultValue ?? enumCaseParameter?.defaultValue
        return value?.initializerClause
    }
}

// MARK: - Generic Syntax Capabilities

fileprivate extension Syntax {
    var name: String {
        guard let node = self.as(FunctionParameterSyntax.self) else { return "" }
        return node.secondName?.text ?? node.firstName.text
    }
    
    var label: String {
        if let node = self.as(FunctionParameterSyntax.self) {
            return node.firstName.text
        }
        
        if let node = self.as(EnumCaseParameterSyntax.self) {
            let label = [node.firstName?.text, node.secondName?.text]
                .compactMap { $0 }
                .joined(separator: " ")
            
            return label
        }
        
        return ""
    }
    
    var typeAttributes: [Attribute] {
        if let node = self.as(FunctionParameterSyntax.self),
           let type = node.type.as(AttributedTypeSyntax.self) {
            return type.attributes.attributes
        }
        
        if let node = self.as(EnumCaseParameterSyntax.self),
           let type = node.type.as(AttributedTypeSyntax.self) {
            return type.attributes.attributes
        }
        
        return []
    }
}
