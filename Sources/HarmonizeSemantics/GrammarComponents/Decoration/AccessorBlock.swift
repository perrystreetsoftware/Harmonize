//
//  AccessorBlock.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import SwiftSyntax

/// The representation of a declaration's `get`, `set`, `willSet` or `didSet` accessors.
public struct AccessorBlock: DeclarationDecoration, SyntaxNodeProviding {
    /// The syntax node representing the attribute in the abstract syntax tree (AST).
    public let node: AccessorDeclSyntax
    
    public var modifier: Modifier? {
        Modifier(rawValue: node.accessorSpecifier.text)
    }
    
    public var description: String {
        node.trimmedDescription
    }
    
    internal init(node: AccessorDeclSyntax) {
        self.node = node
    }
    
    internal init?(node: AccessorDeclSyntax?) {
        guard let node = node else { return nil }
        self.node = node
    }
}

// MARK: - Modifier
public extension AccessorBlock {
    enum Modifier: String, CaseIterable, Equatable {
        case get = "get"
        case set = "set"
        case didSet = "didSet"
        case willSet = "willSet"
    }
}

// MARK: - Providers
extension AccessorBlock: BodyProviding {
    public var body: Body? {
        Body(node: node.body?.statements)
    }
}

// MARK: - Accessors Factory

extension AccessorBlock {
    static func accessors(_ node: AccessorBlockSyntax?) -> [AccessorBlock] {
        guard let node = node else { return [] }
        
        return switch node.accessors {
        case .accessors(let accessors):
            accessors.compactMap { AccessorBlock(node: $0) }
        case .getter(_):
            []
        }
    }
}
