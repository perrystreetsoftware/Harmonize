//
//  ActorsTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2026. All Rights Reserved.
//

import Foundation
import Harmonize
import HarmonizeSemantics
import XCTest

final class ActorsTests: XCTestCase {
    private let scope = Harmonize.productionCode().on("Fixtures/Filters/Actors")

    func testResolvesActors() throws {
        XCTAssertEqual(
            scope.actors().map { $0.name },
            ["AccountService", "SessionCache", "Metrics", "RemoteService", "Inner"]
        )
    }

    func testFiltersActorsByName() throws {
        scope.actors()
            .withNameEndingWith("Service")
            .assertCount(count: 2)

        scope.actors()
            .withoutSuffix("Service")
            .assertCount(count: 3)
    }

    func testFiltersActorsByConformance() throws {
        scope.actors()
            .conforming(to: "Service")
            .assertCount(count: 1)
    }

    func testFiltersActorsByModifier() throws {
        scope.actors()
            .withModifier(.distributed)
            .assertCount(count: 1)
    }

    func testAssertsOnActorMembers() throws {
        scope.actors()
            .withName("AccountService")
            .assertTrue(message: "Actors must keep their state private", strict: true) {
                $0.variables.allSatisfy { $0.modifiers.contains(.private) }
            }
    }

    func testResolvesActorsNestedInActors() throws {
        let sessionCache = scope.actors().first { $0.name == "SessionCache" }

        XCTAssertEqual(sessionCache?.actors.map { $0.name }, ["Metrics"])
    }

    func testResolvesActorsNestedInClasses() throws {
        let container = scope.classes().first { $0.name == "Container" }

        XCTAssertEqual(container?.actors.map { $0.name }, ["Inner"])
    }

    func testResolvesActorsFromSources() throws {
        XCTAssertEqual(scope.sources().actors().count, 5)
    }

    // MARK: - Regression: actor members must not leak into the enclosing scope

    func testActorMembersAreNotReportedAsParentless() throws {
        let parentlessFunctions = scope.functions(includeNested: true)
            .filter { $0.parent == nil }

        XCTAssertEqual(parentlessFunctions, [])
    }

    func testActorMembersAreNotFlattenedIntoTheirEnclosingClass() throws {
        let container = scope.classes().first { $0.name == "Container" }

        XCTAssertEqual(container?.functions.map { $0.name }, [])
    }
}
