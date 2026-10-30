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

    /// Maps a type name to the names it directly inherits from or conforms to.
    private var typeInheritanceCache: [String: [String]] = [:]

    /// Reverse index of `typeInheritanceCache`: maps a subtype to its direct
    /// supertypes, so `supertypes(of:)` resolves by dictionary lookup instead
    /// of scanning every entry.
    private var supertypesBySubtype: [String: [String]] = [:]

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

    /// Merges one file's worth of collected declarations and inheritance edges
    /// in a single lock acquisition, so concurrent collectors contend once per
    /// file instead of once per declaration.
    func merge(
        nodesAndDeclarations fileNodes: [Syntax: [Declaration]],
        inheritanceEdges: [(subtype: String, supertype: String)]
    ) {
        locking {
            nodesAndDeclarations.merge(fileNodes) { _, new in new }
            for edge in inheritanceEdges {
                unsafePut(subtype: edge.subtype, of: edge.supertype)
            }
        }
    }

    func inheritedTypes(of type: String) -> [String] {
        locking {
            typeInheritanceCache[type, default: []]
        }
    }

    /// Returns every known ancestor of `subtype`: direct supertypes, their supertypes, and so on,
    /// following all branches of multiple inheritance. Cycles are ignored.
    func supertypes(of subtype: String) -> Set<String> {
        locking {
            var ancestors = Set<String>()
            var pending = supertypesBySubtype[subtype, default: []]

            while let type = pending.popLast() {
                guard type != subtype, ancestors.insert(type).inserted else { continue }
                pending.append(contentsOf: supertypesBySubtype[type, default: []])
            }

            return ancestors
        }
    }

    func put(subtype typeName: String, of type: String) {
        locking {
            unsafePut(subtype: typeName, of: type)
        }
    }

    /// Must be called while holding `lock`.
    private func unsafePut(subtype typeName: String, of type: String) {
        var values = typeInheritanceCache[type, default: []]
        if !values.contains(typeName) {
            values.append(typeName)
        }
        typeInheritanceCache[type] = values

        var supertypes = supertypesBySubtype[typeName, default: []]
        if !supertypes.contains(type) {
            supertypes.append(type)
        }
        supertypesBySubtype[typeName] = supertypes
    }

    private func locking<T>(f: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return f()
    }
}
