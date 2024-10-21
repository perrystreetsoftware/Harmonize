//
//  StatementsProviding.swift
//  Harmonize
//
//  Created by Matheus Luz on 10/21/24.
//

/// A protocol that represents declarations capable of providing a body, split by line.
public protocol StatementsProviding {
    /// The statement of the declaration as a `[String]`, if any.
    ///
    /// This property returns an array containing each line of the body of the declaration. For example, in a function:
    ///
    /// ```swift
    /// func greet() {
    ///     print("Hello, World!")
    ///     print("Bye, World!")
    /// }
    /// ```
    /// The `statements` is `["print(\"Hello, World!\")", "print(\"Bye, World!\")"]`. If the declaration does not have a body, this returns `[]`.
    var statements: [String] { get }
}
