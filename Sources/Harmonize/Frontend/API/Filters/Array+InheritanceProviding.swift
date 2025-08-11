//
//  Array+InheritanceProviding.swift
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

/// An extension for arrays where the elements conform to both `Declaration` and `InheritanceProviding`,
/// providing filtering functionality based on inheritance clause.
public extension Array where Element: Declaration & InheritanceProviding {
    /// Filters the array to include only elements that inherit from the specified class type.
    ///
    /// - Parameter anyClass: The class type to check inheritance against.
    /// - Parameter includeTransitiveInheritance: To also include transitive types inheritance. True by default.
    /// - Returns: An array of elements that inherit from the specified class.
    func inheriting(_ anyClass: AnyObject.Type, includeTransitiveInheritance: Bool = true) -> [Element] {
        filter { $0.inherits(from: anyClass, includeTransitiveInheritance: includeTransitiveInheritance) }
    }
    
    /// Filters the array to include only elements that inherit from the specified class name.
    ///
    /// - Parameter name: The name of the class to check inheritance against.
    /// - Parameter includeTransitiveInheritance: To also include transitive types inheritance. True by default.
    /// - Returns: An array of elements that inherit from the specified class name.
    func inheriting(from name: String, includeTransitiveInheritance: Bool = true) -> [Element] {
        filter { $0.inherits(from: name, includeTransitiveInheritance: includeTransitiveInheritance) }
    }
    
    /// Filters the array to include only elements that conform to the specified protocol type.
    ///
    /// - Parameter proto: The protocol type to check conformance against.
    /// - Parameter includeTransitiveInheritance: To also include transitive types inheritance. True by default.
    /// - Returns: An array of elements that conform to the specified protocol.
    func conforming<T>(to proto: T.Type, includeTransitiveInheritance: Bool = true) -> [Element] {
        filter { $0.conforms(to: proto, includeTransitiveInheritance: includeTransitiveInheritance) }
    }
    
    /// Filters the array to include only elements that conform to the specified protocol names.
    ///
    /// - Parameter names: The protocol names to check conformance against.
    /// - Parameter includeTransitiveInheritance: To also include transitive types inheritance. True by default.
    /// - Returns: An array of elements that conform to the specified protocol names.
    func conforming(to names: String..., includeTransitiveInheritance: Bool = true) -> [Element] {
        filter { $0.conforms(to: names, includeTransitiveInheritance: includeTransitiveInheritance) }
    }
    
    /// Filters the array to include only elements that conform to the specified protocol names.
    ///
    /// - Parameter names: An array of protocol names to check conformance against.
    /// - Parameter includeTransitiveInheritance: To also include transitive types inheritance. True by default.
    /// - Returns: An array of elements that conform to the specified protocol names.
    func conforming(to names: [String], includeTransitiveInheritance: Bool = true) -> [Element] {
        filter { $0.conforms(to: names, includeTransitiveInheritance: includeTransitiveInheritance) }
    }
}
