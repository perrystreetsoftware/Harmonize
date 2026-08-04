//
//  RuleTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2026. All Rights Reserved.
//

import Foundation
import Harmonize
import HarmonizeSemantics
import XCTest

final class RuleTests: XCTestCase {
    // MARK: - Ambient metadata

    func testAssertionsInsideRuleBodyInheritRuleMetadata() throws {
        let rule = Rule(
            id: "viewmodels-inherit-base",
            why: "ViewModels must inherit BaseViewModel.",
            howToFix: "Inherit from BaseViewModel."
        ) { scope in
            scope.classes().assertTrue { $0.inherits(from: "BaseViewModel") }
        }

        let violations = rule.violations(in: Harmonize.on(source: "final class ProfileViewModel {}", path: "VM.swift"))

        let violation = try XCTUnwrap(violations.first)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violation.rule?.id, "viewmodels-inherit-base")
        XCTAssertEqual(violation.rule?.howToFix, "Inherit from BaseViewModel.")
        XCTAssertEqual(violation.name, "ProfileViewModel")
        XCTAssertEqual(violation.message, rule.formatted)
        XCTAssertTrue(violation.message.contains("ViewModels must inherit BaseViewModel."))
    }

    func testExplicitRuleOnAssertionWinsOverAmbientRule() throws {
        let rule = Rule(id: "ambient-rule", why: "Ambient.") { scope in
            scope.classes().assertTrue(rule: Rule(id: "explicit-rule", why: "Explicit.")) { _ in false }
        }

        let violations = rule.violations(in: Harmonize.on(source: "final class Foo {}", path: "Foo.swift"))

        XCTAssertEqual(violations.map { $0.rule?.id }, ["explicit-rule"])
        XCTAssertEqual(violations.map(\.message), [Rule(id: "explicit-rule", why: "Explicit.").formatted])
    }

    func testAmbientRuleDoesNotLeakOutsideRuleBody() {
        let rule = Rule(id: "scoped-rule", why: "Scoped.") { scope in
            scope.classes().assertTrue { _ in false }
        }

        let scope = Harmonize.on(source: "final class Foo {}", path: "Foo.swift")
        _ = rule.violations(in: scope)

        let reporter = CollectingReporter()
        HarmonizeReporting.withReporter(reporter) {
            scope.classes().assertTrue { _ in false }
        }

        XCTAssertNil(reporter.violations.first?.rule)
    }

    // MARK: - Evaluation

    func testResultDoesNotDisturbTheActiveReporter() {
        let outer = CollectingReporter()
        let rule = Rule(id: "some-rule", why: "Nope.") { scope in
            scope.classes().assertTrue { _ in false }
        }

        HarmonizeReporting.withReporter(outer) {
            _ = rule.violations(in: Harmonize.on(source: "final class Foo {}", path: "Foo.swift"))
        }

        XCTAssertTrue(outer.isEmpty, "Inspecting a rule's results must not report them.")
    }

    func testEvaluateReportsToTheActiveReporter() {
        let reporter = CollectingReporter()
        HarmonizeReporting.withReporter(reporter) {
            DemoRules.viewModelsInheritBase.evaluate(
                in: Harmonize.on(source: "final class ProfileViewModel {}", path: "VM.swift")
            )
        }

        XCTAssertEqual(reporter.violations.map(\.name), ["ProfileViewModel"])
    }

    func testFileAttributedRuleFiresOnNamedInlineSource() {
        let result = DemoRules.domainDoesNotImportUIKit.result(
            inSource: "import UIKit",
            path: "FetchUserUseCase.swift"
        )

        XCTAssertEqual(result.violations.map(\.name), ["FetchUserUseCase.swift"])
    }

    // MARK: - Authoring assertions

    func testAssertFiresReportsWhenRuleNeverMatches() {
        let rule = Rule(id: "never-fires") { scope in
            scope.classes().withNameEndingWith("Nonexistent").assertEmpty()
        }

        let reporter = CollectingReporter()
        HarmonizeReporting.withReporter(reporter) {
            rule.assertFires(on: "final class ProfileViewModel {}")
        }

        XCTAssertEqual(reporter.failures.count, 1)
        XCTAssertTrue(reporter.failures[0].message.contains("'never-fires'"))
    }

    func testAssertPassesReportsWhenRuleMatchesCleanCode() {
        let reporter = CollectingReporter()
        HarmonizeReporting.withReporter(reporter) {
            DemoRules.viewModelsInheritBase.assertPasses(on: "final class ProfileViewModel {}")
        }

        XCTAssertEqual(reporter.failures.count, 1)
        XCTAssertTrue(reporter.failures[0].message.contains("ProfileViewModel"))
    }

    func testAuthoringAssertionsPassForACorrectRule() {
        let reporter = CollectingReporter()
        HarmonizeReporting.withReporter(reporter) {
            DemoRules.viewModelsInheritBase.assertFires(on: "final class ProfileViewModel {}")
            DemoRules.viewModelsInheritBase.assertPasses(on: "final class ProfileViewModel: BaseViewModel {}")
        }

        XCTAssertTrue(reporter.isEmpty)
    }

    // MARK: - Examples

    func testDemoRuleExamplesAreAccurate() {
        DemoRules.assertExamples()
    }

    func testAssertExamplesCatchesABadExampleThatDoesNotFire() {
        let rule = Rule(
            id: "wrong-bad-example",
            why: "ViewModels must inherit BaseViewModel.",
            badExample: "final class ProfileViewModel: BaseViewModel {}", // doesn't actually break the rule
            goodExample: "final class ProfileViewModel: BaseViewModel {}"
        ) { scope in
            scope.classes().withNameEndingWith("ViewModel").assertTrue { $0.inherits(from: "BaseViewModel") }
        }

        let reporter = CollectingReporter()
        HarmonizeReporting.withReporter(reporter) { rule.assertExamples() }

        XCTAssertEqual(reporter.failures.count, 1)
        XCTAssertTrue(reporter.failures[0].message.contains("does not fire on its own bad example"))
    }

    func testAssertExamplesCatchesAGoodExampleThatBreaksTheRule() {
        let rule = Rule(
            id: "wrong-good-example",
            why: "ViewModels must inherit BaseViewModel.",
            badExample: "final class SettingsViewModel {}",
            goodExample: "final class ProfileViewModel {}" // actually breaks the rule
        ) { scope in
            scope.classes().withNameEndingWith("ViewModel").assertTrue { $0.inherits(from: "BaseViewModel") }
        }

        let reporter = CollectingReporter()
        HarmonizeReporting.withReporter(reporter) { rule.assertExamples() }

        XCTAssertEqual(reporter.failures.count, 1)
        XCTAssertTrue(reporter.failures[0].message.contains("fires on its own good example"))
    }

    func testRulesWithoutExamplesPassTrivially() {
        let reporter = CollectingReporter()
        HarmonizeReporting.withReporter(reporter) {
            Rule(id: "no-examples") { $0.classes().assertTrue { _ in false } }.assertExamples()
        }

        XCTAssertTrue(reporter.isEmpty)
    }

    // MARK: - Ignored scope

    /// A rule whose check queries its own scope instead of the one it receives. Every rule in a
    /// codebase migrating from inline assertions looks like this.
    private static let ignoresItsScope = Rule(
        id: "ignores-its-scope",
        summary: "Reads the project rather than the scope it is handed.",
        badExample: "final class Anything {}",
        goodExample: "final class Anything {}"
    ) { _ in
        Harmonize.on(source: "final class Elsewhere {}", path: "Elsewhere.swift")
            .classes()
            .assertEmpty()
    }

    func testAssertExamplesReportsARuleThatIgnoresItsScope() {
        let reporter = CollectingReporter()
        HarmonizeReporting.withReporter(reporter) { Self.ignoresItsScope.assertExamples() }

        XCTAssertEqual(reporter.failures.count, 1, "Should report once, not once per example.")
        XCTAssertTrue(reporter.failures[0].message.contains("Elsewhere.swift"))
        XCTAssertTrue(reporter.failures[0].message.contains("builds its own scope"))
    }

    func testAssertFiresReportsARuleThatIgnoresItsScope() {
        let reporter = CollectingReporter()
        HarmonizeReporting.withReporter(reporter) {
            Self.ignoresItsScope.assertFires(on: "final class Anything {}")
        }

        XCTAssertEqual(reporter.failures.count, 1)
        XCTAssertTrue(reporter.failures[0].message.contains("builds its own scope"))
    }

    func testAssertPassesReportsARuleThatIgnoresItsScope() {
        let reporter = CollectingReporter()
        HarmonizeReporting.withReporter(reporter) {
            Self.ignoresItsScope.assertPasses(on: "final class Anything {}")
        }

        XCTAssertEqual(reporter.failures.count, 1)
        XCTAssertTrue(reporter.failures[0].message.contains("builds its own scope"))
    }

    func testRulesUsingTheGivenScopeAreNotFlagged() {
        let reporter = CollectingReporter()
        HarmonizeReporting.withReporter(reporter) { DemoRules.assertExamples() }

        XCTAssertTrue(reporter.isEmpty)
    }

    // MARK: - Example paths

    func testExamplesOfAPathScopedRuleVerifyAtTheirOwnPath() {
        let reporter = CollectingReporter()
        HarmonizeReporting.withReporter(reporter) {
            DemoRules.screensDoNotStyleDirectly.assertExamples()
        }

        XCTAssertTrue(reporter.isEmpty, "A rule scoped to a directory should see examples placed in it.")
    }

    func testAPathScopedRuleNeverSeesExamplesLeftAtTheDefaultPath() {
        let strandedExamples = Rule(
            id: "stranded-examples",
            why: "Screens must not style directly.",
            badExample: "struct ProfileScreen: View { var body: some View { Text(\"Hi\").padding(16) } }",
            goodExample: "struct ProfileScreen: View { var body: some View { AtomText() } }"
            // examplePath omitted, so both stand at Snippet.swift and fall outside Sources/Screens
        ) { scope in
            scope.sources()
                .filter { $0.filePath?.path.contains("Sources/Screens") == true }
                .assertTrue { !$0.source.contains(".padding(") }
        }

        let reporter = CollectingReporter()
        HarmonizeReporting.withReporter(reporter) { strandedExamples.assertExamples() }

        XCTAssertEqual(reporter.failures.count, 1)
        XCTAssertTrue(reporter.failures[0].message.contains("matches on a directory that path is not in"))
        XCTAssertTrue(reporter.failures[0].message.contains("examplePath"))
    }

    func testSnippetPathsDoNotDependOnTheWorkingDirectory() {
        let rule = Rule(id: "path-shape") { scope in
            scope.sources().assertEmpty()
        }

        let violations = rule.violations(in: Harmonize.on(source: "let a = 1", path: "Sources/Screens/A.swift"))

        XCTAssertEqual(violations.first?.filePath.path, "/Sources/Screens/A.swift")
    }

    // MARK: - Catalog integrity

    func testDemoCatalogIsValid() {
        DemoRules.assertRulesAreValid()
    }

    func testCatalogValidityReportsDuplicateIds() {
        enum Duplicated: RuleSet {
            static let rules: [Rule] = [
                Rule(id: "same-id", why: "One.") { _ in },
                Rule(id: "same-id", why: "Two.") { _ in }
            ]
        }

        let reporter = CollectingReporter()
        HarmonizeReporting.withReporter(reporter) { Duplicated.assertRulesAreValid() }

        XCTAssertEqual(reporter.failures.count, 1)
        XCTAssertTrue(reporter.failures[0].message.contains("'same-id'"))
    }

    func testCatalogValidityReportsRulesThatExplainNothing() {
        enum Undocumented: RuleSet {
            static let rules: [Rule] = [Rule(id: "silent-rule") { _ in }]
        }

        let reporter = CollectingReporter()
        HarmonizeReporting.withReporter(reporter) { Undocumented.assertRulesAreValid() }

        XCTAssertEqual(reporter.failures.count, 1)
        XCTAssertTrue(reporter.failures[0].message.contains("no summary and no reasoning"))
    }

    // MARK: - RuleSet

    func testRuleSetEvaluatesEveryRule() {
        let source = """
        import UIKit

        final class ProfileViewModel {
            init() {
                fetch { self.name = $0 }
            }
        }
        """

        let violations = DemoRules.violations(in: Harmonize.on(source: source, path: "ProfileViewModel.swift"))

        XCTAssertEqual(
            Set(violations.compactMap { $0.rule?.id }),
            ["viewmodels-inherit-base", "domain-does-not-import-uikit", "no-side-effects-in-initializers"]
        )
    }

    func testRuleLookupById() {
        XCTAssertEqual(DemoRules.rule(id: "viewmodels-inherit-base")?.id, "viewmodels-inherit-base")
        XCTAssertNil(DemoRules.rule(id: "nonexistent"))
    }
}
