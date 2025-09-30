//
//  Closure.swift
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

/// Represents a closure expression in Swift AST.
/// This structure provides access to various components of a closure.
public struct Closure: DeclarationDecoration, SyntaxNodeProviding {
    public let node: ClosureExprSyntax
    public let sourceCodeLocation: SourceCodeLocation?

    /// The parameters of the closure, represented as an array of strings.
    public var parameters: [String] {
        if let shortHandParams = node.signature?.parameterClause?.as(ClosureShorthandParameterListSyntax.self) {
            return shortHandParams.map(\.name.text)
        }
        
        if let params = node.signature?.parameterClause?.as(ClosureParameterClauseSyntax.self) {
            return params.parameters.map(\.firstName.text)
        }
        
        return []
    }
    
    /// The return clause of the closure, if any.
    public var returnClause: ReturnClause? {
        ReturnClause(node: node.signature?.returnClause)
    }
    
    /// The captures of the closure, i.e., the values that are captured by the closure.
    /// - Returns: An array of `Capture` objects representing each captured value. Returns an empty array if there are no captured values.
    public var captures: [Capture] {
        node.signature?.capture?.items.map(Capture.init(node:)) ?? []
    }
    
    public var description: String {
        node.trimmedDescription
    }
    
    public var hasSelfReference: Bool {
        return body?.hasAnySelfReference ?? false
    }
    
    public func isCapturing(valueOf value: String) -> Bool {
        return captures.contains(where: { $0.node.name.text == value })
    }
    
    public func isCapturingWeak(valueOf value: String) -> Bool {
        return captures.contains(where: { $0.isWeak() && $0.node.name.text == value })
    }
    
    public func isCapturingUnowned(valueOf value: String) -> Bool {
        return captures.contains(where: { $0.isUnowned() && $0.node.name.text == value })
    }
    
    internal init(node: ClosureExprSyntax, sourceCodeLocation: SourceCodeLocation? = nil) {
        self.node = node
        self.sourceCodeLocation = sourceCodeLocation
    }
    
    internal init?(node: ClosureExprSyntax?, sourceCodeLocation: SourceCodeLocation? = nil) {
        guard let node else { return nil }
        self.node = node
        self.sourceCodeLocation = sourceCodeLocation
    }
}

// MARK: - AttributesProviding Comformance

extension Closure: AttributesProviding, BodyProviding, VariablesProviding {
    public var attributes: [Attribute] {
        node.signature?.attributes.attributes ?? []
    }

    public var body: Body? {
        Body(node: node.statements, sourceCodeLocation: self.sourceCodeLocation)
    }

    public var variables: [Variable] {
        body?.variables ?? []
    }
}

// MARK: - Capture

extension Closure {
    public struct Capture: DeclarationDecoration, SyntaxNodeProviding {
        public enum Specifier: Equatable {
            case weak
            case unowned(detail: String)
            
            var description: String {
                switch self {
                case .weak: "weak"
                case .unowned(detail: let detail): "unowned(\(detail))"
                }
            }
            
            var isWeak: Bool {
                switch self {
                case .weak: return true
                case .unowned: return false
                }
            }
            
            var isUnowned: Bool {
                switch self {
                case .weak: return false
                case .unowned: return true
                }
            }
        }
        
        /// The underlying syntax node for the capture.
        public var node: ClosureCaptureSyntax
        
        /// A textual description of the statement, trimmed for readability.
        public var description: String {
            node.trimmedDescription
        }
        
        /// The captured closure value specifier if any.
        public var specifier: Specifier? {
            switch node.specifier?.specifier.tokenKind {
            case .keyword(.weak): .weak
            case .keyword(.unowned): .unowned(detail: node.specifier?.detail?.text ?? "")
            default: nil
            }
        }
        
        /// The text representation of the captured value.
        public var value: String {
            node.initializer?.value.trimmedDescription ?? ""
        }
        
        internal init(node: ClosureCaptureSyntax) {
            self.node = node
        }
        
        public func isWeak() -> Bool {
            return specifier?.isWeak == true
        }
        
        public func isUnowned() -> Bool {
            return specifier?.isUnowned == true
        }
        
        public func isSafeUnowned() -> Bool {
            return specifier?.description == "unowned(safe)"
        }
        
        public func isUnsafeUnowned() -> Bool {
            return specifier?.description == "unowned(unsafe)"
        }
    }
}
