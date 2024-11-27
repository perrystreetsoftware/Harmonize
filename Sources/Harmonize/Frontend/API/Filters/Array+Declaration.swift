//
//  Array+Declaration.swift
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

/// Provides extension methods for filtering arrays of declarations based on key paths.
public extension Array where Element: Declaration {
    /// Filters the array to include only elements where the specified key path's value satisfies the given predicate.
    ///
    /// - parameters:
    ///   - path: A key path to the property of the element to be evaluated.
    ///   - predicate: A closure that takes a value of the type at the key path and returns a Boolean value
    ///     indicating whether the value meets the specified criteria.
    /// - returns: An array of elements whose property at the specified key path satisfies the predicate.
    func with<KeyType>(
        _ path: KeyPath<Element, KeyType>,
        predicate: (KeyType) -> Bool
    ) -> [Element] {
        filter { predicate($0[keyPath: path]) }
    }
    
    /// Filters the array to include only elements where the specified key path's value does not satisfy the given predicate.
    ///
    /// - parameters:
    ///   - path: A key path to the property of the element to be evaluated.
    ///   - predicate: A closure that takes a value of the type at the key path and returns a Boolean value
    ///     indicating whether the value meets the specified criteria.
    /// - returns: An array of elements whose property at the specified key path does not satisfy the predicate.
    func withNot<KeyType>(
        _ path: KeyPath<Element, KeyType>,
        predicate: (KeyType) -> Bool
    ) -> [Element] {
        with(path, predicate: { !predicate($0) })
    }
}
