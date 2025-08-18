//
//  DeclarationsCache.swift
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
import Foundation

internal class DeclarationsCache {
    private let lock = NSLock()

    internal static let shared = DeclarationsCache()
    
    private var nodesAndDeclarations: [Syntax: [Declaration]] = [:]
    private var resolved: [Syntax: Declaration] = [:]
    
    private var typeInheritanceCache: [String: [String]] = [:]
    
    private init() {}
    
    func declarations(from parent: SyntaxProtocol) -> [Declaration] {
        locking {
            nodesAndDeclarations[parent._syntaxNode, default: []]
        }
    }
    
    func put(children declarations: [Declaration], for parent: SyntaxProtocol) {
        locking {
            nodesAndDeclarations[parent._syntaxNode] = declarations
        }
    }
    
    func inheritedTypes(of type: String) -> [String] {
        locking {
            typeInheritanceCache[type, default: []]
        }
    }
    
    func supertype(of subtype: String) -> String? {
        let matches = typeInheritanceCache.compactMap {
            $0.value.contains(subtype) ? $0.key : nil
        }

        guard let directSupertype = matches.first else {
            return nil
        }

        if matches.count == 1 {
            return supertype(of: directSupertype) ?? directSupertype
        }
        
        let firstSupertype = matches.first { supertype in
            typeInheritanceCache.keys.contains(supertype)
        }
        
        guard let firstSupertype else { return directSupertype }
        return supertype(of: firstSupertype) ?? firstSupertype
    }
    
    func put(subtype typeName: String, of type: String) {
        locking {
            var values = typeInheritanceCache[type, default: []]
            if !values.contains(typeName) {
                values.append(typeName)
            }
            typeInheritanceCache[type] = values
        }
    }
    
    private func locking<T>(f: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return f()
    }
}
