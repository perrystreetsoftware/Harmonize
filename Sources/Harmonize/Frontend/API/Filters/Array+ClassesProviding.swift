//
//  Array+ClassesProviding.swift
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

/// An extension for arrays where the elements conform to both `Declaration` and `ClassesProviding`,
/// providing filtering functionality based on body.
public extension Array where Element: Declaration & ClassesProviding {
    /// Filters the array to include only elements that have classes satisfying the given predicate.
    ///
    /// - parameter predicate: A closure that takes a `Class` and returns a Boolean value indicating
    ///   whether the class meets the specified criteria.
    /// - returns: An array of elements that contain at least one class satisfying the predicate.
    func withClasses(_ predicate: (Class) -> Bool) -> [Element] {
        with(\.classes) { $0.contains(where: predicate) }
    }
    
    /// Retrieves a flat array of all classes from the elements in the array.
    ///
    /// - returns: An array of `Class` instances extracted from each element in the array.
    func classes() -> [Class] {
        flatMap { $0.classes }
    }
}
