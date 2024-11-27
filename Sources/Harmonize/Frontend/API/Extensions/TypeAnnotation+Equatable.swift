//
//  TypeAnnotation+Equatable.swift
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

import HarmonizeSemantics

public extension TypeAnnotation {
    /// Compares a `TypeAnnotation` instance with a given type to check for equality.
    ///
    /// This operator overload allows for comparing a `TypeAnnotation` directly with a type.
    /// It checks if the annotation string representation of the `TypeAnnotation` is equal
    /// to the string representation of the type.
    ///
    /// - parameters:
    ///   - lhs: The `TypeAnnotation` instance on the left side of the equality operator.
    ///   - rhs: The type to compare against, which can be any type `T`.
    /// - returns: A Boolean value indicating whether the `TypeAnnotation`'s annotation
    ///   matches the string representation of the type.
    static func == <T>(lhs: TypeAnnotation, rhs: T.Type) -> Bool {
        lhs.annotation == String(describing: rhs.self)
    }
}
