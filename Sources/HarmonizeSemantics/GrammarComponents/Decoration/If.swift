//
//  If.swift
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

public struct If: DeclarationDecoration, SyntaxNodeProviding {
    public let node: IfExprSyntax

    public var description: String {
        node.trimmedDescription
    }
    
    public var conditions: [String] {
        node.conditions.map(\.trimmedDescription)
    }
    
    public var elseIf: If? {
        Self(node: node.elseBody?.as(IfExprSyntax.self))
    }
    
    public var elseBody: Body? {
        Body(node: node.elseBody?.as(CodeBlockSyntax.self)?.statements)
    }
    
    internal init(node: IfExprSyntax) {
        self.node = node
    }
    
    internal init?(node: IfExprSyntax?) {
        guard let node else { return nil }
        self.node = node
    }
}

// MARK: BodyProviding comformance

extension If: BodyProviding {
    public var body: Body? {
        Body(node: node.body.statements)
    }
}
