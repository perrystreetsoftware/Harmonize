//
//  Initializer.swift
//
//
//  Created by Lucas Cavalcante on 8/28/24.
//

import Foundation

public struct Initializer: Declaration,
                           ParentDeclarationProviding,
                           ChildrenDeclarationProviding,
                           BodyProviding,
                           ModifiersProviding,
                           AttributesProviding,
                           ParametersProviding,
                           FunctionsProviding,
                           PropertiesProviding {
    public var text: String
    
    public var parent: Declaration? = nil
    
    public var children: [Declaration] = []
    
    public var swiftFile: SwiftFile
        
    public var body: String?
    
    public var attributes: [Attribute]
    
    public var modifiers: [Modifier]
    
    public var parameters: [Parameter] {
        children.as(Parameter.self)
    }
    
    public var properties: [Property] {
        children.as(Property.self)
    }
    
    public var functions: [Function] {
        children.as(Function.self)
    }
}
