//
//  Extension.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import SwiftSyntax

public struct Extension: Declaration, SyntaxNodeProviding {
    public let node: ExtensionDeclSyntax
    
    public let parent: Declaration?
    
    public let sourceCodeLocation: SourceCodeLocation
    
    public var description: String {
        node.trimmedDescription
    }
    
    internal init(
        node: ExtensionDeclSyntax,
        parent: Declaration?,
        sourceCodeLocation: SourceCodeLocation
    ) {
        self.node = node
        self.parent = parent
        self.sourceCodeLocation = sourceCodeLocation
    }
}

// MARK: - Capabilities Comformance

extension Extension: AttributesProviding,
                     DeclarationsProviding,
                     InheritanceProviding,
                     ModifiersProviding,
                     ParentDeclarationProviding,
                     ClassesProviding,
                     ProtocolsProviding,
                     EnumsProviding,
                     StructsProviding,
                     VariablesProviding,
                     FunctionsProviding,
                     InitializersProviding,
                     TypeProviding,
                     SourceCodeProviding {
    public var attributes: [Attribute] {
        node.attributes.attributes
    }
    
    public var inheritanceTypesNames: [String] {
        node.inheritanceClause?.toString() ?? []
    }
    
    public var modifiers: [Modifier] {
        node.modifiers.modifiers
    }
    
    public var typeAnnotation: TypeAnnotation? {
        TypeAnnotation(node: node.extendedType)
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
    
    public var variables: [Variable] {
        declarations.as(Variable.self)
    }
    
    public var functions: [Function] {
        declarations.as(Function.self)
    }
    
    public var initializers: [Initializer] {
        declarations.as(Initializer.self)
    }
}
