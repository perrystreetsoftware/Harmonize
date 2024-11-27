//
//  Array+VariablesProviding.swift
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

/// An extension for arrays where the elements conform to both `Declaration` and `VariablesProviding`,
/// providing filtering functionality based on variables.
public extension Array where Element: Declaration & VariablesProviding {
    /// Returns an array of elements that have variables satisfying the specified predicate.
    ///
    /// - parameter predicate: A closure that takes a `Variable` and returns a Boolean value
    ///   indicating whether the variable should be included in the result.
    /// - returns: An array of elements that have variables satisfying the predicate.
    func withVariables(_ predicate: (Variable) -> Bool) -> [Element] {
        with(\.variables) { $0.contains(where: predicate) }
    }
    
    /// Returns an array of all variables from the elements in the array.
    ///
    /// - returns: An array of all `Variable` instances contained within the elements.
    func variables() -> [Variable] {
        flatMap { $0.variables }
    }
}
