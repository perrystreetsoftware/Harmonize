//
//  Array+SourceCodeProviding.swift
//  Harmonize
//
//  Copyright 2025 Perry Street Software Inc.

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
import SwiftSyntax

/// An extension for arrays where the elements conform to both `SourceCodeProviding`,
/// providing filtering functionality based on type.
public extension Array where Element: SourceCodeProviding {
    /// Filters the array to include only elements whose file path's last path component satisfies the given predicate.
    ///
    /// - parameter predicate: A closure that takes a filename and returns a Boolean value indicating whether the element should be included.
    /// - returns: An array containing the elements whose filename satisfies the given predicate.
    func withLastPathComponent(_ predicate: (String) -> Bool) -> [Element] {
        filter { predicate($0.sourceCodeLocation.sourceFilePath!.lastPathComponent) }
    }

    /// Filters the array to include only elements whose file path's last path component is in the given filenames.
    ///
    /// - parameter names: An array of filenames to match against.
    /// - returns: An array containing the elements whose filename is in the given array.
    func withLastPathComponent(_ names: [String]) -> [Element] {
        withLastPathComponent(names.contains)
    }

    /// Filters the array to include only elements whose file path's last path component matches the given filename.
    ///
    /// - parameter name: The filename to match against.
    /// - returns: An array containing the elements whose filename matches the given name.
    func withLastPathComponent(_ name: String) -> [Element] {
        withLastPathComponent([name])
    }

    /// Filters the array to exclude elements whose file path's last path component satisfies the given predicate.
    ///
    /// - parameter predicate: A closure that takes a filename and returns a Boolean value indicating whether the element should be excluded.
    /// - returns: An array containing the elements whose filename does not satisfy the given predicate.
    func withoutLastPathComponent(_ predicate: (String) -> Bool) -> [Element] {
        filter { !predicate($0.sourceCodeLocation.sourceFilePath!.lastPathComponent) }
    }

    /// Filters the array to exclude elements whose file path's last path component is in the given filenames.
    ///
    /// - parameter names: An array of filenames to exclude.
    /// - returns: An array containing the elements whose filename is not in the given array.
    func withoutLastPathComponent(_ names: [String]) -> [Element] {
        withoutLastPathComponent(names.contains)
    }
}
