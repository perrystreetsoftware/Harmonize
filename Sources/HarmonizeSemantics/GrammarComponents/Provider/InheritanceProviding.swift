//
//  InheritanceProviding.swift
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
import SwiftParser
import SwiftSyntax

/// A protocol that provides information about the types a declaration inherits from or conforms to.
public protocol InheritanceProviding {
    /// A collection of all type names that this declaration inherits from or conforms to.
    var inheritanceTypesNames: [String] { get }
}

public extension InheritanceProviding {
    /// Checks whether the declaration inherits from a given class or object type.
    ///
    /// - Parameter type: The object type to check against. This must be a class type (`AnyObject`).
    /// - Parameter includeTransitiveInheritance: To also include transitive types inheritance. True by default.
    /// - Returns: `true` if the declaration inherits from the given class or object type, `false` otherwise.
    func inherits(from type: AnyObject.Type, includeTransitiveInheritance: Bool = true) -> Bool {
        inherits(from: String(describing: type.self), includeTransitiveInheritance: includeTransitiveInheritance)
    }

    /// Checks whether the declaration inherits from a given class or object name.
    ///
    /// - Parameters:
    ///   - name: The name of the class or object to check inheritance from.
    ///   - includeTransitiveInheritance: To also include transitive types inheritance. True by default.
    ///   - strict: If `true`, the check is strict and requires an exact match; otherwise, it allows for inheritance from superclasses. Default is `false`.
    /// - Returns: `true` if the declaration inherits from the given class or object name, `false` otherwise.
    func inherits(from name: String, includeTransitiveInheritance: Bool = true, strict: Bool = false) -> Bool {        
        let baseNames = name.baseTypeNames
        let matches: (String) -> Bool = { strict ? $0 == name : baseNames.isSubset(of: $0.baseTypeNames) }

        return inheritanceTypesNames.contains {
            let hasDirectInheritance = matches($0)
            let supertype = includeTransitiveInheritance ? DeclarationsCache.shared.supertype(of: $0) : nil
            let hasTransitiveInheritance = supertype.map(matches) ?? false
            return hasDirectInheritance || hasTransitiveInheritance
        }
    }

    /// Checks whether the declaration conforms to a given protocol type.
    ///
    /// - Parameter type: The protocol type to check for conformance.
    /// - Parameter includeTransitiveInheritance: To also include transitive types inheritance. True by default.
    /// - Returns: `true` if the declaration conforms to the given protocol, `false` otherwise.
    func conforms<T>(to type: T.Type, includeTransitiveInheritance: Bool = true, strict: Bool = false) -> Bool {
        conforms(
            to: String(describing: type.self),
            includeTransitiveInheritance: includeTransitiveInheritance,
            strict: strict
        )
    }

    /// Checks whether the declaration conforms to a set of protocols by their names.
    ///
    /// - Parameters:
    ///   - protos: A variadic list of protocol names to check for conformance.
    ///   - includeTransitiveInheritance: To also include transitive types inheritance. True by default.
    ///   - strict: If `true`, the check requires exact matches for the protocol names; if `false`, names match ignoring module qualification and generic arguments. Default is `false`.
    /// - Returns: `true` if the declaration conforms to all of the given protocol names, `false` otherwise.
    func conforms(to protos: String..., includeTransitiveInheritance: Bool = true, strict: Bool = false) -> Bool {
        protos.contains { inherits(from: $0, includeTransitiveInheritance: includeTransitiveInheritance, strict: strict) }
    }

    /// Checks whether the declaration conforms to a list of protocols by their names.
    ///
    /// - Parameters:
    ///   - protos: An array of protocol names to check for conformance.
    ///   - includeTransitiveInheritance: To also include transitive types inheritance. True by default.
    ///   - strict: If `true`, the check requires exact matches for the protocol names; if `false`, names match ignoring module qualification and generic arguments. Default is `false`.
    /// - Returns: `true` if the declaration conforms to all of the given protocol names, `false` otherwise.
    func conforms(to protos: [String], includeTransitiveInheritance: Bool = true, strict: Bool = false) -> Bool {
        protos.contains { inherits(from: $0, includeTransitiveInheritance: includeTransitiveInheritance, strict: strict) }
    }
}

private extension String {
    /// The bare type names, without module qualification or generic arguments:
    /// `MyModule.BaseViewModel`, `BaseViewModel<State>`, `Container<() -> Void>.BaseViewModel`
    /// all become `["BaseViewModel"]`, and a composition `A & B` becomes `["A", "B"]`.
    /// The name is parsed as a Swift type, so generic arguments of any shape
    /// (function types, tuples, nested generics) are handled by the parser.
    var baseTypeNames: Set<String> {
        var parser = Parser(self)
        return TypeSyntax.parse(from: &parser).baseTypeNames
    }
}

private extension TypeSyntax {
    var baseTypeNames: Set<String> {
        if let composition = self.as(CompositionTypeSyntax.self) {
            return Set(composition.elements.flatMap(\.type.baseTypeNames))
        }

        if let member = self.as(MemberTypeSyntax.self) {
            return [member.name.text]
        }

        if let identifier = self.as(IdentifierTypeSyntax.self) {
            return [identifier.name.text]
        }

        return [trimmedDescription]
    }
}
