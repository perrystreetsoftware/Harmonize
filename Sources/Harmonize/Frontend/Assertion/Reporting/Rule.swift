//
//  Rule.swift
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

import Foundation

/// The set of rule categories that a project defines.
///
/// Define your categories once, as an enum. Every rule then uses the same
/// spelling, and the compiler rejects near-duplicates such as `"view-model"`
/// next to `"viewmodel"`:
///
/// ```swift
/// enum Categories: String, RuleCategory {
///     case viewmodel, logic, networking
///     var categoryName: String { rawValue }
///     var categoryDescription: String {
///         switch self {
///         case .viewmodel: "Rules for ViewModels and UIModels. Read before you create or change a ViewModel."
///         case .logic: "Rules for Logic classes (use cases). Read before you add business logic."
///         case .networking: "Rules for APIs and DTOs. Read before you change network code."
///         }
///     }
/// }
/// ```
public protocol RuleCategory {
    /// The canonical category name. It groups the rules and names the layer
    /// file of the generated skill (`references/<categoryName>.md`).
    var categoryName: String { get }

    /// One or two sentences that say what the category covers and when to
    /// read its rules. The generated skill shows it next to the layer, so
    /// write it as a trigger: "Rules for X. Read before you create or change Y."
    var categoryDescription: String { get }
}

/// The metadata of an architectural rule.
///
/// Attach a `Rule` to an assertion. A violation then carries a machine-readable
/// identity and the guidance to correct it, not only a failure string:
///
/// ```swift
/// viewModels.assertTrue(rule: .init(
///     title: "ViewModels must inherit from BaseViewModel.",
///     category: Categories.viewmodel,
///     rationale: "Lifecycle handling lives in the base class.",
///     howToFix: "Declare the class as `final class MyViewModel: BaseViewModel`.",
///     badExample: "final class MyViewModel: ObservableObject { }",
///     goodExample: "final class MyViewModel: BaseViewModel { }"
/// )) { $0.inherits(from: "BaseViewModel") }
/// ```
///
/// Set every descriptive field. A rule that explains itself lets humans and
/// AI agents correct a violation without a search through the history. Pass an
/// empty string only when a field does not apply.
public struct Rule: Codable, Equatable {
    /// When agents must learn the rule. The value does not change enforcement.
    /// Every rule runs and fails in the same way. The value only says where the
    /// generated documentation shows the rule.
    public enum Disclosure: String, Codable, Equatable {
        /// The rule applies to almost every task. The generated skill shows it
        /// on its first page. Use it for a small number of rules.
        case upfront

        /// The rule applies to one layer. The generated skill lists it in the
        /// file of that layer. This is the default.
        case progressive

        /// The generated skill does not list the rule. The test failure explains
        /// the fix.
        case deferred
    }

    /// The stable identifier of the rule, for example `"view-models-inherit-base"`.
    ///
    /// The default is the file name of the rule in kebab case
    /// (`ViewModelsInheritBase.swift` → `view-models-inherit-base`). Set it to
    /// choose a better name, or when one file defines more than one rule. Use
    /// lowercase letters, digits, and single hyphens. Do not change an id after
    /// you publish it.
    public let id: String

    /// One sentence that says what the rule checks, for example
    /// `"ViewModels must inherit from BaseViewModel."`.
    public let title: String

    /// The layer of the rule, for example `"viewmodel"` or `"networking"`.
    /// Prefer the initializer that takes a project ``RuleCategory`` enum. An
    /// empty string means that the rule has no category.
    public let category: String

    /// When agents must learn the rule (see ``Disclosure``).
    public let disclosure: Disclosure

    /// Why the rule exists: the architectural reasoning.
    public let rationale: String

    /// How to correct a violation.
    public let howToFix: String

    /// A short code sample that violates the rule.
    public let badExample: String

    /// A short code sample that obeys the rule.
    public let goodExample: String

    public init(
        id: String? = nil,
        title: String,
        category: String,
        disclosure: Disclosure = .progressive,
        rationale: String,
        howToFix: String,
        badExample: String,
        goodExample: String,
        file: StaticString = #filePath
    ) {
        self.id = id ?? Rule.derivedId(fromFilePath: file)
        self.title = title
        self.category = category
        self.disclosure = disclosure
        self.rationale = rationale
        self.howToFix = howToFix
        self.badExample = badExample
        self.goodExample = goodExample
    }

    /// The preferred initializer. It takes the category from the project's
    /// ``RuleCategory`` enum, so the compiler checks the spelling.
    public init(
        id: String? = nil,
        title: String,
        category: some RuleCategory,
        disclosure: Disclosure = .progressive,
        rationale: String,
        howToFix: String,
        badExample: String,
        goodExample: String,
        file: StaticString = #filePath
    ) {
        self.init(
            id: id,
            title: title,
            category: category.categoryName,
            disclosure: disclosure,
            rationale: rationale,
            howToFix: howToFix,
            badExample: badExample,
            goodExample: goodExample,
            file: file
        )
    }

    /// `SomeRuleName.swift` → `some-rule-name`. An acronym run stays together.
    /// Set an explicit id when the derived id is not readable (for example with `DTOs`).
    internal static func derivedId(fromFilePath file: StaticString) -> String {
        var name = URL(fileURLWithPath: file.description)
            .deletingPathExtension()
            .lastPathComponent
        for regex in [acronymBoundary, wordBoundary] {
            name = regex.stringByReplacingMatches(
                in: name,
                range: NSRange(name.startIndex..., in: name),
                withTemplate: "$1-$2"
            )
        }
        return name.lowercased()
    }

    private static let acronymBoundary = try! NSRegularExpression(pattern: "([A-Z]+)([A-Z][a-z])")
    private static let wordBoundary = try! NSRegularExpression(pattern: "([a-z0-9])([A-Z])")

    /// The violation message when the assertion gives no explicit message:
    /// the rationale, or the title or the id when the rationale is empty.
    internal var defaultMessage: String {
        if !rationale.isEmpty { return rationale }
        return title.isEmpty ? id : title
    }

    /// The rule as text for humans. Reporters and assertion messages show it.
    /// The first line shows the title, or the id when the title is empty.
    public var formatted: String {
        var sections: [String] = []
        sections.append("RULE: \(title.isEmpty ? id : title)")
        if !rationale.isEmpty { sections.append("WHY: \(rationale)") }
        if !howToFix.isEmpty { sections.append("HOW TO FIX: \(howToFix)") }
        if !badExample.isEmpty { sections.append("❌ BAD:\n\(badExample)") }
        if !goodExample.isEmpty { sections.append("✅ GOOD:\n\(goodExample)") }
        return sections.joined(separator: "\n\n")
    }
}
