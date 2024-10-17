//
//  Class.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import SwiftSyntax

public struct Class: Declaration, SyntaxNodeProviding {
    public let node: ClassDeclSyntax
    
    public let parent: Declaration?
    
    public let sourceCodeLocation: SourceCodeLocation
    
    public var description: String {
        node.trimmedDescription
    }
    
    internal init(
        node: ClassDeclSyntax,
        parent: Declaration?,
        sourceCodeLocation: SourceCodeLocation
    ) {
        self.node = node
        self.parent = parent
        self.sourceCodeLocation = sourceCodeLocation
    }
}

// MARK: - Capabilities Comformance

extension Class: NamedDeclaration,
                 AttributesProviding,
                 ClassesProviding,
                 DeclarationsProviding,
                 EnumsProviding,
                 FunctionsProviding,
                 InitializersProviding,
                 InheritanceProviding,
                 ModifiersProviding,
                 ParentDeclarationProviding,
                 ProtocolsProviding,
                 StructsProviding,
                 VariablesProviding,
                 SourceCodeProviding {
    public var attributes: [Attribute] {
        node.attributes.attributes
    }
    
    public var declarations: [Declaration] {
        DeclarationsCache.shared.declarations(from: node)
    }
    
    public var inheritanceTypesNames: [String] {
        node.inheritanceClause?.toString() ?? []
    }
    
    public var modifiers: [Modifier] {
        node.modifiers.modifiers
    }
    
    public var name: String {
        node.name.text
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