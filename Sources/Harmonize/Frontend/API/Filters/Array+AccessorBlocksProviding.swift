//
//  Array+AccessorBlocksProviding.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import HarmonizeSemantics

/// Extension to filter an array of elements that conform to both `Declaration` and `AccessorBlocksProviding`
/// protocols. This provides a convenient API for filtering declarations based on accessor blocks, getter blocks,
/// and associated bodies or modifiers.
public extension Array where Element: Declaration & AccessorBlocksProviding {

    /// Filters the array by checking if the element contains an `AccessorBlock` that satisfies the provided predicate.
    ///
    /// - parameter predicate: A closure that takes an `AccessorBlock` and returns a Boolean indicating whether
    /// the block satisfies the condition.
    /// - returns: An array of elements whose accessor blocks meet the predicate condition.
    func withAccessorBlock(_ predicate: (AccessorBlock) -> Bool) -> [Element] {
        with(\.accessors) { $0.contains(where: predicate) }
    }

    /// Filters the array by checking if the element contains a `GetterBlock` that satisfies the provided predicate.
    ///
    /// - parameter predicate: A closure that takes a `GetterBlock` and returns a Boolean indicating whether
    /// the getter block satisfies the condition.
    /// - returns: An array of elements whose getter blocks meet the predicate condition.
    func withGetterBlock(_ predicate: (GetterBlock) -> Bool) -> [Element] {
        with(\.getter) {
            guard let getter = $0 else { return false }
            return predicate(getter)
        }
    }

    /// Filters the array by checking if an `AccessorBlock` with the specified modifier contains a body that satisfies the predicate.
    ///
    /// - parameters:
    ///   - accessorModifier: The specific modifier (e.g., `.get`, `.set`) to filter the accessor blocks by.
    ///   - predicate: A closure that takes the body (optional `String`) of the accessor block and returns a Boolean
    ///   indicating whether the body satisfies the condition.
    /// - returns: An array of elements whose accessor blocks have the specified modifier and meet the body condition.
    func withBody(
        from accessorModifier: AccessorBlock.Modifier,
        predicate: (String?) -> Bool
    ) -> [Element] {
        withAccessorBlock {
            $0.modifier == accessorModifier ? predicate($0.body?.content) : false
        }
    }

    /// Filters the array by checking if an `AccessorBlock` has the specified modifier.
    ///
    /// - parameter accessorModifier: The specific modifier to filter the accessor blocks by.
    /// - returns: An array of elements whose accessor blocks match the specified modifier.
    func withAccessorBlockBody(_ accessorModifier: AccessorBlock.Modifier) -> [Element] {
        withAccessorBlock { $0.modifier == accessorModifier }
    }

    /// Filters the array by checking if the `GetterBlock`'s body satisfies the provided predicate.
    ///
    /// - parameter predicate: A closure that takes the body (optional `String`) of the getter block and returns a Boolean
    /// indicating whether the body satisfies the condition.
    /// - returns: An array of elements whose getter blocks have a body that meets the predicate condition.
    func withGetter(_ predicate: (String?) -> Bool) -> [Element] {
        withGetterBlock { predicate($0.body?.content) }
    }

    /// Filters the array by checking if the `get` accessor block's body satisfies the provided predicate.
    ///
    /// - parameter predicate: A closure that takes the body (optional `String`) of the `get` accessor block and
    /// returns a Boolean indicating whether the body satisfies the condition.
    /// - returns: An array of elements whose `get` accessor blocks meet the predicate condition.
    func withGet(_ predicate: (String?) -> Bool) -> [Element] {
        withBody(from: .get, predicate: predicate)
    }

    /// Filters the array by checking if the `set` accessor block's body satisfies the provided predicate.
    ///
    /// - parameter predicate: A closure that takes the body (optional `String`) of the `set` accessor block and
    /// returns a Boolean indicating whether the body satisfies the condition.
    /// - returns: An array of elements whose `set` accessor blocks meet the predicate condition.
    func withSet(_ predicate: (String?) -> Bool) -> [Element] {
        withBody(from: .set, predicate: predicate)
    }

    /// Filters the array by checking if the `didSet` accessor block's body satisfies the provided predicate.
    ///
    /// - parameter predicate: A closure that takes the body (optional `String`) of the `didSet` accessor block and
    /// returns a Boolean indicating whether the body satisfies the condition.
    /// - returns: An array of elements whose `didSet` accessor blocks meet the predicate condition.
    func withDidSet(_ predicate: (String?) -> Bool) -> [Element] {
        withBody(from: .didSet, predicate: predicate)
    }

    /// Filters the array by checking if the `willSet` accessor block's body satisfies the provided predicate.
    ///
    /// - parameter predicate: A closure that takes the body (optional `String`) of the `willSet` accessor block and
    /// returns a Boolean indicating whether the body satisfies the condition.
    /// - returns: An array of elements whose `willSet` accessor blocks meet the predicate condition.
    func withWillSet(_ predicate: (String?) -> Bool) -> [Element] {
        withBody(from: .willSet, predicate: predicate)
    }
}
