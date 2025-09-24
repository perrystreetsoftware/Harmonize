//
//  SwiftSourceCode.swift
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
import SwiftParser
import HarmonizeSemantics

/// Represents a source of Swift code, which can either be loaded from a URL or provided as a raw string.
/// This class offers lazy loading of the source text, resolving it from either the provided URL or raw string.
public final class SwiftSourceCode {
    /// Transforms Swift Syntax into the Semantics Models.
    internal lazy var resolver: SourceFileSyntaxResolver = {
        // Not ideal as it will break lazy evaluation of the Source File Syntax.
        // 'Fine' for this initial release, but we must rework this when Harmonize
        // evolves to be a 'File Query' over swift files.
        SourceFileSyntaxResolver(source: self, node: foldedSourceFileSyntax ?? sourceFileSyntax)
    }()

    /// The URL pointing to the Swift source file, if provided. Nil if `source` is provided directly as string.
    private let url: URL?
    
    /// Unique identifier for this Source.
    public let id: UUID = UUID()
    
    /// Returns the Swift source code as a string. This returns either the URL or using the raw string, depending on which was initialized.
    public let source: String
    
    /// Initializes the `SwiftSourceCode` with a URL pointing to a Swift source file.
    ///
    /// - parameter url: The file URL to the Swift source code.
    public init?(url: URL) {
        guard let source = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        self.url = url
        self.source = source
    }

    /// Initializes the `SwiftSourceCode` with a raw Swift source code string.
    ///
    /// - parameter source: A string containing Swift source code.
    public init(source: String) {
        self.url = nil
        self.source = source
    }
    
    /// Returns the name of the file associated with this instance, if available.
    public var fileName: String? {
        url?.lastPathComponent
    }
    
    /// Returns the file path associated with this instance, if available.
    public var filePath: URL? {
        url
    }
    
    /// Returns ``Class`` collection within this source.
    public func classes(includeNested: Bool = true) -> [Class] {
        if !includeNested {
            return resolver.collection().classes
        }
        
        return resolver.collection().declarations.as(Class.self)
    }
    
    /// Returns ``Enum`` collection within this source.
    public func enums(includeNested: Bool = true) -> [Enum] {
        if !includeNested {
            return resolver.collection().enums
        }
        
        return resolver.collection().declarations.as(Enum.self)
    }
    
    /// Returns ``Extension`` collection within this source.
    public func extensions() -> [Extension] {
        resolver.collection().extensions
    }
    
    /// Returns ``Function`` collection within this source.
    public func functions(includeNested: Bool = true) -> [Function] {
        if !includeNested {
            return resolver.collection().functions
        }
        
        return resolver.collection().declarations.as(Function.self)
    }
    
    /// Returns ``Import`` collection within this source.
    public func imports() -> [Import] {
        resolver.collection().imports
    }
    
    /// Returns ``Initializer`` collection within this source.
    public func initializers() -> [Initializer] {
        resolver.collection().initializers
    }
    
    /// Returns ``ProtocolDeclaration`` collection within this source.
    public func protocols(includeNested: Bool = true) -> [ProtocolDeclaration] {
        if !includeNested {
            return resolver.collection().protocols
        }
        
        return declarations().as(ProtocolDeclaration.self)
    }
    
    /// Returns ``Struct`` collection within this source.
    public func structs(includeNested: Bool = true) -> [Struct] {
        if !includeNested {
            return resolver.collection().structs
        }
        
        return declarations().as(Struct.self)
    }
    
    /// Returns ``Variable`` collection within this source.
    public func variables(includeNested: Bool = true) -> [Variable] {
        if !includeNested {
            return resolver.collection().variables
        }
        
        return declarations().as(Variable.self)
    }
    
    private func declarations() -> [Declaration] {
        resolver.collection().declarations
    }
}

// MARK: - Equatable

extension SwiftSourceCode: Equatable, Hashable  {
    public static func == (lhs: SwiftSourceCode, rhs: SwiftSourceCode) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - SyntaxSourceCache

internal extension SwiftSourceCode {
    var sourceFileSyntax: SourceFileSyntax {
        syntaxTreeCache.get(self)
    }
    
    var foldedSourceFileSyntax: SourceFileSyntax? {
        foldedSyntaxTreeCache.get(self)
    }
}

// MARK: - SourceFileSyntaxResolver

internal extension SwiftSourceCode {
    final class SourceFileSyntaxResolver {
        private let source: SwiftSourceCode
        private let node: SourceFileSyntax
        private let collector: DeclarationsCollector
        
        init(source: SwiftSourceCode, node: SourceFileSyntax) {
            self.source = source
            self.node = node
            self.collector = DeclarationsCollector(
                sourceCodeLocation: SourceCodeLocation(
                    sourceFilePath: source.url,
                    sourceFileTree: node
                )
            )
            
            collector.walk(node) // side-effect. Rework this when api is 'lazier'?
        }
        
        func collection() -> DeclarationsCollector {
            collector
        }
    }
}
