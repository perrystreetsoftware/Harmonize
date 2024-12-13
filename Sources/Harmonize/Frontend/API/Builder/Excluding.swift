//
//  Excluding.swift
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

/// Builder protocol to provide the functionality to exclude especific paths/folders/files from the Harmonize Scope.
public protocol Excluding: HarmonizeScope {
    /// The `excluding` builder method to filter out Files/Folders from the Harmonize Scope.
    /// Note that if you pass a string with a trailing `*` it will treat it as a wildcard against the filename
    ///
    /// - Parameter excludes: files, paths or folders to be excluded.
    /// - Returns: ``HarmonizeScope``.
    func excluding(_ excludes: String...) -> HarmonizeScope

    /// The `excluding` builder method to filter out Files/Folders from the Harmonize Scope.
    /// Note that if you pass a string with a trailing `*` it will treat it as a wildcard against the filename
    ///
    /// - Parameter excludes: files, paths or folders to be excluded.
    /// - Returns: ``HarmonizeScope``.
    func excluding(_ excludes: [String]) -> HarmonizeScope
}
