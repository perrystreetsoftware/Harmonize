//
//  Array+BodyProviding.swift
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

/// An extension for arrays where the elements conform to both `Declaration` and `BodyProviding`,
/// providing filtering functionality based on body.
public extension Array where Element: Declaration & BodyProviding {
    /// Filters the array to include only elements with a body that satisfies the given predicate.
    ///
    /// - parameter predicate: A closure that takes a `Body` and returns a Boolean value indicating whether the body meets the criteria.
    /// - returns: An array of elements whose body matches the specified predicate.
    func withBody(_ predicate: (Body) -> Bool) -> [Element] {
        with(\.body) {
            guard let body = $0 else { return false }
            return predicate(body)
        }
    }

    /// Filters the array to include only elements whose body does not satisfy the given predicate.
    ///
    /// - parameter predicate: A closure that takes a `Body` and returns a Boolean value indicating whether the body meets the criteria.
    /// - returns: An array of elements whose body does not match the specified predicate.
    func withoutBody(_ predicate: (Body) -> Bool) -> [Element] {
        withBody { !predicate($0) }
    }

    /// Filters the array to include only elements whose body contains assignments that satisfy the given predicate.
    ///
    /// - parameter predicate: A closure that takes an array of ``InfixExpression`` objects and returns a Boolean value indicating whether the assignments meet the criteria.
    /// - returns: An array of elements whose assignments match the specified predicate.
    func withAssignments(_ predicate: ([InfixExpression]) -> Bool) -> [Element] {
        with(\.body) {
            guard let body = $0 else { return false }
            return predicate(body.infixExpressions.filter(\.isAssignment))
        }
    }

    /// Filters the array to include only elements whose body contains assignments that do not satisfy the given predicate.
    ///
    /// - parameter predicate: A closure that takes an array of ``InfixExpression`` objects and returns a Boolean value indicating whether the assignments meet the criteria.
    /// - returns: An array of elements whose assignments do not match the specified predicate.
    func withoutAssignments(_ predicate: ([InfixExpression]) -> Bool) -> [Element] {
        withAssignments { !predicate($0) }
    }

    /// Filters the array to include only elements whose body contains function calls that satisfy the given predicate.
    ///
    /// - parameter predicate: A closure that takes an array of `FunctionCall` objects and returns a Boolean value indicating whether the function calls meet the criteria.
    /// - returns: An array of elements whose function calls match the specified predicate.
    func withFunctionCalls(_ predicate: ([FunctionCall]) -> Bool) -> [Element] {
        with(\.body) {
            guard let body = $0 else { return false }
            return predicate(body.functionCalls)
        }
    }

    /// Filters the array to include only elements whose body contains function calls that do not satisfy the given predicate.
    ///
    /// - parameter predicate: A closure that takes an array of `FunctionCall` objects and returns a Boolean value indicating whether the function calls meet the criteria.
    /// - returns: An array of elements whose function calls do not match the specified predicate.
    func withoutFunctionCalls(_ predicate: ([FunctionCall]) -> Bool) -> [Element] {
        withFunctionCalls { !predicate($0) }
    }

    /// Filters the array to include only elements whose body contains if statements that satisfy the given predicate.
    ///
    /// - parameter predicate: A closure that takes an array of `If` objects and returns a Boolean value indicating whether the if statements meet the criteria.
    /// - returns: An array of elements whose if statements match the specified predicate.
    func withIfs(_ predicate: ([If]) -> Bool) -> [Element] {
        with(\.body) {
            guard let body = $0 else { return false }
            return predicate(body.ifs)
        }
    }

    /// Filters the array to include only elements whose body contains if statements that do not satisfy the given predicate.
    ///
    /// - parameter predicate: A closure that takes an array of `If` objects and returns a Boolean value indicating whether the if statements meet the criteria.
    /// - returns: An array of elements whose if statements do not match the specified predicate.
    func withoutIfs(_ predicate: ([If]) -> Bool) -> [Element] {
        withIfs { !predicate($0) }
    }

    /// Filters the array to include only elements whose body contains switches that satisfy the given predicate.
    ///
    /// - parameter predicate: A closure that takes an array of `Switch` objects and returns a Boolean value indicating whether the switches meet the criteria.
    /// - returns: An array of elements whose switches match the specified predicate.
    func withSwitches(_ predicate: ([Switch]) -> Bool) -> [Element] {
        with(\.body) {
            guard let body = $0 else { return false }
            return predicate(body.switches)
        }
    }

    /// Filters the array to include only elements whose body contains switches that do not satisfy the given predicate.
    ///
    /// - parameter predicate: A closure that takes an array of `Switch` objects and returns a Boolean value indicating whether the switches meet the criteria.
    /// - returns: An array of elements whose switches do not match the specified predicate.
    func withoutSwitches(_ predicate: ([Switch]) -> Bool) -> [Element] {
        withSwitches { !predicate($0) }
    }
    
    /// Filters the array to include only elements with a body that satisfies the given predicate.
    ///
    /// - parameter predicate: A closure that takes a `String` representing the body of the element and returns
    ///   a Boolean value indicating whether the body meets the criteria.
    /// - returns: An array of elements whose body matches the specified predicate.
    func withBodyContent(_ predicate: (String) -> Bool) -> [Element] {
        with(\.body) {
            guard let body = $0 else { return false }
            return predicate(body.content)
        }
    }

    /// Filters the array to include only elements with a body that satisfies the given predicate.
    ///
    /// - parameter predicate: A closure that takes a `[String]` representing the body of the element and returns
    ///   a Boolean value indicating whether the body meets the criteria.
    /// - returns: An array of elements whose body matches the specified predicate.
    func withStatements(_ predicate: ([String]) -> Bool) -> [Element] {
        with(\.body) {
            guard let body = $0 else { return false }
            return predicate(body.statements.map(\.description))
        }
    }

    /// Filters the array to include only elements with a body that contains the specified regex pattern.
    ///
    /// - parameter regex: A regex pattern to match against the body of the element.
    /// - returns: An array of elements whose body contains the specified regex pattern.
    @available(iOS 16.0, macOS 13.0, *)
    func withBodyContent(containing regex: some RegexComponent) -> [Element] {
        withBodyContent { $0.contains(regex) }
    }
    
    /// Filters the array to include only elements with a body that contains the specified regex pattern.
    /// May return empty if regex pattern isn't valid.
    ///
    /// - parameter regex: A regex pattern to match against the body of the element.
    /// - returns: An array of elements whose body contains the specified regex pattern.
    func withBodyContent(containing regex: String) -> [Element] {
        withBodyContent {
            let range = NSRange(location: 0, length: $0.utf16.count)
            let regex = try? NSRegularExpression(pattern: regex)
            return regex?.firstMatch(in: $0, options: [], range: range) != nil
        }
    }
    
    /// Filters the array to include only elements without a body that satisfies the given predicate.
    ///
    /// - parameter predicate: A closure that takes a `String` representing the body of the element and returns
    ///   a Boolean value indicating whether the body meets the criteria.
    /// - returns: An array of elements whose body does not match the specified predicate.
    func withoutBodyContent(_ predicate: (String) -> Bool) -> [Element] {
        withBodyContent { !predicate($0) }
    }
}
