//
//  Array+Enum.swift
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

/// Provides extension methods for filtering and retrieving cases from an array of enums.
public extension Array where Element == Enum {
    /// Filters the array to include only enum elements that contain cases satisfying the given predicate.
    ///
    /// - parameter predicate: A closure that takes an `EnumCase` and returns a Boolean value indicating
    ///   whether the case meets the specified criteria.
    /// - returns: An array of enum elements that contain at least one case satisfying the predicate.
    func withCases(_ predicate: (EnumCase) -> Bool) -> [Element] {
        with(\.cases) { $0.contains(where: predicate) }
    }
    
    /// Retrieves a flat array of all cases from the enum elements in the array.
    ///
    /// - returns: An array of `EnumCase` instances extracted from each enum element in the array.
    func cases() -> [EnumCase] {
        flatMap { $0.cases }
    }
}
