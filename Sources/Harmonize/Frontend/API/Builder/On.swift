//
//  On.swift
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

/// Builder protocol to provide the functionality to lookup for especific paths/folders/packages into the working directory.
public protocol On: Excluding {
    /// A folder or path builder specifier to target Harmonize.
    ///
    /// - parameter folder: the target folder or path name as string.
    /// - returns: the Builder allowing filtering with `excluding` or Harmonize scope.
    ///
    /// Calling Harmonize.on("path/to/code") will effectivelly allow the work on the given path that must be a directory of the working directory.
    /// Additionally it is also possible to call Harmonize.on("Folder") and it will act on every directory it finds with the given name.
    ///
    func on(_ folder: String) -> Excluding
}
