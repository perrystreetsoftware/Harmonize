//
//  DeclarationsProviding.swift
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

/// A protocol that provides declarations found within a declaration.
public protocol DeclarationsProviding {
    /// A collection of ``Declaration`` objects representing the declarations
    /// contained in this declaration.
    ///
    /// The `declarations` property provides access to the collection of declarations
    /// (such as classes, functions, etc.) that have been found in this declaration.
    var declarations: [Declaration] { get }
}
