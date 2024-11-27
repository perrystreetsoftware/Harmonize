//
//  Array+ModifiersProviding.swift
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

/// An extension for arrays where the elements conform to both `Declaration` and `ModifiersProviding`,
/// providing filtering functionality based on modifiers.
public extension Array where Element: Declaration & ModifiersProviding {
    /// Filters the array to include only elements that have modifiers satisfying the given predicate.
    ///
    /// - parameter predicate: A closure that takes a `Modifier` and returns a Boolean value indicating
    ///   whether the modifier meets the specified criteria.
    /// - returns: An array of elements that contain modifiers satisfying the predicate.
    func withModifiers(_ predicate: (Modifier) -> Bool) -> [Element] {
        with(\.modifiers) { $0.contains(where: predicate) }
    }
    
    /// Filters the array to include only elements that do not have modifiers satisfying the given predicate.
    ///
    /// - parameter predicate: A closure that takes a `Modifier` and returns a Boolean value indicating
    ///   whether the modifier meets the specified criteria.
    /// - returns: An array of elements that do not contain modifiers satisfying the predicate.
    func withoutModifiers(_ predicate: (Modifier) -> Bool) -> [Element] {
        withNot(\.modifiers) { $0.contains(where: predicate) }
    }
    
    /// Filters the array to include only elements that have the specified modifiers.
    ///
    /// - parameter modifiers: A variadic list of `Modifier` values to check against the elements' modifiers.
    /// - returns: An array of elements that contain any of the specified modifiers.
    func withModifier(_ modifiers: Modifier...) -> [Element] {
        withModifiers { modifiers.contains($0) }
    }
    
    /// Filters the array to include only elements that do not have the specified modifiers.
    ///
    /// - parameter modifiers: A variadic list of `Modifier` values to check against the elements' modifiers.
    /// - returns: An array of elements that do not contain any of the specified modifiers.
    func withoutModifier(_ modifiers: Modifier...) -> [Element] {
        withoutModifiers { modifiers.contains($0) }
    }
    
    /// Filters the array to include only elements that have a public modifier.
    ///
    /// - returns: An array of elements that contain the `.public` modifier.
    func withPublicModifier() -> [Element] {
        withModifier(.public)
    }
    
    /// Filters the array to include only elements that have a private modifier.
    ///
    /// - returns: An array of elements that contain the `.private` modifier.
    func withPrivateModifier() -> [Element] {
        withModifier(.private)
    }
    
    /// Filters the array to include only elements that have a final modifier.
    ///
    /// - returns: An array of elements that contain the `.final` modifier.
    func withFinalModifier() -> [Element] {
        withModifier(.final)
    }
}
