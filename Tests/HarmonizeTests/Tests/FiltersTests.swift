//
//  FiltersTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import HarmonizeSemantics
import Harmonize
import XCTest

#if canImport(RegexBuilder)
import RegexBuilder
#endif

final class FiltersTests: XCTestCase {
    func testNamedDeclarationsFilters() throws {
        let scope = Harmonize.productionCode().on("Fixtures/Filters/NamedDeclarations")
        
        scope.classes(includeNested: true)
            .withSuffix("ViewModel")
            .assertCount(count: 3)

        scope.classes(includeNested: true)
            .withNameEndingWith("ViewModel")
            .assertCount(count: 3)

        scope.classes(includeNested: true)
            .withoutSuffix("ViewModel")
            .assertEmpty()
        
        scope.classes(includeNested: true)
            .withPrefix("Base")
            .assertCount(count: 1)

        scope.classes(includeNested: true)
            .withNameStartingWith("Base")
            .assertCount(count: 1)

        scope.classes(includeNested: true)
            .withoutPrefix("Base")
            .assertCount(count: 2)
        
        scope.classes(includeNested: true)
            .withNameContaining("Base", "ViewModel")
            .assertCount(count: 3)
        
        scope.classes(includeNested: true)
            .withoutNameContaining("Base", "ViewModel")
            .assertEmpty()
        
        scope.classes(includeNested: true)
            .withoutName(["BaseViewModel", "AppMainViewModel"])
            .assertCount(count: 1)
        
        scope.classes(includeNested: true)
            .withName(["BaseViewModel"])
            .assertCount(count: 1)
    }
    
    func testInheritanceProvidingFilters() throws {
        let scope = Harmonize.productionCode().on("Fixtures/Filters/Inheritance")
        
        scope.classes(includeNested: true)
            .inheriting(from: "BaseUseCase")
            .assertCount(count: 1)
        
        scope.structs(includeNested: true)
            .conforming(to: "AgedUserModel")
            .assertCount(count: 1)
        
        scope.classes(includeNested: true)
            .inheriting(from: "BaseUseCase")
            .assertTrue { $0.inherits(from: "BaseUseCase") }
    }
    
    func testAttributesProvidingFilters() throws {
        let scope = Harmonize.productionCode().on("Fixtures/Filters/Attributes")
        
        scope.variables(includeNested: true)
            .withAttribute(Published<Int>.self)
            .assertCount(count: 2)
        
        scope.variables(includeNested: true)
            .withAttribute { $0.name == "@objc" }
            .assertEmpty()
        
        scope.variables(includeNested: true)
            .withAttribute(named: "@objc")
            .assertEmpty()
        
        scope.variables(includeNested: true)
            .withAttribute(named: "@Published")
            .assertCount(count: 2)
        
        scope.variables(includeNested: true)
            .withAttribute(annotatedWith: .published)
            .assertCount(count: 2)
    }
    
    func testTypeAnnotationProvidingFilters() throws {
        let scope = Harmonize.productionCode().on("Fixtures/Filters/Types")
        
        scope.variables(includeNested: true)
            .withType(Int.self)
            .assertCount(count: 1)
        
        scope.variables(includeNested: true)
            .withInferredType()
            .assertCount(count: 1)
        
        scope.variables(includeNested: true)
            .withType(named: "AppMainViewModel")
            .assertCount(count: 1)
        
        scope.variables(includeNested: true)
            .withType(String?.self)
            .assertCount(count: 1)
        
        scope.variables(includeNested: true)
            .withType { $0 == String?.self }
            .assertCount(count: 1)
    }
    
    func testBodyProvidingFilters() throws {
        let scope = Harmonize.productionCode().on("Fixtures/Filters/Body")
        
        scope.functions(includeNested: true)
            .withBodyContent { $0.contains("makeACall()") }
            .assertCount(count: 1)
        
        scope.functions(includeNested: true)
            .withBodyContent(containing: "makeACall\\(\\)")
            .assertCount(count: 1)
        
        if #available(iOS 16.0, macOS 13.0, *) {
            scope.functions(includeNested: true)
                .withBodyContent(containing: Regex {
                    "_"
                    ZeroOrMore { .whitespace }
                    "="
                    ZeroOrMore { .whitespace }
                    "\""
                    Capture {
                        OneOrMore { CharacterClass.any }
                    }
                    "\""
                })
                .assertCount(count: 1)
        }
        
        scope.functions(includeNested: true)
            .withoutBodyContent { $0.contains("makeACall()") }
            .assertNotEmpty()
    }
    
    func testModifiersProvidingFilters() throws {
        let scope = Harmonize.productionCode().on("Fixtures/Filters/Modifiers")
        
        scope.classes(includeNested: true)
            .withModifier(.final, .public)
            .assertCount(count: 1)
        
        scope.variables(includeNested: true)
            .withModifier(.public, .privateSet)
            .assertCount(count: 2)
        
        scope.variables(includeNested: true)
            .withoutModifier(.public)
            .assertCount(count: 1)
    }
    
    func testAccessorBlocksProvidingFilters() throws {
        let scope = Harmonize.productionCode().on("Fixtures/Filters/Accessors")
        let variables = scope.variables(includeNested: true)
        
        AccessorBlock.Modifier.allCases.forEach {
            variables.withAccessorBlockBody($0)
                .assertCount(count: 1)
        }
        
        variables.withGetter { $0?.contains("getter") ?? false }.assertNotEmpty()
        variables.withGet { $0?.contains("that's a get") ?? false }.assertNotEmpty()
        variables.withSet { $0?.contains("newValue") ?? false }.assertNotEmpty()
        variables.withDidSet { $0?.contains("didset") ?? false }.assertNotEmpty()
        variables.withWillSet { $0?.contains("willset") ?? false }.assertNotEmpty()
    }
    
    func testFunctionsProvidingFilters() throws {
        let scope = Harmonize.productionCode().on("Fixtures/Filters/Functions")
        scope.classes(includeNested: true)
            .withFunctions { $0.modifiers.contains(.private) }
            .assertCount(count: 1)
    }
    
    func testInitializeClauseProvidingFilters() throws {
        let scope = Harmonize.productionCode().on("Fixtures/Filters/InitializerClauses")
        
        scope.variables(includeNested: true)
            .withInitializerClause { $0.value.contains("42") }
            .assertCount(count: 2)
        
        scope.variables(includeNested: true)
            .withValue(containing: ":\\s*42")
            .assertCount(count: 1)
        
        if #available(iOS 16.0, macOS 13.0, *) {
            scope.variables(includeNested: true)
                .withValue(containing: Regex {
                    ":"
                    ZeroOrMore {
                        CharacterClass.whitespace
                    }
                    "42"
                })
                .assertCount(count: 1)
        }
    }
    
    func testInitializersProvidingFilters() throws {
        let scope = Harmonize.productionCode().on("Fixtures/Filters/Initializers")
        
        scope.structs(includeNested: true)
            .withInitializers { $0.parameters.isEmpty }
            .assertCount(count: 1)
        
        scope.extensions()
            .withInitializers { !$0.parameters.isEmpty }
            .assertCount(count: 1)
    }
    
    func testParametersProvidingFilters() throws {
        let scope = Harmonize.productionCode().on("Fixtures/Filters/Variables")
        
        scope.initializers()
            .withParameters { $0.name == "parameter" }
            .assertCount(count: 1)
    }
    
    func testPropertiesProvidingFilters() throws {
        let scope = Harmonize.productionCode().on("Fixtures/Filters/Variables")
        
        scope.initializers()
            .withVariables { $0.name == "variable" }
            .assertCount(count: 1)
    }
    
    func testReturnsEmptyWhenRegexPatternIsNotValid() throws {        
        Harmonize.productionCode().on("Fixtures/Filters/InitializerClauses")
            .variables()
            .withValue(containing: "wrong_regex")
            .assertEmpty()
        
        Harmonize.productionCode().on("Fixtures/Filters/Body")
            .functions()
            .withBodyContent(containing: "wrong_regex")
            .assertEmpty()
    }

    func testSourceCodeFilters() throws {
        Harmonize.productionCode().sources().withName("AccessorBlocksProviding.swift")
            .assertNotEmpty()

        Harmonize.productionCode().sources().withName("InvalidNameFile.swift")
            .assertEmpty()

        Harmonize.productionCode().sources()
            .withSuffix("+Enum.swift")
            .assertCount(count: 1)

        Harmonize.productionCode().sources()
            .withNameEndingWith("+Enum.swift")
            .assertCount(count: 1)

        Harmonize.productionCode().sources()
            .withSuffix("+Enum.swift")
            .withImport("HarmonizeSemantics")
            .assertCount(count: 1)

        Harmonize.productionCode().sources()
            .withSuffix("+Enum.swift")
            .withImport("Invalid")
            .assertCount(count: 0)

        Harmonize.productionCode().on("Fixtures/Filters/Inheritance")
            .sources()
            .withoutSuffix("Fixtures.swift")
            .assertEmpty()

        Harmonize.productionCode().on("Fixtures/Filters/Inheritance")
            .sources()
            .withoutName(["InheritanceFixtures.swift"])
            .assertEmpty()

        Harmonize.productionCode().on("Fixtures/Filters/Inheritance")
            .structs()
            .variables()
            .withTypeEndingWith("String")
            .assertNotEmpty()

        Harmonize.productionCode().on("Fixtures/Filters/Inheritance")
            .structs()
            .variables()
            .withTypeEndingWith("File")
            .assertEmpty()
    }
}
