//
//  HarmonizeScopeBuilder.swift
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
import HarmonizeSemantics

/// The default Harmonize scope builder implementation.
/// Provides all declarations and files from a given path.
internal class HarmonizeScopeBuilder {
    private let file: StaticString
    private let getFiles: GetFiles
    
    private var folder: String? {
        didSet { filesCache = nil }
    }
    private var includingOnly: [String] = [] {
        didSet { filesCache = nil }
    }
    private var exclusions: [String] = [] {
        didSet { filesCache = nil }
    }

    private var filesCache: [SwiftSourceCode]?

    var files: [SwiftSourceCode] {
        if let cachedFiles = filesCache {
            return cachedFiles
        }

        let newFiles = getFiles(folder: folder, inclusions: includingOnly, exclusions: exclusions)
        filesCache = newFiles

        return newFiles
    }

    internal init(
        file: StaticString,
        folder: String? = nil,
        includingOnly: [String] = [],
        exclusions: [String] = []
    ) {
        self.file = file
        self.getFiles = GetFiles(file)
        self.folder = folder
        self.includingOnly = includingOnly
        self.exclusions = exclusions
    }
}

// MARK: - On

extension HarmonizeScopeBuilder: On {
    func on(_ folder: String) -> Excluding {
        self.folder = folder
        return self
    }
}

// MARK: - Excluding

extension HarmonizeScopeBuilder: Excluding {
    func excluding(_ excludes: String...) -> HarmonizeScope {
        self.exclusions = excludes + exclusions
        return self
    }

    func excluding(_ excludes: [String]) -> HarmonizeScope {
        self.exclusions = excludes + exclusions
        return self
    }
}

// MARK: - HarmonizeScope

extension HarmonizeScopeBuilder: HarmonizeScope {
    func classes(includeNested: Bool) -> [Class] {
        sources().flatMap {
            $0.classes(includeNested: includeNested)
        }
    }
    
    func classes() -> [Class] {
        classes(includeNested: false)
    }
    
    func enums(includeNested: Bool) -> [Enum] {
        sources().flatMap {
            $0.enums(includeNested: includeNested)
        }
    }
    
    func enums() -> [Enum] {
        enums(includeNested: false)
    }
    
    func extensions() -> [Extension] {
        sources().flatMap { $0.extensions() }
    }
    
    func sources() -> [SwiftSourceCode] {
        files
    }
    
    func functions(includeNested: Bool) -> [Function] {
        sources().flatMap { $0.functions(includeNested: includeNested) }
    }
    
    func functions() -> [Function] {
        functions(includeNested: false)
    }
    
    func imports() -> [Import] {
        sources().flatMap { $0.imports() }
    }
    
    func initializers() -> [Initializer] {
        sources().flatMap { $0.initializers() }
    }
    
    func variables(includeNested: Bool) -> [Variable] {
        sources().flatMap { $0.variables(includeNested: includeNested )}
    }
    
    func variables() -> [Variable] {
        variables(includeNested: false)
    }
    
    func protocols(includeNested: Bool) -> [ProtocolDeclaration] {
        sources().flatMap { $0.protocols(includeNested: includeNested )}
    }
    
    func protocols() -> [ProtocolDeclaration] {
        protocols(includeNested: false)
    }
    
    func structs(includeNested: Bool) -> [Struct] {
        sources().flatMap { $0.structs(includeNested: includeNested )}

    }
    
    func structs() -> [Struct] {
        structs(includeNested: false)
    }
}
