//
//  String+LogicalOperators.swift
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

public extension String {
    /// Combines two `String` values into an array of `String` using the `||` operator.
    static func ||(lhs: String, rhs: String) -> [String] {
        [lhs, rhs]
    }
}

public extension Array where Element == String {
    /// Appends a `String` value to an array of `String` elements using the `||` operator.
    static func ||(lhs: [String], rhs: String) -> [String] {
        lhs + [rhs]
    }
}
