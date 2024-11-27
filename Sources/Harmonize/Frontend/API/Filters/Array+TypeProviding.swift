//
//  Array+TypeProviding.swift
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

/// An extension for arrays where the elements conform to both `Declaration` and `TypeProviding`,
/// providing filtering functionality based on type.
public extension Array where Element: Declaration & TypeProviding {
    /// Returns an array of elements that have a type annotation satisfying the specified predicate.
    ///
    /// - parameter predicate: A closure that takes a `TypeAnnotation` and returns a Boolean value
    ///   indicating whether the type annotation should be included in the result.
    /// - returns: An array of elements that have type annotations satisfying the predicate.
    func withType(_ predicate: (TypeAnnotation) -> Bool) -> [Element] {
        with(\.typeAnnotation) {
            guard let type = $0 else { return false }
            return predicate(type)
        }
    }
    
    /// Returns an array of elements with a type annotation that matches the specified name.
    ///
    /// - Parameter named: The name of the type annotation to match.
    /// - Returns: An array of elements that have a type annotation with the specified name.
    func withType(named: String) -> [Element] {
        withType { $0.annotation == named }
    }
    
    /// Returns an array of elements with a type annotation that matches the specified type.
    ///
    /// - Parameter type: The type to match against the type annotation.
    /// - Returns: An array of elements that have a type annotation matching the specified type.
    func withType<T>(_ type: T.Type) -> [Element] {
        withType(named: String(describing: type))
    }
    
    /// Returns an array of elements that do not have a type annotation.
    ///
    /// - Returns: An array of elements with no type annotation.
    func withInferredType() -> [Element] {
        filter { $0.typeAnnotation == nil }
    }
}
