//
//  ActorsTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2026. All Rights Reserved.
//

import Foundation
import HarmonizeSemantics
import XCTest
import SwiftSyntax

final class ActorsTests: XCTestCase {
    private var sourceSyntax = """
    @available(iOS 16.0, *)
    public actor RootActor: SomeProtocol, @unchecked Sendable {
        var property: String = "x"
        let y: Int = 0
        
        init(property: String) {
            self.property = property
        }
        
        func foo() {
            let make = 42
        }
        
        private actor NestedActor {
            func bar() {}
        }
    }

    distributed actor Worker {
        distributed func remoteCall() {}
    }

    final class Holder {
        actor Inner {
            func work() {}
        }
    }
    """.parsed()
    
    private lazy var visitor = {
        DeclarationsCollector(
            sourceCodeLocation: SourceCodeLocation(
                sourceFilePath: nil,
                sourceFileTree: sourceSyntax
            )
        )
    }()
    
    override func setUp() {
        visitor.walk(sourceSyntax)
    }
    
    func testParseActorsIncludingNested() throws {
        let actors = visitor.actors
        let actorsNames = actors.map { $0.name }
        
        XCTAssertEqual(actors.count, 4)
        XCTAssertEqual(actorsNames, ["RootActor", "NestedActor", "Worker", "Inner"])
    }
    
    func testParseInheritanceTypesNames() throws {
        let inheritanceTypes = visitor.actors.map { $0.inheritanceTypesNames }
        
        XCTAssertEqual(inheritanceTypes, [["SomeProtocol", "Sendable"], [], [], []])
    }
    
    func testParseActorsVariables() throws {
        let variables = visitor.actors.flatMap { $0.variables }
        let names = variables.map { $0.name }
        let parent = variables.map { ($0.parent as? NamedDeclaration)?.name }
        let values = variables.compactMap { $0.initializerClause }.map { $0.value }
        
        XCTAssertEqual(variables.count, 2)
        XCTAssertEqual(names, ["property", "y"])
        XCTAssertEqual(parent, ["RootActor", "RootActor"])
        XCTAssertEqual(values, ["x", "0"])
    }
    
    func testParseActorsAttributes() throws {
        let attributes = visitor.actors.flatMap { $0.attributes }.map { $0.annotation }
        
        XCTAssertEqual(attributes.count, 1)
        XCTAssertEqual(attributes, [.available])
    }
    
    func testParseActorsModifiers() throws {
        let modifiers = visitor.actors.map { $0.modifiers }
        
        XCTAssertEqual(modifiers, [[.public], [.private], [.distributed], []])
    }
    
    func testParseActorsMemberFunctions() throws {
        let functions = visitor.actors
            .first { $0.name == "RootActor" }?.functions ?? []
        
        XCTAssertEqual(functions.count, 1)
        XCTAssertEqual(functions.map { $0.name }, ["foo"])
        XCTAssertEqual(functions.map { $0.body?.content }, ["let make = 42"])
    }
    
    func testParseActorsMemberInitializers() throws {
        let initializers = visitor.actors
            .first { $0.name == "RootActor" }?.initializers ?? []
        
        XCTAssertEqual(initializers.count, 1)
        XCTAssertEqual(initializers.map { ($0.parent as? NamedDeclaration)?.name }, ["RootActor"])
    }
    
    func testParseNestedActorsWithinActor() throws {
        let nested = visitor.actors
            .first { $0.name == "RootActor" }?.actors ?? []
        
        XCTAssertEqual(nested.map { $0.name }, ["NestedActor"])
    }
    
    func testParseNestedActorsWithinClass() throws {
        let holder = visitor.classes.first { $0.name == "Holder" }
        
        XCTAssertEqual(holder?.actors.map { $0.name }, ["Inner"])
    }
    
    // MARK: - Regression: actor members must not leak into the enclosing scope
    
    func testActorMembersAreAttributedToTheirActor() throws {
        let parents = visitor.functions.map { ($0.parent as? NamedDeclaration)?.name }
        
        XCTAssertEqual(visitor.functions.map { $0.name }, ["foo", "bar", "remoteCall", "work"])
        XCTAssertEqual(parents, ["RootActor", "NestedActor", "Worker", "Inner"])
    }
    
    func testActorMembersAreNotRootDeclarations() throws {
        let rootDeclarations = visitor.rootDeclarations
            .compactMap { ($0 as? NamedDeclaration)?.name }
        
        XCTAssertEqual(rootDeclarations, ["RootActor", "Worker", "Holder"])
    }
    
    func testNestedActorIsNotFlattenedIntoItsEnclosingClass() throws {
        let holder = visitor.classes.first { $0.name == "Holder" }
        
        XCTAssertEqual(holder?.functions.map { $0.name }, [])
        XCTAssertEqual(holder?.declarations.count, 1)
    }
}
