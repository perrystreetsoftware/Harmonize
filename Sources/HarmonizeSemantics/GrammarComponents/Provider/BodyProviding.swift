//
//  BodyProviding.swift
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

/// A protocol that represents declarations capable of providing a body.
public protocol BodyProviding: FunctionCallsProviding {
    /// The body of the declaration, if any.
    var body: Body? { get }
}

extension BodyProviding {
    public var functionCalls: [FunctionCall] {
        body?.functionCalls ?? []
    }
    
    // MARK: - Checks for Assignments
        
    /// Checks if the body contains an assignment to a variable with the specified name.
    ///
    /// - Parameter variableName: The name of the variable to check for.
    /// - Returns: `true` if the body contains an assignment to the variable, otherwise `false`.
    public func assigns(to variableName: String) -> Bool {
        body?.assignments.contains { $0.target == variableName } ?? false
    }
    
    /// Retrieves all assignments to the specified variable name.
    ///
    /// - Parameter variableName: The name of the variable.
    /// - Returns: An array of assignments to the specified variable, or an empty array if none exist.
    public func assignments(to variableName: String) -> [Assignment] {
        body?.assignments.filter { $0.target == variableName } ?? []
    }
    
    /// Checks if the body contains any assignments.
    ///
    /// - Returns: `true` if the body contains assignments, otherwise `false`.
    public func hasAssignments() -> Bool {
        body?.assignments.isEmpty == false
    }
        
    /// Checks if the body contains any `if` statements.
    ///
    /// - Returns: `true` if the body contains `if` statements, otherwise `false`.
    public func hasIfStatements() -> Bool {
        body?.ifs.isEmpty == false
    }
    
    /// Retrieves all `if` statements in the body.
    ///
    /// - Returns: An array of `If` objects representing all `if` statements, or an empty array if none exist.
    public func ifStatements() -> [If] {
        body?.ifs ?? []
    }
        
    /// Checks if the body contains any `switch` statements.
    ///
    /// - Returns: `true` if the body contains `switch` statements, otherwise `false`.
    public func hasSwitchStatements() -> Bool {
        body?.switches.isEmpty == false
    }
    
    /// Retrieves all `switch` statements in the body.
    ///
    /// - Returns: An array of `Switch` objects representing all `switch` statements, or an empty array if none exist.
    public func switchStatements() -> [Switch] {
        body?.switches ?? []
    }
    
    /// Checks if the body is empty (contains no statements, assignments, or function calls).
    ///
    /// - Returns: `true` if the body is empty, otherwise `false`.
    public func isEmptyBody() -> Bool {
        let isEmpty = body?.statements.isEmpty ?? true
        let hasNoAssignments = body?.assignments.isEmpty ?? true
        let hasNoFunctionCalls = body?.functionCalls.isEmpty ?? true
        return isEmpty && hasNoAssignments && hasNoFunctionCalls
    }
}
