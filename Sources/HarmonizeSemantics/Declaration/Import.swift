//
//  Import.swift
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

public struct Import: Declaration, SyntaxNodeProviding {
    public let node: ImportDeclSyntax
    
    public let sourceCodeLocation: SourceCodeLocation
    
    public var description: String {
        node.trimmedDescription
    }
    
    internal init(
        node: ImportDeclSyntax,
        sourceCodeLocation: SourceCodeLocation
    ) {
        self.node = node
        self.sourceCodeLocation = sourceCodeLocation
    }
}

// MARK: - ImportKind

public extension Import {
    enum ImportKind: String {
        case `typealias`, `struct`, `class`, `enum`, `protocol`, `let`, `var`, `func`
    }
}

// MARK: - Capabilities Comformance

extension Import: NamedDeclaration,
                  AttributesProviding,
                  SourceCodeProviding {
    public var attributes: [Attribute] {
        node.attributes.attributes
    }
    
    public var name: String {
        node.path.map { $0.name.text }.joined(separator: ".")
    }
    
    public var kind: ImportKind? {
        ImportKind(rawValue: node.importKindSpecifier?.text ?? "")
    }
}
