//
//  AttributesProviding.swift
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

/// A protocol that provides access to the attributes of a declaration.
public protocol AttributesProviding {
    /// A collection of all attributes associated with this declaration.
    var attributes: [Attribute] { get }
}

// MARK: - Checks

public extension AttributesProviding {
    /// Retrieves the attribute with the specified name if it exists.
    ///
    /// - parameter name: The name of the attribute to retrieve, with or without the `@` symbol.
    /// - returns: The attribute with the specified name, or `nil` if no such attribute exists.
    func attribute(named name: String) -> Attribute? {
        attributes.first { $0.name == name.replacingOccurrences(of: "@", with: "") }
    }
    
    /// Retrieves the attribute with the specified name if it exists.
    ///
    /// - parameter annotation: The annotation of the attribute to retrieve.
    /// - returns: The attribute with the specified annotation, or `nil` if no such attribute exists.
    func attribute(annotatedWith annotation: Attribute.Annotation) -> Attribute? {
        attributes.first { $0.annotation == annotation }
    }
    
    /// Filters the attributes to return only those that match the specified annotation.
    ///
    /// - Parameter annotation: The annotation to filter by.
    /// - Returns: An array of attributes that match the specified annotation.
    func attributes(annotatedWith annotation: Attribute.Annotation) -> [Attribute] {
        return attributes.filter { $0.annotation == annotation }
    }
    
    /// Filters the attributes to return those that have arguments matching a specific predicate.
    ///
    /// - parameter predicate: A closure that takes an `Argument` and returns a Boolean value indicating
    ///   whether the argument satisfies the condition.
    /// - returns: An array of attributes whose arguments match the given predicate.
    func attributes(withArgumentMatching predicate: (Attribute.Argument) -> Bool) -> [Attribute] {
        attributes.filter { attribute in attribute.arguments.contains(where: predicate) }
    }
    
    /// Checks if the declaration has an attribute with the given name.
    ///
    /// - parameter name: The name of the attribute to check for, with or without the `@` symbol.
    /// - returns: `true` if the declaration contains an attribute with the specified name, `false` otherwise.
    func hasAttribute(named name: String) -> Bool {
        attribute(named: name) != nil
    }
    
    /// Checks if the declaration has an attribute with the given annotation.
    ///
    /// - parameter annotation: The annotation to check for.
    /// - returns: `true` if the declaration contains an attribute with the specified annotation, `false` otherwise.
    func hasAnnotation(_ annotation: Attribute.Annotation) -> Bool {
        attribute(annotatedWith: annotation) != nil
    }

    /// Checks if any attribute contains an argument matching a specific predicate.
    ///
    /// - parameter predicate: A closure that takes an `Argument` and returns a Boolean value indicating
    ///   whether the argument satisfies the condition.
    /// - returns: `true` if any attribute contains an argument that matches the predicate, `false` otherwise.
    func hasAttributeArgument(matching predicate: (Attribute.Argument) -> Bool) -> Bool {
        attributes.contains { attribute in attribute.arguments.contains(where: predicate) }
    }
    
    /// Checks if the declaration contains all of the specified attributes by name.
    ///
    /// - parameter names: An array of attribute names to check for.
    /// - returns: `true` if the declaration contains all the specified attributes, `false` otherwise.
    func hasAttributes(named names: [String]) -> Bool {
        names.allSatisfy { attribute(named: $0) != nil }
    }
    
    /// Checks if the declaration contains any of the specified attributes by name.
    ///
    /// - parameter names: An array of attribute names to check for.
    /// - returns: `true` if the declaration contains any of the specified attributes, `false` otherwise.
    func hasAnyAttribute(named names: [String]) -> Bool {
        names.contains { attribute(named: $0) != nil }
    }
}
