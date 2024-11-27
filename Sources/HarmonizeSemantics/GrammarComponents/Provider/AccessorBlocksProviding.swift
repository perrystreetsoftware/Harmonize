//
//  AccessorBlocksProviding.swift
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

/// A protocol that provides access to accessor blocks, such as `get` and `set` blocks.
public protocol AccessorBlocksProviding {
    /// A collection of accessor blocks, such as `get`, `set`, `willSet`, or `didSet`.
    var accessors: [AccessorBlock] { get }
    
    /// The getter block of this variable if this is a computed property.
    var getter: GetterBlock? { get }
}

// MARK: - Accessor Existence Checks

public extension AccessorBlocksProviding {
    /// Checks if the accessors contain a `get` block.
    func hasGetAccessor() -> Bool {
        return accessors.contains { $0.modifier == .get }
    }
    
    /// Checks if the accessors contain a `set` block.
    func hasSetAccessor() -> Bool {
        return accessors.contains { $0.modifier == .set }
    }

    /// Checks if the accessors contain a `willSet` block.
    func hasWillSetAccessor() -> Bool {
        return accessors.contains { $0.modifier == .willSet }
    }
    
    /// Checks if the accessors contain a `didSet` block.
    func hasDidSetAccessor() -> Bool {
        return accessors.contains { $0.modifier == .didSet }
    }

    /// Checks if the element has any accessor blocks.
    func hasAnyAccessor() -> Bool {
        return !accessors.isEmpty
    }
    
    /// Checks if the element has a getter block (indicating a computed property).
    func hasGetterBlock() -> Bool {
        return getter != nil
    }
}
