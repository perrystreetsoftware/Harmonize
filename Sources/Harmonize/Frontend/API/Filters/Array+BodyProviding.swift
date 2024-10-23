//
//  Array+BodyProviding.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import HarmonizeSemantics

/// An extension for arrays where the elements conform to both `Declaration` and `BodyProviding`,
/// providing filtering functionality based on body.
public extension Array where Element: Declaration & BodyProviding {
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
            return predicate(body.statements)
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
