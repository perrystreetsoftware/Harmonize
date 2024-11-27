//
//  Array+ProtocolsProviding.swift
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

/// An extension for arrays where the elements conform to both `Declaration` and `ProtocolsProviding`,
/// providing filtering functionality based on protocols.
public extension Array where Element: Declaration & ProtocolsProviding {
    /// Returns an array of elements that conform to protocols satisfying the specified predicate.
    ///
    /// - parameter predicate: A closure that takes a `ProtocolDeclaration` and returns a Boolean value
    ///   indicating whether the protocol should be included in the result.
    /// - returns: An array of elements that conform to protocols satisfying the predicate.
    func withProtocols(_ predicate: (ProtocolDeclaration) -> Bool) -> [Element] {
        with(\.protocols) { $0.contains(where: predicate) }
    }
    
    /// Flattens the protocols from all elements in the array into a single array.
    ///
    /// - returns: An array of all protocols from the elements in the array.
    func protocols() -> [ProtocolDeclaration] {
        flatMap { $0.protocols }
    }
}
