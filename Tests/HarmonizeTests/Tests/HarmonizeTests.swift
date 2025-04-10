//
//  HarmonizeTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import Harmonize
import XCTest

final class HarmonizeTests: XCTestCase {
    private let productionAndTestCode = Harmonize.productionAndTestCode()
        .on("Fixtures/SampleApp")
    
    private let productionCode = Harmonize.productionCode()
        .on("Fixtures/SampleApp")
    
    private let testCode = Harmonize.testCode()
        .on("Fixtures/SampleApp")

    func testMultipleOnSelectsDifferentClasses() throws {
        let productionCode = Harmonize.productionCode()
        let filtersFiles = productionCode.on("Fixtures/Filters")
        let sampleApp = productionCode.on("Fixtures/SampleApp")

        XCTAssertNotEqual(filtersFiles.classes(), sampleApp.classes())
    }

    func testMultipleExcludingExcludesDifferentClasses() throws {
        let productionCode = Harmonize.productionCode()
        let filtersFiles = productionCode.excluding("Fixtures/Filters")
        let sampleApp = productionCode.excluding("Fixtures/SampleApp")

        XCTAssertNotEqual(filtersFiles.classes(), sampleApp.classes())
    }

    func testCreatesScopesWithProductionAndTestCode() throws {
        let scope = productionAndTestCode
        let fileNames = scope.sources().map { $0.fileName }
        let edgeCases = ["MathTests.swift", "UseCases.swift", "ModelsTests.swift"]
        
        XCTAssertEqual(scope.sources().count, 5)
        
        for edgeCase in edgeCases {
            XCTAssert(fileNames.contains(edgeCase), "\(edgeCase) not found in \(fileNames)")
        }
    }
    
    func testCreatesScopesWithProductionAndTestCodeExcludingFiles() throws {
        let scope = productionAndTestCode
            .excluding("MathTests.swift", "UseCases.swift", "ModelsTests.swift")
        
        let fileNames = scope.sources().map { $0.fileName }
        
        XCTAssertEqual(scope.sources().count, 2)
        
        for excluded in ["MathTests.swift", "UseCases.swift", "ModelsTests.swift"] {
            XCTAssert(!fileNames.contains(excluded), "\(excluded) found in \(fileNames)")
        }
    }
    
    func testCreatesScopesWithProductionAndTestCodeExcludingPath() throws {
        let scope = productionAndTestCode.excluding("Tests")
        let fileNames = scope.sources().map { $0.fileName }
        
        XCTAssertEqual(scope.sources().count, 2)
        
        for excluded in ["MathTests.swift", "UseCasesTests.swift", "ModelsTests.swift"] {
            XCTAssert(!fileNames.contains(excluded), "\(excluded) found in \(fileNames)")
        }
    }

    func testCreatesScopesWithProductionCode() throws {
        let isOnlyProductionCode = productionCode.sources()
            .map { $0.fileName }
            .contains {
                ["Models.swift", "UseCases.swift"].contains($0)
            }
    
        XCTAssertTrue(isOnlyProductionCode)
    }
    
    func testCreatesScopesWithTestCode() throws {
        let isOnlyTestCode = testCode.sources()
            .map { $0.fileName }
            .contains {
                ["MathTests.swift", "UseCasesTests.swift", "ModelsTests.swift"].contains($0)
            }

        XCTAssertTrue(isOnlyTestCode)
    }
    
    func testCreatesScopesMatchingFolder() throws {
        // Grab every test code contained in "Sources" folder
        // Certainly empty because Sources must have no Tests on this project.
        let scope = Harmonize.testCode()
            .on("Sources")
        
        // Grab every production code in "Sources" folder.
        let prodScope = Harmonize.productionCode()
            .on("Sources")
        
        // Sources must have no test code
        XCTAssertTrue(scope.sources().isEmpty)
        XCTAssertTrue(!prodScope.sources().isEmpty)
        XCTAssertTrue(prodScope.sources().contains { !($0.fileName?.hasSuffix("Tests") == true) })
    }

    func testChangingScopeBuilderParamsResetsCache() throws {
        let initialSources = testCode.sources()
        XCTAssertEqual(initialSources.count, 3)

        let newSources = testCode.excluding("MathTests.swift").sources()
        XCTAssertEqual(newSources.count, 2)
    }

    func testCreatesScopesWithProductionAndTestCodeWildcardExclusion() throws {
        let scope = productionAndTestCode.excluding("UseCase*")
        let fileNames = scope.sources().map { $0.fileName }

        for excluded in ["UseCasesTests.swift", "UseCases.swift"] {
            XCTAssert(!fileNames.contains(excluded), "\(excluded) found in \(fileNames)")
        }
    }
}
