//
//  AccessorBlock.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import SwiftSyntax

/// The representation of a computed-property getter block.
public struct GetterBlock: DeclarationDecoration, SyntaxNodeProviding {
    /// The syntax node representing the getter block from a computed-property in the abstract syntax tree (AST).
    public let node: CodeBlockItemListSyntax
    
    public var description: String {
        node.trimmedDescription
    }
    
    init(node: CodeBlockItemListSyntax) {
        self.node = node
    }
    
    init?(node: CodeBlockItemListSyntax?) {
        guard let node = node else { return nil }
        self.node = node
    }
}

// MARK: - BodyProviding Comformance

extension GetterBlock: BodyProviding {
    public var body: Body? {
        Body(node: node)
    }
}

// MARK: - Factory

extension GetterBlock {
    static func getter(_ node: AccessorBlockSyntax?) -> GetterBlock? {
        guard let node = node else { return nil }
        
        return switch node.accessors {
        case .accessors(_):
            nil
        case .getter(let block):
            Self(node: block)
        }
    }
}
