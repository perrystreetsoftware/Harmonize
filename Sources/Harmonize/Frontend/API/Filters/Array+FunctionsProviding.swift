//
//  Array+FunctionsProviding.swift
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

/// An extension for arrays where the elements conform to both `Declaration` and `FunctionsProviding`,
/// providing filtering functionality based on functions.
public extension Array where Element: Declaration & FunctionsProviding {
    /// Filters the array to include only elements that contain functions satisfying the given predicate.
    ///
    /// - Parameter predicate: A closure that takes a `Function` and returns a Boolean value indicating
    ///   whether the function meets the specified criteria.
    /// - Returns: An array of elements that contain at least one function satisfying the predicate.
    func withFunctions(_ predicate: (Function) -> Bool) -> [Element] {
        with(\.functions) { $0.contains(where: predicate) }
    }
    
    /// Retrieves a flat array of all functions from the elements in the array.
    ///
    /// - Returns: An array of `Function` instances extracted from each element in the array that
    ///   conforms to `FunctionsProviding`.
    func functions() -> [Function] {
        flatMap { $0.functions }
    }
}
