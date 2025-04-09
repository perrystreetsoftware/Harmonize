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
import SwiftSyntax

/// An extension for arrays where the elements conform to both `Declaration` and `TypeProviding`,
/// providing filtering functionality based on type.
public extension Array where Element: SwiftSourceCode {
    /// Filters the array to include only elements whose names satifies the given predicate.
    ///
    /// - parameter predicate: name to match condition.
    /// - returns: An array containing the elements satisfying the given predicate.
    func withImport(_ predicate: (String) -> Bool) -> [Element] {
        filter { $0.imports().contains { predicate($0.name) } }
    }
    /// Filters the array to include only elements whose names are in the given names.
    ///
    /// - parameter names: names to match condition.
    /// - returns: An array containing the elements satisfying the given predicate.
    func withImport(_ names: [String]) -> [Element] {
        withImport(names.contains)
    }
    /// Filters the array to include only elements whose names satifies the given name.
    ///
    /// - parameter name: name to match condition.
    /// - returns: An array containing the elements satisfying the given predicate.
    func withImport(_ name: String) -> [Element] {
        withImport([name])
    }
    /// Filters the array to include only elements whose names satifies the given predicate.
    ///
    /// - parameter predicate: name to match condition.
    /// - returns: An array containing the elements satisfying the given predicate.
    func withName(_ predicate: (String) -> Bool) -> [Element] {
        filter { predicate($0.fileName!) }
    }
    /// Filters the array to include only elements whose names are in the given names.
    ///
    /// - parameter names: names to match condition.
    /// - returns: An array containing the elements satisfying the given predicate.
    func withName(_ names: [String]) -> [Element] {
        withName(names.contains)
    }

    /// Filters the array to include only elements whose names satifies the given name.
    ///
    /// - parameter name: name to match condition.
    /// - returns: An array containing the elements satisfying the given predicate.
    func withName(_ name: String) -> [Element] {
        withName([name])
    }

    /// Filters the array to exclude elements whose names satifies the given predicate.
    ///
    /// - parameter predicate: name to exclude.
    /// - returns: An array containing the elements satisfying the given predicate.
    func withoutName(_ predicate: (String) -> Bool) -> [Element] {
        filter { !predicate($0.fileName!) }
    }

    /// Filters the array to exclude elements whose names are in the given names.
    ///
    /// - parameter names: names to exclude.
    /// - returns: An array containing the elements satisfying the given predicate.
    func withoutName(_ names: [String]) -> [Element] {
        withoutName(names.contains)
    }

    /// Filters the array to include only elements whose names end with any of the specified suffixes.
    ///
    /// - parameter suffixes: One or more suffixes to match.
    /// - returns: A filtered array of elements whose names end with one of the provided suffixes.
    func withSuffix(_ suffixes: String...) -> [Element] {
        withName {
            suffixes.contains(where: $0.hasSuffix)
        }
    }

    /// Filters the array to include only elements whose names end with any of the specified suffixes.
    /// Identical to method above, just matches Konsist naming
    ///
    /// - parameter suffixes: One or more suffixes to match.
    /// - returns: A filtered array of elements whose names end with one of the provided suffixes.
    func withNameEndingWith(_ suffixes: String...) -> [Element] {
        withName {
            suffixes.contains(where: $0.hasSuffix)
        }
    }

    /// Filters the array to include only elements whose names do not end with any of the specified suffixes.
    ///
    /// - parameter suffixes: One or more suffixes to exclude.
    /// - returns: A filtered array of elements whose names do not end with any of the provided suffixes.
    func withoutSuffix(_ suffixes: String...) -> [Element] {
        withoutName {
            suffixes.contains(where: $0.hasSuffix)
        }
    }
}
