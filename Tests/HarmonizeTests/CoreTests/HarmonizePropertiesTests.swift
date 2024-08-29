import Foundation
import Harmonize
import XCTest

final class HarmonizePropertiesTests: XCTestCase {
    private var harmonize: Harmonize {
        HarmonizeUtils().appendingPath("PropertiesFixture").harmonize()
    }
    
    private var topLevelProperties: [SwiftProperty] {
        harmonize.properties(includeNested: false)
    }
    
    func testAssertCanParseTopLevelProperties() throws {
        let names = topLevelProperties.map { $0.name }
        
        XCTAssertEqual(topLevelProperties.count, 5)
        
        let expectedNames = ["property", "immutable", "nullable", "inlineProperty1", "inlineProperty2"]
        XCTAssertEqual(names, expectedNames)
    }
    
    func testAssertCanParseTopLevelPropertiesTypes() throws {
        let types = topLevelProperties.map { $0.declarationType }
        
        XCTAssertEqual(types, [.var, .let, .var, .var, .var])
    }
    
    func testAssertCanParseTopLevelPropertiesAnnotations() throws {
        let annotations = topLevelProperties.map { $0.typeAnnotation }
        
        let expectedAnnotations = [
            "",
            "String",
            "String?",
            "Int",
            "String?"
        ]
        
        XCTAssertEqual(annotations, expectedAnnotations)
    }
    
    func testAssertCanParseTopLevelPropertiesInferredAnnotations() throws {
        let inferredProperties = topLevelProperties.filter { $0.isInferredType }
        
        XCTAssertEqual(inferredProperties.count, 1)
    }
    
    func testAssertCanParseTopLevelPropertiesPrimitiveValues() throws {
        let initializers = topLevelProperties.map { $0.initializer }
        
        let expectedValues = [
            "a",
            "string",
            "nil",
            "2",
            "b",
        ]
        
        XCTAssertEqual(initializers, expectedValues)
    }
    
    func testAssertCanParseTopLevelPropertiesImmutability() throws {
        let immutableProperties = topLevelProperties.filter { $0.isImmutable }
        
        XCTAssertEqual(immutableProperties.count, 1)
    }
    
    func testAssertCanParsePropertiesWithOptionalTypes() throws {
        let optionalProperties = topLevelProperties.filter { $0.isOptional }
        XCTAssertEqual(optionalProperties.count, 2)
    }
    
    func testAssertCanParseSingleLineMultipleProperties() throws {
        let exampleClass = harmonize.classes().first { $0.name == "ExampleClass" }!
        let properties = exampleClass.properties
        
        XCTAssertEqual(
            properties.map { $0.name },
            ["a", "b", "c", "d"]
        )
    }
    
    func testAssertSingleLineMultiplePropertiesAreOfTheSameType() throws {
        let exampleClass = harmonize.classes().first { $0.name == "ExampleClass" }!
        let properties = exampleClass.properties
        
        XCTAssert(
            properties.map { $0.typeAnnotation }.allSatisfy { $0 == "Double" }
        )
    }
    
    func testAssertCanParseCustomTypeProperties() throws {
        let mainClass = harmonize.classes().first { $0.name == "Main" }!
        let properties = mainClass.properties
        
        XCTAssertEqual(
            properties.map { $0.typeAnnotation },
            ["MyClassType", "MyClassType"]
        )
    }
    
    func testAssertCanParseCustomTypePropertiesInitializer() throws {
        let mainClass = harmonize.classes().first { $0.name == "Main" }!
        let properties = mainClass.properties
        
        XCTAssertEqual(
            properties.map { $0.initializer },
            ["MyClassType(value: 2)", ""]
        )
    }
    
    func testAssertCanParsePropertiesModifiers() throws {
        let properties = harmonize.properties().filter { $0.parent?.name == "Properties" }
        let modifiers = properties.map { $0.modifiers }
        
        let expectedModifiers: [[SwiftModifier]] = [
            [.private],
            [.public],
            [.internal],
            [.fileprivate],
            [.open],
            [.public, .weak],
            [.unowned],
            [.fileprivate, .lazy],
            [.final],
            [.static],
            [],
            [],
            []
        ]
        
        XCTAssertEqual(modifiers, expectedModifiers)
    }
    
    func testAssertCanParsePropertiesAttributes() throws {
        let properties = harmonize.properties()
        let attributes = properties.flatMap { $0.attributes }
        
        let expectedAttributes: [SwiftAttribute] = [
            .declaration(attribute: .available, arguments: ["*", "renamed: example11"]),
            .declaration(attribute: .objc, arguments: []),
            .customPropertyWrapper(name: "Published", arguments: []),
            .customPropertyWrapper(name: "Published", arguments: [])
        ]
        
        XCTAssertEqual(
            attributes,
            expectedAttributes
        )
    }
    
    func testAssertCanParsePropertiesAccessorsBody() throws {
        let properties = harmonize.properties()
        let accessors = properties.flatMap { $0.accessors }.map { $0.body }
        
        XCTAssertEqual(accessors.count, 3)
        XCTAssertEqual(
            accessors,
            ["9", "return example12", "example12 = newValue"]
        )
    }
    
    func testAssertCanParsePropertiesAccessorsText() throws {
        let properties = harmonize.properties()
        let accessors = properties.flatMap { $0.accessors }.map { $0.text }
        
        XCTAssertEqual(accessors.count, 3)
        XCTAssertEqual(
            accessors,
            [
                "{ 9 }",
                "{ return example12 }",
                "{ example12 = newValue }"
            ]
        )
    }
    
    func testAssertCanParsePropertiesAccessorsModifier() throws {
        let properties = harmonize.properties()
        let accessors = properties.flatMap { $0.accessors }.map { $0.modifier }
        
        XCTAssertEqual(accessors.count, 3)
        XCTAssertEqual(accessors, [.getter, .get, .set])
    }
    
    func testAssertCanParsePropertiesWrapper() throws {
        let properties = harmonize.properties().filter { $0.parent?.name == "MyViewModel" }
        let attributes = properties.flatMap { $0.attributes }
        
        XCTAssertEqual(attributes.count, 2)
        XCTAssertEqual(
            attributes,
            [
                .customPropertyWrapper(name: "Published", arguments: []),
                .customPropertyWrapper(name: "Published", arguments: [])
            ]
        )
    }
    
    func testAssertCanParsePropertiesAccessorsModifiers() throws {
        let properties = harmonize.properties().filter { $0.parent?.name == "MyViewModel" }
        let modifiers = properties.flatMap { $0.modifiers }.map { $0}
        
        XCTAssertEqual(modifiers.count, 3)
        XCTAssertEqual(modifiers, [.public, .public, .privateSet])
    }
}