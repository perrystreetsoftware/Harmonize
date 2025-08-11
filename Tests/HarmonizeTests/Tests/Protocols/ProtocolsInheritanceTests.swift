//
//  ProtocolsInheritanceTests.swift
//  Harmonize
//
//  Created by Lucas Cavalcante on 8/7/25.
//

import Foundation
import Harmonize
import XCTest

final class ProtocolsConformanceTests: XCTestCase {
    private let protocolsSample = """
    protocol BaseCoordinator {}
    protocol CoordinatorThrows : BaseCoordinator {}
    protocol AnotherProtocol {}
    protocol MultiInheritProtocol : BaseCoordinator, AnotherProtocol {}

    open class FooCoordinator : CoordinatorThrows {}
    final class FooBarCoordinator : BaseCoordinator {}
    final class BarCoordinator : BaseCoordinator {}
    final class MachineCoordinator : FooCoordinator, AnotherProtocol {}
    
    protocol GenericCoordinator: AnyObject {
        associatedtype Destination
        associatedtype Route: Hashable
        
        func start()
        func navigate(to route: Route) -> Destination
    }
    
    class ItemNavigator<Item: Hashable, DetailView: UIViewController>: GenericCoordinator {
        // ...
    }
    """

    func testDirectProtocolInheritance() throws {
        Harmonize.on { protocolsSample }
            .protocols()
            .withoutName(["BaseCoordinator", "GenericCoordinator"])
            .withNameContaining("Coordinator")
            .assertTrue {
                $0.inherits(from: "BaseCoordinator")
            }
    }

    func testTransitiveInheritance() throws {
        Harmonize.on { protocolsSample }
            .classes()
            .withNameContaining("Coordinator")
            .assertTrue { $0.inherits(from: "BaseCoordinator") }
    }

    func testClassesDirectInheritance() throws {
        Harmonize.on { protocolsSample }
            .classes()
            .inheriting(from: "CoordinatorThrows")
            .assertTrue { $0.name == "FooCoordinator" }
    }

    func testMultiAndTransitiveInheritance() throws {
        Harmonize.on { protocolsSample }
            .classes()
            .inheriting(from: "AnotherProtocol")
            .assertTrue { $0.inherits(from: "BaseCoordinator") }
    }

    func testNonTransitiveInheritance() throws {
        Harmonize.on { protocolsSample }
            .classes()
            .inheriting(from: "AnotherProtocol")
            .assertFalse { $0.inherits(from: "BaseCoordinator", includeTransitiveInheritance: false)}
    }

    func testConformance() {
        Harmonize.on { protocolsSample }
            .classes()
            .inheriting(from: "AnotherProtocol")
            .assertTrue { $0.conforms(to: "BaseCoordinator") }
    }
    
    func testGenericCoordinator() {
        Harmonize.on { protocolsSample }
            .classes()
            .withNameEndingWith("ItemNavigator")
            .assertTrue { $0.conforms(to: "GenericCoordinator") }
    }
    
    func testConformanceFilters() {
        let protos = Harmonize.on { protocolsSample }
            .protocols()
            .withoutName(["BaseCoordinator", "GenericCoordinator"])
            .inheriting(from: "BaseCoordinator")
            .map(\.name)
        
        XCTAssertEqual(protos, ["CoordinatorThrows", "MultiInheritProtocol"])
        
        let classes = Harmonize.on { protocolsSample }
            .classes()
            .withoutName(["BaseCoordinator", "GenericCoordinator"])
            .inheriting(from: "BaseCoordinator")
            .map(\.name)
        
        XCTAssertEqual(classes, ["FooCoordinator", "FooBarCoordinator", "BarCoordinator", "MachineCoordinator"])
    }
}
