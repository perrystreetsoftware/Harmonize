//
//  DeclarationsCacheTests.swift
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

@testable import HarmonizeSemantics
import XCTest

/// Regression tests for the crash in `DeclarationsCache.supertype(of:)`.
final class DeclarationsCacheTests: XCTestCase {
    // MARK: - Circular inheritance

    /// Old code: `supertype(of:)` recurses A -->B -->A -->... until stack overflow.
    /// Fixed code: `visited` set breaks the cycle; the call terminates and returns a value.
    func testSupertypeOfDoesNotCrashOnCircularInheritance() {
        let cache = DeclarationsCache.shared

        // Simulate a circular inheritance graph in the cache:
        //   CycleA_DCTest inherits CycleB_DCTest
        //   CycleB_DCTest inherits CycleA_DCTest
        cache.put(subtype: "CycleA_DCTest", of: "CycleB_DCTest")
        cache.put(subtype: "CycleB_DCTest", of: "CycleA_DCTest")

        // Old code --> infinite recursion → stack overflow --> crash.
        // Fixed code --> `visited` set detects the cycle; the call returns without crashing.
        // The assertion is simply that this line is reached at all.
        _ = cache.supertype(of: "CycleA_DCTest")
    }

    // MARK: - Concurrent access

    /// Old code: reads `typeInheritanceCache` without the lock --> data race.
    /// Reliably detected by the Swift Thread Sanitizer (-sanitize=thread).
    /// Fixed code: takes a snapshot of the cache under the lock --> no data race.
    func testConcurrentReadsAndWritesDoNotCrash() {
        let cache = DeclarationsCache.shared

        // Interleave writes (put) and reads (supertype) across many threads simultaneously.
        // On old code + TSan this reliably triggers the data race and crashes.
        DispatchQueue.concurrentPerform(iterations: 200) { i in
            cache.put(subtype: "Concurrent\(i)_Child_DCTest", of: "Concurrent\(i)_Parent_DCTest")
            _ = cache.supertype(of: "Concurrent\(i)_Child_DCTest")
        }
    }
}
