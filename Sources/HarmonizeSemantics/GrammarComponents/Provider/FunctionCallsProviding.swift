//
//  FunctionCallsProviding.swift
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

/// A protocol that represents declarations capable of providing a collection of invoked functions on its body.
public protocol FunctionCallsProviding {
    /// The list of function calls happening in this function, including calls from nested functions or closures.
    ///
    /// Given this function:
    ///
    /// ```swift
    /// func sampleCode() {
    ///     closure {
    ///         functionCall()
    ///     }
    ///
    ///     functionCall()
    /// }
    /// ```
    ///
    /// calling this will return: `["closure", "functionCall", "functionCall"]`.
    var functionCalls: [FunctionCall] { get }
}

public extension FunctionCallsProviding {
    /// Checks if any of the function calls matches a list of specified function names ignoring arguments and ().
    ///
    /// - Parameter functions: An array of function names to check.
    /// - Returns: A Boolean value indicating whether any of the functions in the list have been invoked.
    func invokes(_ functions: [String]) -> Bool {
        return functionCalls.contains(where: {
            functions.contains($0.call)
        })
    }

    /// Checks if a specific function name has been invoked.
    ///
    /// - Parameter function: The name of the function to check.
    /// - Returns: A Boolean value indicating whether the specified function has been invoked.
    func invokes(_ function: String) -> Bool {
        return invokes([function])
    }

    /// Checks if any function call satisfies a given predicate.
    ///
    /// - Parameter predicate: A closure that takes a `FunctionCall` object and returns a Boolean value.
    /// - Returns: A Boolean value indicating whether any function call satisfies the given predicate.
    func invokes(where predicate: (FunctionCall) -> Bool) -> Bool {
        return functionCalls.contains(where: predicate)
    }
}
