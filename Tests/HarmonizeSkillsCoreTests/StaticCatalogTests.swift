//
//  StaticCatalogTests.swift
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

final class StaticCatalogTests: XCTestCase {
    private var repository: FixtureRepository!

    override func setUpWithError() throws {
        repository = try FixtureRepository()
        try repository.addRuleFile("Categories", contents: categoryEnumSource)
    }

    override func tearDown() {
        repository.remove()
    }

    func testReadsRuleMetadataAndDerivesTheIdFromTheFileName() throws {
        try repository.addRuleFile("ViewModelsInheritBase", contents: ruleSource(className: "ViewModelsInheritBase"))

        let catalog = try StaticCatalogLoader.load(rulesPackage: repository.rulesPackage)
        let rule = try XCTUnwrap(catalog.rules.first)

        XCTAssertEqual(catalog.rules.count, 1)
        XCTAssertEqual(rule.id, "view-models-inherit-base")
        XCTAssertEqual(rule.title, "Title of the rule.")
        XCTAssertEqual(rule.category, "viewmodel")
        XCTAssertEqual(rule.disclosure, "progressive")
        XCTAssertEqual(rule.rationale, "Because.")
        XCTAssertEqual(rule.howToFix, "Fix it.")
        XCTAssertEqual(rule.badExample, "bad()")
        XCTAssertEqual(rule.goodExample, "good()")
        XCTAssertEqual(rule.definedIn.lastPathComponent, "ViewModelsInheritBase.swift")
    }

    func testResolvesEnumCasesToRawValuesAndReadsDescriptions() throws {
        try repository.addRuleFile("ComponentsRule", contents: ruleSource(className: "ComponentsRule", category: "Categories.designSystem"))
        try repository.addRuleFile("ImplicitMember", contents: ruleSource(className: "ImplicitMember", category: ".logic"))

        let catalog = try StaticCatalogLoader.load(rulesPackage: repository.rulesPackage)

        XCTAssertEqual(catalog.rules.map(\.category).sorted(), ["designsystem", "logic"])
        XCTAssertEqual(catalog.categories["viewmodel"]?.description, "Rules for ViewModels. Read before changing a ViewModel.")
        XCTAssertEqual(catalog.categories["designsystem"]?.description, "Rules for components and use cases.")
        XCTAssertEqual(catalog.categories["logic"]?.description, "Rules for components and use cases.")
    }

    func testExplicitIdLiteralCategoryAndDisclosureAreKept() throws {
        try repository.addRuleFile("ClassesMustBeFinal", contents: ruleSource(
            className: "ClassesMustBeFinal", id: "classes-are-final", category: "\"\"", disclosure: ".upfront"
        ))

        let catalog = try StaticCatalogLoader.load(rulesPackage: repository.rulesPackage)
        let rule = try XCTUnwrap(catalog.rules.first)

        XCTAssertEqual(rule.id, "classes-are-final")
        XCTAssertEqual(rule.category, "")
        XCTAssertEqual(rule.disclosure, "upfront")
        XCTAssertEqual(catalog.upfrontRules.map(\.id), ["classes-are-final"])
        XCTAssertTrue(catalog.documentedCategories.isEmpty)
    }

    private func secondRule(id: String? = nil) -> String {
        """

        extension PairedRules {
            static let second = Rule(
                \(id.map { "id: \"\($0)\"," } ?? "")
                title: "Second title.",
                category: Categories.viewmodel,
                rationale: "Second why.",
                howToFix: "Second fix.",
                badExample: "b",
                goodExample: "g"
            )
        }
        """
    }

    func testTwoRulesWithOneIdFailWithBothLocations() throws {
        let file = try repository.addRuleFile("PairedRules", contents: ruleSource(className: "PairedRules") + secondRule())

        XCTAssertThrowsError(try StaticCatalogLoader.load(rulesPackage: repository.rulesPackage)) { error in
            let message = "\(error)"
            XCTAssertTrue(message.contains("rule id 'paired-rules' is already used at \(file.path):"), message)
            XCTAssertTrue(message.contains("Set an explicit id"), message)
        }
    }

    func testAnExplicitIdSeparatesTwoRulesInOneFile() throws {
        try repository.addRuleFile("PairedRules", contents: ruleSource(className: "PairedRules") + secondRule(id: "paired-rules-second"))

        let catalog = try StaticCatalogLoader.load(rulesPackage: repository.rulesPackage)

        XCTAssertEqual(catalog.rules.map(\.id), ["paired-rules", "paired-rules-second"])
    }

    func testOneExplicitIdInTwoFilesFails() throws {
        try repository.addRuleFile("First", contents: ruleSource(className: "First", id: "shared-id"))
        try repository.addRuleFile("Second", contents: ruleSource(className: "Second", id: "shared-id"))

        XCTAssertThrowsError(try StaticCatalogLoader.load(rulesPackage: repository.rulesPackage)) { error in
            XCTAssertTrue("\(error)".contains("rule id 'shared-id' is already used"), "\(error)")
        }
    }

    func testEveryInitializerFormIsRecognized() throws {
        try repository.addRuleFile("Qualified", contents: ruleSource(className: "Qualified", ruleTypeName: "Harmonize.Rule"))
        try repository.addRuleFile("ExplicitInit", contents: ruleSource(className: "ExplicitInit", ruleTypeName: "Rule.init"))
        try repository.addRuleFile("QualifiedInit", contents: ruleSource(className: "QualifiedInit", ruleTypeName: "Harmonize.Rule.init"))
        try repository.addRuleFile("Spaced", contents: ruleSource(className: "Spaced", ruleTypeName: "Rule "))
        try repository.addRuleFile("Contextual", contents: """
        import Harmonize
        import XCTest

        final class Contextual: XCTestCase {
            func testRule() {
                Harmonize.productionCode().classes().assertTrue(rule: .init(
                    title: "Contextual title.",
                    category: Categories.viewmodel,
                    rationale: "Why.",
                    howToFix: "Fix.",
                    badExample: "b",
                    goodExample: "g"
                )) { _ in true }
            }
        }
        """)

        let catalog = try StaticCatalogLoader.load(rulesPackage: repository.rulesPackage)

        XCTAssertEqual(
            catalog.rules.map(\.id).sorted(),
            ["contextual", "explicit-init", "qualified", "qualified-init", "spaced"]
        )
        XCTAssertEqual(catalog.rules.first { $0.id == "contextual" }?.title, "Contextual title.")
    }

    func testAContextualInitThatIsNotARuleIsIgnored() throws {
        try repository.addRuleFile("Other", contents: """
        import XCTest

        final class Other: XCTestCase {
            func testSomething() {
                let value: SomeType = .init(title: "Not a rule.", category: "x")
                _ = value
            }
        }
        """)

        let catalog = try StaticCatalogLoader.load(rulesPackage: repository.rulesPackage)

        XCTAssertTrue(catalog.rules.isEmpty)
    }

    func testAMemberExpressionForAStringFieldFails() throws {
        let source = """
        import Harmonize
        final class Shared: XCTestCase {
            static let text = "x"
            private static let rule = Rule(
                title: "Title.",
                category: Categories.viewmodel,
                rationale: "", howToFix: Self.text, badExample: "", goodExample: ""
            )
        }
        """
        let file = try repository.addRuleFile("Shared", contents: source)

        XCTAssertThrowsError(try StaticCatalogLoader.load(rulesPackage: repository.rulesPackage)) { error in
            let message = "\(error)"
            XCTAssertTrue(message.contains("\(file.path):7:"), message)
            XCTAssertTrue(message.contains("'howToFix' must be a string literal"), message)
        }
    }

    func testAnUnknownDisclosureFails() throws {
        try repository.addRuleFile("Sometimes", contents: ruleSource(className: "Sometimes", disclosure: ".sometimes"))

        XCTAssertThrowsError(try StaticCatalogLoader.load(rulesPackage: repository.rulesPackage)) { error in
            XCTAssertTrue("\(error)".contains("'disclosure' must be .upfront, .progressive or .deferred"), "\(error)")
        }
    }

    func testAnIdThatIsNotKebabCaseFails() throws {
        try repository.addRuleFile("Escaping", contents: ruleSource(className: "Escaping", id: "../../../other-skill/SKILL"))

        XCTAssertThrowsError(try StaticCatalogLoader.load(rulesPackage: repository.rulesPackage)) { error in
            XCTAssertTrue("\(error)".contains("rule id '../../../other-skill/SKILL' is not valid"), "\(error)")
        }
    }

    func testIdValidation() {
        for id in ["a", "view-models-inherit-base", "rule2-check"] {
            XCTAssertTrue(StaticCatalogLoader.isValidId(id), id)
        }
        for id in ["", "ViewModels", "a_b", "a b", "-a", "a-", "a--b", "a/b", "..", "é"] {
            XCTAssertFalse(StaticCatalogLoader.isValidId(id), id)
        }
    }

    func testNonLiteralArgumentFailsWithFileAndLine() throws {
        let source = """
        import Harmonize
        final class Dynamic: XCTestCase {
            static let shared = "x"
            private static let rule = Rule(
                title: Self.shared,
                category: Categories.viewmodel,
                rationale: "", howToFix: "", badExample: "", goodExample: ""
            )
        }
        """
        let file = try repository.addRuleFile("Dynamic", contents: source)

        XCTAssertThrowsError(try StaticCatalogLoader.load(rulesPackage: repository.rulesPackage)) { error in
            let message = (error as? HarmonizeSkillsError)?.message ?? ""
            XCTAssertTrue(message.contains("\(file.path):5:"), message)
            XCTAssertTrue(message.contains("'title' must be a string literal"), message)
        }
    }

    func testInterpolatedStringFails() throws {
        let source = """
        import Harmonize
        final class Interpolated: XCTestCase {
            private static let rule = Rule(
                title: "Count \\(1)",
                category: Categories.viewmodel,
                rationale: "", howToFix: "", badExample: "", goodExample: ""
            )
        }
        """
        try repository.addRuleFile("Interpolated", contents: source)

        XCTAssertThrowsError(try StaticCatalogLoader.load(rulesPackage: repository.rulesPackage)) { error in
            XCTAssertTrue("\(error)".contains("no interpolation"), "\(error)")
        }
    }

    func testCategoryNamesThatCollideAfterNormalizationFail() throws {
        try repository.addRuleFile("First", contents: ruleSource(className: "First", category: "\"viewmodel\""))
        try repository.addRuleFile("Second", contents: ruleSource(className: "Second", category: "\"View-Model\""))

        XCTAssertThrowsError(try StaticCatalogLoader.load(rulesPackage: repository.rulesPackage)) { error in
            XCTAssertTrue("\(error)".contains("'View-Model' vs 'viewmodel'"), "\(error)")
        }
    }

    func testSourcePathsAreCanonicalEvenWhenTheInputPathUsesASymlink() throws {
        try repository.addRuleFile("Linked", contents: ruleSource(className: "Linked"))
        let viaSymlink = URL(fileURLWithPath: "/var" + repository.rulesPackage.path.dropFirst("/private/var".count))
        try XCTSkipUnless(repository.rulesPackage.path.hasPrefix("/private/var"), "needs the macOS /var symlink")

        let catalog = try StaticCatalogLoader.load(rulesPackage: viaSymlink)
        let config = try ProjectConfig.load(startingAt: viaSymlink)

        XCTAssertEqual(catalog.rules.first?.definedIn.path, repository.rulesPackage.appendingPathComponent("Tests/RulesTests/Linked.swift").path)
        XCTAssertEqual(config.repoRoot.path, repository.root.path)
    }

    func testDerivedIdMatchesTheLibraryRule() {
        XCTAssertEqual(StaticCatalogLoader.derivedId(fromFileName: "DoNotUseDelayForInViewModels"), "do-not-use-delay-for-in-view-models")
        XCTAssertEqual(StaticCatalogLoader.derivedId(fromFileName: "ViewModelsInheritBase"), "view-models-inherit-base")
        XCTAssertEqual(StaticCatalogLoader.derivedId(fromFileName: "Rule2Check"), "rule2-check")
    }
}
