//
//  Array+InitializerClauseProviding.swift
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

/// An extension for arrays where the elements conform to both `Declaration`
/// and `InitializerClauseProviding`,
/// providing filtering functionality based on initializer clause.
public extension Array where Element: Declaration & InitializerClauseProviding {
    /// Filters the array to include only elements that have an initializer clause satisfying the given predicate.
    ///
    /// - parameter predicate: A closure that takes an `InitializerClause` and returns a Boolean value indicating
    ///   whether the initializer clause meets the specified criteria.
    /// - returns: An array of elements that have an initializer clause satisfying the predicate.
    func withInitializerClause(_ predicate: (InitializerClause) -> Bool) -> [Element] {
        with(\.initializerClause) {
            guard let initializerClause = $0 else { return false }
            return predicate(initializerClause)
        }
    }
    
    /// Filters the array to include only elements that have an initializer clause with a value satisfying the given predicate.
    ///
    /// - parameter predicate: A closure that takes a `String` representing the value and returns a Boolean value indicating
    ///   whether the value meets the specified criteria.
    /// - returns: An array of elements that have an initializer clause with a value satisfying the predicate.
    func withValue(_ predicate: (String) -> Bool) -> [Element] {
        withInitializerClause {
            predicate($0.value)
        }
    }
    
    /// Filters the array to include only elements that have an initializer clause with a value matching the specified regex.
    ///
    /// - parameter regex: A regex component to check against the value of the initializer clause.
    /// - returns: An array of elements that have an initializer clause with a value containing the specified regex.
    @available(iOS 16.0, macOS 13.0, *)
    func withValue(containing regex: some RegexComponent) -> [Element] {
        withValue { $0.contains(regex) }
    }
    
    /// Filters the array to include only elements that have an initializer clause with a value matching the specified regex.
    ///
    /// - parameter regex: A regex component to check against the value of the initializer clause.
    /// - returns: An array of elements that have an initializer clause with a value containing the specified regex.
    func withValue(containing regex: String) -> [Element] {
        withValue {
            let range = NSRange(location: 0, length: $0.utf16.count)
            let regex = try? NSRegularExpression(pattern: regex)
            return regex?.firstMatch(in: $0, options: [], range: range) != nil
        }
    }
}
