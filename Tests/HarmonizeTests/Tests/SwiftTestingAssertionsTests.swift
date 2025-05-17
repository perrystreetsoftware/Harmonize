//
//  Assertions.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

#if canImport(Testing)

import Foundation
import Harmonize
import HarmonizeSemantics
import Testing

@Suite(.serialized) struct SwiftTestingSourceFileAssertionsTests {
    @Test func assertThatAssertTruePasses() {
        Harmonize.on("Fixtures/SwiftTesting")
            .functions()
            .assertTrue { $0.name.starts(with: "on") }
    }
    
    @Test func assertThatAssertTrueFails() {
        withKnownIssue {
            Harmonize.on("Fixtures/SwiftTesting")
                .functions()
                .assertTrue { !$0.name.starts(with: "on") }
        }
    }
    
    @Test func assertThatAssertFalsePasses() {
        Harmonize.on("Fixtures/SwiftTesting")
            .functions()
            .assertFalse { $0.name.endsWith("on") }
    }
    
    @Test func assertThatAssertFalseFails() {
        withKnownIssue {
            Harmonize.on("Fixtures/SwiftTesting")
                .functions()
                .assertFalse { $0.name.starts(with: "on") }
        }
    }
    
    @Test func assertThatAssertEmptyPasses() {
        Harmonize.on("Fixtures/SwiftTesting")
            .functions()
            .withNameEndingWith("on")
            .assertEmpty()
    }
    
    @Test func assertThatAssertEmptyFails() {
        withKnownIssue {
            Harmonize.on("Fixtures/SwiftTesting")
                .functions()
                .withNameStartingWith("on")
                .assertEmpty()
        }
    }
    
    @Test func assertThatAssertNotEmptyPasses() {
        Harmonize.on("Fixtures/SwiftTesting")
            .functions()
            .withNameStartingWith("on")
            .assertNotEmpty()
    }
    
    @Test func assertThatAssertNotEmptyFails() {
        withKnownIssue {
            Harmonize.on("Fixtures/SwiftTesting")
                .functions()
                .withNameEndingWith("on")
                .assertNotEmpty()
        }
    }
}

#endif
