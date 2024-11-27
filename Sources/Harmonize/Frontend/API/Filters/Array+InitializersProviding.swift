//
//  Array+InitializersProviding.swift
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

/// An extension for arrays where the elements conform to both `Declaration` and `InitializersProviding`,
/// providing filtering functionality based on initializers.
public extension Array where Element: Declaration & InitializersProviding {
    /// Filters the array to include only elements that have initializers satisfying the given predicate.
    ///
    /// - parameter predicate: A closure that takes an `Initializer` and returns a Boolean value indicating
    ///   whether the initializer meets the specified criteria.
    /// - returns: An array of elements that contain initializers satisfying the predicate.
    func withInitializers(_ predicate: (Initializer) -> Bool) -> [Element] {
        with(\.initializers) { $0.contains(where: predicate) }
    }
    
    /// Retrieves an array of all initializers from the elements in the array.
    ///
    /// - returns: An array containing all `Initializer` instances from the elements that conform to
    ///   the `InitializersProviding` protocol.
    func initializers() -> [Initializer] {
        flatMap { $0.initializers }
    }
}
