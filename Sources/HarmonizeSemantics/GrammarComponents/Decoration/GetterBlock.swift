//
//  GetterBlock.swift
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
