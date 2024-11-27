//
//  NamedDeclaration.swift
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

/// A protocol that represents a declaration with an associated name.
///
/// Types conforming to `NamedDeclaration` are expected to provide a `name` property that represents
/// the identifier or name of the declaration.
public protocol NamedDeclaration {
    /// The name of the declaration.
    ///
    /// This property holds the name associated with the declaration. For example, in the declaration
    /// `let file = "document.txt"`, `name` is `"file"`.
    var name: String { get }
}
