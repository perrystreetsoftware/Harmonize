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
        body?.infixExpressions.filter(\.isAssignment)
            .contains { $0.leftOperand.contains(variableName) } ?? false
    }

    /// Retrieves all assignments to the specified variable name.
    ///
    /// - Parameter variableName: The name of the variable.
    /// - Returns: An array of assignments to the specified variable, or an empty array if none exist.
    public func assignments(to variableName: String) -> [InfixExpression] {
        body?.infixExpressions.filter(\.isAssignment)
            .filter { $0.leftOperand == variableName } ?? []
    }

    /// Checks if the body contains any assignments.
    ///
    /// - Returns: `true` if the body contains assignments, otherwise `false`.
    public func hasAssignments() -> Bool {
        body?.infixExpressions.filter(\.isAssignment).isEmpty == false
    }

    // - MARK: Common Checks

    /// Checks if the body contains any `if` statements.
    ///
    /// - Returns: `true` if the body contains `if` statements, otherwise `false`.
    public func hasIfs() -> Bool {
        body?.ifs.isEmpty == false
    }

    /// Retrieves all `if` statements in the body.
    ///
    /// - Returns: An array of ``If`` objects representing all `if` statements, or an empty array if none exist.
    public func ifs() -> [If] {
        body?.ifs ?? []
    }

    /// Checks if the body contains any `switch` statements.
    ///
    /// - Returns: `true` if the body contains `switch` statements, otherwise `false`.
    public func hasSwitches() -> Bool {
        body?.switches.isEmpty == false
    }

    /// Retrieves all `switch` statements in the body.
    ///
    /// - Returns: An array of `Switch` objects representing all `switch` statements, or an empty array if none exist.
    public func switches() -> [Switch] {
        body?.switches ?? []
    }

    /// Retrieves all `guard` statements in the body.
    ///
    /// - Returns: An array of `Guard` objects representing all `guard` statements, or an empty array if none exist.
    public func guards() -> [Guard] {
        body?.guards ?? []
    }

    /// Retrieves all closure statements in this body.
    ///
    /// - Returns: An array of `Closure` objects representing all `switch` statements, or an empty array if none exist.
    public func closures() -> [Closure] {
        body?.closures ?? []
    }

    /// Checks if the body is empty.
    ///
    /// - Returns: `true` if the body is empty, otherwise `false`.
    public func isEmptyBody() -> Bool {
        return body?.description.isEmpty ?? true
    }

    /// Checks if any statement in this body is a self reference
    /// This doesn't necessarily means that this body is having a self reference within a closure since this could be a simple reference in a function call.
    ///
    /// - Returns: A boolean value indicating whether any of the statement in this body has a self reference.
    public var refersToSelf: Bool {
        return body?.hasAnySelfReference ?? false
    }

    /// Checks if any closure in this body has a self reference.
    ///
    /// - Returns: A boolean value indicating whether any of the statement in this body has a self reference.
    public var hasAnyClosureWithSelfReference: Bool {
        return body?.hasAnyClosureWithSelfReference ?? false
    }

    public func hasAnyClosureWithSelfReference(ignoreKnownNonEscapingFunctionCalls: Bool) -> Bool {
        let nonEscapingFunctionCalls = {
            if (ignoreKnownNonEscapingFunctionCalls) {
                return FunctionCall.NonEscapingFunctionCalls
            } else {
                return []
            }
        }()

        return body?.hasAnyClosureWithSelfReference(nonEscapingFunctionCalls: nonEscapingFunctionCalls) ?? false
    }
}
