//
//  HarmonizeSkillsError.swift
//  HarmonizeSkillsCore
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

/// A problem that stops the skill generation. The message tells the user what to do.
public struct HarmonizeSkillsError: Error, CustomStringConvertible, Equatable {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var description: String { message }
}

/// The canonical form of an existing path: absolute, with all symbolic links
/// resolved (`/var/x` → `/private/var/x` on macOS). Use it on every path that
/// comes from outside, so that derived paths compare equal.
///
/// Derived paths use the lexical `URL.standardized`, not
/// `standardizedFileURL`. The second one removes the `/private` prefix again.
public func canonicalURL(_ url: URL) -> URL {
    guard let resolved = realpath(url.path, nil) else { return url.absoluteURL.standardized }
    defer { free(resolved) }
    return URL(fileURLWithPath: String(cString: resolved))
}

/// The relative path from `baseDirectory` to `target`, for links inside
/// generated files. Both paths must be canonical (see ``canonicalURL(_:)``).
/// The function does not read the file system, so the paths do not need to exist.
public func relativePath(to target: String, from baseDirectory: URL) -> String {
    let targetComponents = URL(fileURLWithPath: target).standardized.pathComponents
    let baseComponents = baseDirectory.standardized.pathComponents
    var common = 0
    while common < min(targetComponents.count, baseComponents.count),
          targetComponents[common] == baseComponents[common] {
        common += 1
    }
    let ups = Array(repeating: "..", count: baseComponents.count - common)
    return (ups + targetComponents[common...]).joined(separator: "/")
}
