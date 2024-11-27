//
//  PlainSourceScopeBuilder.swift
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

import HarmonizeSemantics

/// The Harmonize scope builder implementation that parses plain source code over `.swift` files.
internal class PlainSourceScopeBuilder {
    private let sourceCode: SwiftSourceCode
    
    internal init(source: String) {
        self.sourceCode = SwiftSourceCode(source: source)
    }
}

// MARK: - HarmonizeScope

extension PlainSourceScopeBuilder: HarmonizeScope {
    func classes(includeNested: Bool) -> [Class] {
        sourceCode.classes(includeNested: includeNested)
    }
    
    func classes() -> [Class] {
        classes(includeNested: false)
    }
    
    func enums(includeNested: Bool) -> [Enum] {
        sourceCode.enums(includeNested: includeNested)
    }
    
    func enums() -> [Enum] {
        enums(includeNested: false)
    }
    
    func extensions() -> [Extension] {
        sourceCode.extensions()
    }
    
    func sources() -> [SwiftSourceCode] {
        [sourceCode]
    }
    
    func functions(includeNested: Bool) -> [Function] {
        sourceCode.functions(includeNested: includeNested)
    }
    
    func functions() -> [Function] {
        functions(includeNested: false)
    }
    
    func imports() -> [Import] {
        sourceCode.imports()
    }
    
    func initializers() -> [Initializer] {
        sourceCode.initializers()
    }
    
    func variables(includeNested: Bool) -> [Variable] {
        sourceCode.variables(includeNested: includeNested)
    }
    
    func variables() -> [Variable] {
        variables(includeNested: false)
    }
    
    func protocols(includeNested: Bool) -> [ProtocolDeclaration] {
        sourceCode.protocols(includeNested: includeNested)
    }
    
    func protocols() -> [ProtocolDeclaration] {
        protocols(includeNested: false)
    }
    
    func structs(includeNested: Bool) -> [Struct] {
        sourceCode.structs(includeNested: includeNested)
    }
    
    func structs() -> [Struct] {
        structs(includeNested: false)
    }
}
