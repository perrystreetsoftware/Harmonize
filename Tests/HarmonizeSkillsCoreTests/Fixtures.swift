//
//  Fixtures.swift
//  HarmonizeSkillsCoreTests
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

import Foundation
import XCTest
@testable import HarmonizeSkillsCore

/// A temporary repository with a `.harmonize.yaml` and a rules package.
final class FixtureRepository {
    let root: URL
    var rulesPackage: URL { root.appendingPathComponent("Rules") }

    init(harmonizeYAML: String = "") throws {
        root = canonicalURL(FileManager.default.temporaryDirectory)
            .appendingPathComponent("HarmonizeSkillsCoreTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: rulesPackage.appendingPathComponent("Tests/RulesTests"),
            withIntermediateDirectories: true
        )
        try harmonizeYAML.write(to: root.appendingPathComponent(".harmonize.yaml"), atomically: true, encoding: .utf8)
    }

    @discardableResult
    func addRuleFile(_ name: String, in folder: String = "RulesTests", contents: String) throws -> URL {
        let directory = rulesPackage.appendingPathComponent("Tests/\(folder)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(name).swift")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func remove() {
        try? FileManager.default.removeItem(at: root)
    }
}

let categoryEnumSource = """
import Harmonize

enum Categories: String, RuleCategory {
    case viewmodel
    case designSystem = "designsystem"
    case logic

    var categoryName: String { rawValue }

    var categoryDescription: String {
        switch self {
        case .viewmodel: "Rules for ViewModels. Read before changing a ViewModel."
        case .designSystem, .logic:
            return "Rules for components and use cases."
        }
    }
}
"""

func ruleSource(
    className: String,
    id: String? = nil,
    title: String = "Title of the rule.",
    category: String = "Categories.viewmodel",
    disclosure: String? = nil,
    rationale: String = "Because.",
    howToFix: String = "Fix it.",
    badExample: String = "bad()",
    goodExample: String = "good()",
    ruleTypeName: String = "Rule"
) -> String {
    var fields: [String] = []
    if let id { fields.append("id: \"\(id)\"") }
    fields.append("title: \"\(title)\"")
    fields.append("category: \(category)")
    if let disclosure { fields.append("disclosure: \(disclosure)") }
    fields.append("rationale: \"\(rationale)\"")
    fields.append("howToFix: \"\(howToFix)\"")
    fields.append("badExample: \"\(badExample)\"")
    fields.append("goodExample: \"\(goodExample)\"")
    return """
    import Harmonize
    import XCTest

    final class \(className): XCTestCase {
        func testRule() {
            Harmonize.productionCode().classes().assertTrue(rule: Self.rule) { _ in true }
        }

        private static let rule = \(ruleTypeName)(
            \(fields.joined(separator: ",\n        "))
        )
    }
    """
}

func makeRule(
    id: String,
    title: String = "Title.",
    category: String = "viewmodel",
    disclosure: String = "progressive",
    rationale: String = "Why.",
    howToFix: String = "Fix.",
    badExample: String = "bad",
    goodExample: String = "good",
    definedIn: URL = URL(fileURLWithPath: "/repo/Rules/Tests/RulesTests/SomeRule.swift")
) -> StaticRule {
    StaticRule(
        id: id, title: title, category: category, disclosure: disclosure,
        rationale: rationale, howToFix: howToFix, badExample: badExample, goodExample: goodExample,
        definedIn: definedIn
    )
}
