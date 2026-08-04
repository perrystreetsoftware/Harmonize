//
//  RuleContext.swift
//  Harmonize
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

/// Holds the ``Rule`` currently being evaluated so that assertions within its `check` closure
/// don't need to receive it again.
///
/// State is thread local because Swift Testing runs tests in parallel within the same process.
internal enum RuleContext {
    private static let key = "software.perrystreet.harmonize.currentRule"

    internal static var current: Rule? {
        Thread.current.threadDictionary[key] as? Rule
    }

    /// Runs the given closure with `rule` as the current one, restoring the previous afterwards.
    internal static func with<T>(_ rule: Rule, _ body: () throws -> T) rethrows -> T {
        let previous = current
        Thread.current.threadDictionary[key] = rule
        defer { restore(previous) }
        return try body()
    }

    private static func restore(_ rule: Rule?) {
        if let rule {
            Thread.current.threadDictionary[key] = rule
        } else {
            Thread.current.threadDictionary.removeObject(forKey: key)
        }
    }
}
