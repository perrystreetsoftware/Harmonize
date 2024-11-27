//
//  TypeProviding.swift
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

/// A protocol that represents declarations capable of providing a type annotation.
public protocol TypeProviding {
    /// The type annotation of the declaration, if any.
    ///
    /// This property returns an optional `TypeAnnotation`, representing the type of the declaration.
    /// For example, in the declaration `let number: Int`, the `typeAnnotation` is`Int`.
    /// If the declaration doesn't specify a type, this property returns `nil`.
    var typeAnnotation: TypeAnnotation? { get }
}
