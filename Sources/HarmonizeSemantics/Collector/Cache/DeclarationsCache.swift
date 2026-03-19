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
        let cacheCopy = locking { typeInheritanceCache }
        return findSupertype(of: subtype, in: cacheCopy, visited: [])
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

    private func findSupertype(
        of subtype: String,
        in cache: [String: [String]],
        visited: Set<String>
    ) -> String? {
        guard !visited.contains(subtype) else { return nil }

        let matches = cache.compactMap { $0.value.contains(subtype) ? $0.key : nil }

        guard let directSupertype = matches.first else {
            return nil
        }

        var visited = visited
        visited.insert(subtype)

        if matches.count == 1 {
            let resolved = findSupertype(
                of: directSupertype,
                in: cache,
                visited: visited
            )

            return resolvedSupertype(
                resolved ?? directSupertype,
                visited: visited
            )
        }

        let firstSupertype = matches.first { type in
            cache[type] != nil
        }

        guard let firstSupertype else {
            return resolvedSupertype(
                directSupertype,
                visited: visited
            )
        }

        let resolved = findSupertype(
            of: firstSupertype,
            in: cache,
            visited: visited
        )

        return resolvedSupertype(
            resolved ?? firstSupertype,
            visited: visited
        )
    }

    private func resolvedSupertype(
        _ candidate: String,
        visited: Set<String>
    ) -> String? {
        visited.contains(candidate) ? nil : candidate
    }

    private func locking<T>(f: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return f()
    }
}
