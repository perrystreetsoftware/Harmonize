//
//  SyntaxProtocol+ResolveParent.swift
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

import SwiftSyntax

internal extension SyntaxProtocol {
    /// Recursively searches for the first parent of the given type `T`.
    /// - Parameter type: The type of the parent to search for.
    /// - Returns: The parent of type `T` if found, otherwise `nil`.
    func parentAs<T: SyntaxProtocol>(_ type: T.Type) -> T? {
        var currentParent = self.parent
        
        while let parent = currentParent {
            if let matchedParent = parent as? T {
                return matchedParent
            }
            
            currentParent = parent.parent
        }
        
        return nil
    }
}
