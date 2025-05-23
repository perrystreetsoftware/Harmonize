//
//  ModifiersProviding.swift
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

/// A protocol that provides access to the modifiers of a declaration.
public protocol ModifiersProviding {
    /// An array of all modifiers applied to the declaration, such as `public`, `private`, `fileprivate`, etc.
    var modifiers: [Modifier] { get }
}

// MARK: - Checkers

public extension ModifiersProviding {
    /// Checks if the declaration has the specified modifiers.
    func hasModifier(_ modifier: Modifier) -> Bool {
        modifiers.contains(modifier)
    }
    
    /// Returns the count of modifiers applied to the declaration.
    func withModifiersCount() -> Int {
        modifiers.count
    }
}
