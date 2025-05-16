//
//  Assertions.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import Harmonize
import HarmonizeSemantics
import Testing

private let sample = Harmonize.on {
    """
    func test() {}
    """
}

@Suite struct SwiftTestingAssertionsTests {
    @Test func thenExpectAllPasses() {
        sample.functions()
            .expectAll { function in function.name == "test" }
    }

    @Test func thenExpectAllFail() {
        withKnownIssue {
            sample.functions()
                .expectAll { function in function.name == "test2" }
        }
        
        #expect(true)
    }

    @Test func expectNoneToPass() {
        sample.functions()
            .expectNone { function in function.name == "test2" }
    }

    @Test func expectNoneToFail() {
        withKnownIssue {
            sample.functions()
                .expectNone { function in function.name == "test" }
        }
        
        #expect(true)
    }

    @Test func expectEmptyToPass() {
        sample.functions()
            .filter { $0.name == "test2" }
            .expectEmpty()
    }

    @Test func expectEmptyToFail() {
        withKnownIssue {
            sample.functions().expectEmpty()
        }
        
        #expect(true)
    }

    @Test func expectNotEmptyToPass() {
        sample.functions().expectNotEmpty()
    }

    @Test func expectNotEmptyToFail() {
        withKnownIssue {
            [Class]().expectNotEmpty()
        }
        
        #expect(true)
    }

}
