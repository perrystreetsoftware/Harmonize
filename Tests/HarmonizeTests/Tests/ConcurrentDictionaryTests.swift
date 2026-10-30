//
//  ConcurrentDictionaryTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2026. All Rights Reserved.
//

import Foundation
import XCTest
import HarmonizeUtils

final class ConcurrentDictionaryTests: XCTestCase {
    func testSetAndReplaceAreVisibleToReads() {
        let dictionary = ConcurrentDictionary<String, Int>()

        XCTAssertNil(dictionary["key"])
        dictionary["key"] = 1
        XCTAssertEqual(dictionary["key"], 1)
        dictionary["key"] = 2
        XCTAssertEqual(dictionary["key"], 2)
        dictionary["key"] = nil
        XCTAssertNil(dictionary["key"])
    }

    func testRemoveReturnsThePreviousValue() {
        let dictionary = ConcurrentDictionary<String, Int>()
        dictionary["key"] = 42
        dictionary["other"] = 7

        XCTAssertEqual(dictionary.removeValue(forKey: "key"), 42)
        XCTAssertNil(dictionary["key"])
        XCTAssertNil(dictionary.removeValue(forKey: "key"))
        XCTAssertEqual(dictionary["other"], 7)
    }

    func testRemoveAllClearsAndAllowsReuse() {
        let dictionary = ConcurrentDictionary<Int, Int>()
        for key in 0..<32 {
            dictionary[key] = key
        }

        dictionary.removeAll()
        dictionary.removeAll()

        for key in 0..<32 {
            XCTAssertNil(dictionary[key])
            XCTAssertNil(dictionary.removeValue(forKey: key))
        }
        dictionary[0] = 42
        XCTAssertEqual(dictionary[0], 42)
    }

    func testConcurrentMixedAccessPreservesIndependentKeys() {
        let dictionary = ConcurrentDictionary<Int, Int>()

        DispatchQueue.concurrentPerform(iterations: 256) { key in
            dictionary[key] = key
            XCTAssertEqual(dictionary[key], key)
            dictionary[key] = -key
            XCTAssertEqual(dictionary.removeValue(forKey: key), -key)
            XCTAssertNil(dictionary[key])
            XCTAssertNil(dictionary.removeValue(forKey: key))
        }

        for key in 0..<256 {
            XCTAssertNil(dictionary[key])
        }
    }

    func testConcurrentRemovalsReturnEachValueExactlyOnce() {
        let dictionary = ConcurrentDictionary<Int, Int>()
        for key in 0..<128 {
            dictionary[key] = key
        }
        let resultsLock = NSLock()
        var removalCounts = [Int](repeating: 0, count: 128)

        DispatchQueue.concurrentPerform(iterations: 1024) { iteration in
            let key = iteration % 128
            if let removed = dictionary.removeValue(forKey: key) {
                XCTAssertEqual(removed, key)
                resultsLock.withLock { removalCounts[key] += 1 }
            }
        }

        XCTAssertEqual(removalCounts, [Int](repeating: 1, count: 128))
        for key in 0..<128 {
            XCTAssertNil(dictionary[key])
        }
    }

    func testConcurrentClearWithReadsWritesAndRemovals() {
        let dictionary = ConcurrentDictionary<Int, Int>()

        DispatchQueue.concurrentPerform(iterations: 1024) { iteration in
            let key = (iteration / 4) % 32
            switch iteration % 4 {
            case 0:
                dictionary[key] = key
            case 1:
                if let value = dictionary[key] {
                    XCTAssertEqual(value, key)
                }
            case 2:
                if let value = dictionary.removeValue(forKey: key) {
                    XCTAssertEqual(value, key)
                }
            default:
                dictionary.removeAll()
            }
        }

        dictionary.removeAll()
        for key in 0..<32 {
            XCTAssertNil(dictionary[key])
        }
        dictionary[0] = 42
        XCTAssertEqual(dictionary[0], 42)
    }
}
