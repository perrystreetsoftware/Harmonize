//
//  Array+FunctionCallsProviding.swift
//  Harmonize
//
//  Copyright 2026 Perry Street Software Inc.

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

/// An extension for arrays where elements provide function calls,
/// offering helpers to collect and filter invocation sites.
public extension Array where Element: FunctionCallsProviding {
    /// Retrieves a flat array of all function calls from the elements.
    ///
    /// - returns: A flat array of `FunctionCall` values.
    func functionCalls() -> [FunctionCall] {
        flatMap(\.functionCalls)
    }

    /// Retrieves function call sites whose textual invocation contains the provided regex.
    ///
    /// - parameter regex: A regex pattern to match against each call-site description.
    /// - returns: Matching `FunctionCall` values.
    @available(iOS 16.0, macOS 13.0, *)
    func withFunctionCalls(containing regex: some RegexComponent) -> [FunctionCall] {
        functionCalls().filter { $0.description.contains(regex) }
    }

    /// Retrieves function call sites whose textual invocation matches the provided regex pattern.
    /// May return empty if the regex is invalid.
    ///
    /// - parameter regex: A regex pattern string to match against each call-site description.
    /// - returns: Matching `FunctionCall` values.
    func withFunctionCalls(containing regex: String) -> [FunctionCall] {
        functionCalls().filter {
            let range = NSRange(location: 0, length: $0.description.utf16.count)
            let expression = try? NSRegularExpression(pattern: regex)
            return expression?.firstMatch(in: $0.description, options: [], range: range) != nil
        }
    }
}
