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
    private var sourceSyntax = """
    class CycleA_DCTest: CycleB_DCTest {}
    class CycleB_DCTest: CycleA_DCTest {}
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

    func testSupertypeOfDoesNotCrashOnCircularInheritance() {
        let classes = visitor.classes
        XCTAssertEqual(classes.map(\.name), ["CycleA_DCTest", "CycleB_DCTest"])
        XCTAssertEqual(classes.first!.inheritanceTypesNames, ["CycleB_DCTest"])
        XCTAssertEqual(classes.last!.inheritanceTypesNames, ["CycleA_DCTest"])
    }
}
