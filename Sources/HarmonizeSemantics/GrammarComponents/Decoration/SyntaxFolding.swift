//
//  SyntaxFolding.swift
//  Harmonize
//
//  Copyright 2026 Perry Street Software Inc.

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
import SwiftOperators

/// Operator folding applied at the point of use.
///
/// The parser leaves binary/ternary operator chains as flat `SequenceExprSyntax`
/// nodes; only folding turns them into `InfixOperatorExprSyntax`. Folding the
/// whole source tree up front roughly doubles per-file parsing cost, so instead
/// the few places that need expression structure fold just the expression they
/// are looking at.
internal enum SyntaxFolding {
    /// Returns the node as an `InfixOperatorExprSyntax`, folding an unfolded
    /// operator sequence if needed. Nil when the node is not an infix expression.
    static func infixOperator(from node: some SyntaxProtocol) -> InfixOperatorExprSyntax? {
        if let infixOperator = node.as(InfixOperatorExprSyntax.self) {
            return infixOperator
        }

        guard let sequence = node.as(SequenceExprSyntax.self) else {
            return nil
        }

        return OperatorTable.standardOperators
            .foldAll(sequence) { _ in /* no-op */ }
            .as(InfixOperatorExprSyntax.self)
    }
}
