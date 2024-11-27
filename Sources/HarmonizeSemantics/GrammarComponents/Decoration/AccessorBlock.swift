//
//  AccessorBlock.swift
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
