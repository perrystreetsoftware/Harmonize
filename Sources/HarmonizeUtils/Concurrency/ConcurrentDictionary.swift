//
//  ConcurrentDictionary.swift
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

/// A thread-safe, generic dictionary that allows concurrent read and write operations.
///
/// The dictionary uses a `DispatchQueue` with a barrier for writes, ensuring that data
/// integrity is maintained during concurrent access.
///
package final class ConcurrentDictionary<Key: Hashable, Value> {
    private var elements: [Key: Value] = [:]
    private let queue = DispatchQueue(label: "harmonize.concurrentdic.queue", attributes: .concurrent)
    
    public init() {}
    
    /// Accesses the value associated with the given key.
    ///
    /// - parameter key: The key to look up in the dictionary.
    /// - returns: The value associated with the key, or nil if value is not present.
    public subscript(key: Key) -> Value? {
        get { getValue(key: key) }
        set { setValue(key: key, value: newValue) }
    }
    
    // Removes the given key and its value from the dictionary.
    public func removeValue(forKey key: Key) -> Value? {
        return queue.sync {
            elements.removeValue(forKey: key)
        }
    }
    
    // Removes all elements from the dictionary.
    public func removeAll() {
        queue.async(flags: .barrier) {
            self.elements.removeAll()
        }
    }
    
    private func getValue(key: Key) -> Value? {
        queue.sync {
            elements[key]
        }
    }
    
    private func setValue(key: Key, value: Value?) {
        queue.async(flags: .barrier) {
            self.elements[key] = value
        }
    }
}
