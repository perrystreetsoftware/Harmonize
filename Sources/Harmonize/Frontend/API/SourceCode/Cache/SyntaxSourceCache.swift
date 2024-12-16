//
//  SyntaxSourceCache.swift
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
import SwiftOperators
import HarmonizeUtils

/*
 * That's a very simple yet functional in memory caching mechanism based on SwiftLint's implementation
 * for sourceKitten symbols. This is far from making parsing optimal but helps avoid increasing time between
 * tests run. It compensates SwiftSyntax's parsing performance issue when you run all tests.
 */
internal class SyntaxSourceCache<Syntax> {
    private var elements: ConcurrentDictionary<UUID, Syntax> = ConcurrentDictionary()
    private let factory: (SwiftSourceCode) -> Syntax
    
    init(factory: @escaping (SwiftSourceCode) -> Syntax) {
        self.factory = factory
    }
    
    func get(_ source: SwiftSourceCode) -> Syntax {
        guard let element = elements[source.id] else {
            let newElement = factory(source)
            elements[source.id] = newElement
            return newElement
        }
        
        return element
    }
    
    func set(_ source: SwiftSourceCode, value: Syntax) {
        elements[source.id] = value
    }
    
    func removeValue(forKey uuid: UUID) -> Syntax? {
        elements.removeValue(forKey: uuid)
    }
    
    func removeAll() {
        elements.removeAll()
    }
}

internal let syntaxTreeCache = SyntaxSourceCache {
    Parser.parse(source: $0.source)
}

internal let foldedSyntaxTreeCache = SyntaxSourceCache { source -> SourceFileSyntax? in
    OperatorTable.standardOperators
        .foldAll(source.sourceFileSyntax) { _ in /* no-op */ }
        .as(SourceFileSyntax.self)
}
