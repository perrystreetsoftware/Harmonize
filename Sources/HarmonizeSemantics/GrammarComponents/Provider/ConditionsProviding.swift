//
//  ConditionsProviding.swift
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

/// A protocol that represents declarations capable of providing an array of conditions.
public protocol ConditionsProviding {
    var conditions: [Condition] { get }
}

public extension ConditionsProviding {
    /// A boolean that indicates if there is a optional binding to self in this statement.
    ///
    /// Commonly used in `guard let self` to hold a strong reference to self
    /// in which can be combined with `weak self` capturing in a ``Closure``.
    var isBindingToSelf: Bool {
        conditions.contains(where: \.isBindingToSelf)
    }
}
