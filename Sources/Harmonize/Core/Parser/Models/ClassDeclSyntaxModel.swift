//
//  ClassDeclSyntaxModel.swift
//
//
//  Created by Lucas Cavalcante on 8/31/24.
//

import Foundation
import SwiftSyntax

struct ClassDeclSyntaxModel: Class {
    var name: String
    
    var text: String
    
    var parent: Declaration? = nil
    
    var children: [Declaration] = []
    
    var swiftFile: SwiftFile
    
    var inheritanceTypesNames: [String]
    
    var attributes: [Attribute]
    
    var properties: [Property] {
        children.as(Property.self)
    }
    
    var functions: [Function] {
        children.as(Function.self)
    }

    var initializers: [Initializer] {
        children.as(Initializer.self)
    }
    
    init(node: ClassDeclSyntax, file: SwiftFile) {
        self.name = node.name.text
        self.text = node.trimmedDescription
        self.swiftFile = file
        self.inheritanceTypesNames = node.inheritanceClause?.typesAsString() ?? []
        self.attributes = node.attributes.attributes
    }
}