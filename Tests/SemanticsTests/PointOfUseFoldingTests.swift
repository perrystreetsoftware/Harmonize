//
//  PointOfUseFoldingTests.swift
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

import HarmonizeSemantics
import SwiftParser
import XCTest

/// Infix expressions and comparisons must be found on a raw, *unfolded* parse:
/// the production pipeline no longer folds whole files, so `Body` and
/// `Condition` fold operator sequences at the point of use.
final class PointOfUseFoldingTests: XCTestCase {
    private var sourceSyntax = Parser.parse(
        source: """
        func compute(a: Int, b: Int) -> Int {
            let sum = a + b * 2
            var result = 0
            result = sum - 1
            if result > 10 && a < b {
                result += a
            }
            return result
        }
        """
    )

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

    func testFindsInfixExpressionsOnUnfoldedTree() throws {
        let body = try XCTUnwrap(visitor.functions.first?.body)

        // `result = sum - 1` is a flat SequenceExprSyntax before folding;
        // it must still surface as an infix expression.
        let assignment = try XCTUnwrap(body.infixExpressions.first)
        XCTAssertEqual(assignment.leftOperand, "result")
        XCTAssertEqual(assignment.operator, "=")
    }

    func testFindsComparisonConditionOnUnfoldedTree() throws {
        let body = try XCTUnwrap(visitor.functions.first?.body)
        let ifStatement = try XCTUnwrap(body.ifs.first)

        XCTAssertTrue(ifStatement.conditions.allSatisfy(\.isComparison))
    }
}
