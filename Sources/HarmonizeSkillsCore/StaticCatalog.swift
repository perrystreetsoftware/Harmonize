//
//  StaticCatalog.swift
//  HarmonizeSkillsCore
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
import SwiftParser
import SwiftSyntax

/// The metadata of a rule as the source declares it. The loader reads it
/// without a build or a test run. Every `Rule(...)` argument must be a literal:
/// a string literal or an enum case. Any other value is an error that names
/// its location.
public struct StaticRule: Equatable {
    public let id: String
    public let title: String
    public let category: String
    public let disclosure: String
    public let rationale: String
    public let howToFix: String
    public let badExample: String
    public let goodExample: String
    public let definedIn: URL

    public init(
        id: String,
        title: String,
        category: String,
        disclosure: String,
        rationale: String,
        howToFix: String,
        badExample: String,
        goodExample: String,
        definedIn: URL
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.disclosure = disclosure
        self.rationale = rationale
        self.howToFix = howToFix
        self.badExample = badExample
        self.goodExample = goodExample
        self.definedIn = definedIn
    }
}

public struct StaticCategory: Equatable {
    public let caseName: String
    public let name: String
    public let description: String

    public init(caseName: String, name: String, description: String) {
        self.caseName = caseName
        self.name = name
        self.description = description
    }
}

public struct StaticCatalog: Equatable {
    public let rules: [StaticRule]

    /// Keyed by category name (the enum raw value).
    public let categories: [String: StaticCategory]

    public init(rules: [StaticRule], categories: [String: StaticCategory]) {
        self.rules = rules
        self.categories = categories
    }

    public var upfrontRules: [StaticRule] {
        rules.filter { $0.disclosure == "upfront" }.sorted { $0.id < $1.id }
    }

    public func progressiveRules(in category: String) -> [StaticRule] {
        rules.filter { $0.category == category && $0.disclosure == "progressive" }.sorted { $0.id < $1.id }
    }

    /// Categories that have `.progressive` rules, sorted.
    public var documentedCategories: [String] {
        Set(rules.filter { $0.disclosure == "progressive" }.map(\.category)).sorted()
    }
}

public enum StaticCatalogLoader {
    /// Reads every `Rule(...)` declaration and every `RuleCategory` enum under
    /// `<rulesPackage>/Tests`.
    public static func load(rulesPackage: URL) throws -> StaticCatalog {
        let files = swiftFiles(under: canonicalURL(rulesPackage).appendingPathComponent("Tests"))
        var categoriesByCase: [String: StaticCategory] = [:]
        var rawRules: [(file: URL, call: RuleCall)] = []
        var problems: [String] = []

        for file in files {
            guard let source = try? String(contentsOf: file, encoding: .utf8),
                  source.contains("Rule(") || source.contains("RuleCategory") else { continue }
            let tree = Parser.parse(source: source)
            let converter = SourceLocationConverter(fileName: file.path, tree: tree)

            let enumVisitor = CategoryEnumVisitor(viewMode: .sourceAccurate)
            enumVisitor.walk(tree)
            for category in enumVisitor.categories {
                categoriesByCase[category.caseName] = category
            }

            let ruleVisitor = RuleCallVisitor(file: file, converter: converter)
            ruleVisitor.walk(tree)
            problems.append(contentsOf: ruleVisitor.problems)
            rawRules.append(contentsOf: ruleVisitor.calls.map { (file, $0) })
        }

        if !problems.isEmpty {
            throw HarmonizeSkillsError(problems.joined(separator: "\n"))
        }

        // Resolve categories and ids. Derived ids that collide get -2, -3 and so
        // on in file order. The runtime catalog does the same in registration order.
        var seenIds: [String: Int] = [:]
        var rules: [StaticRule] = []
        for (file, call) in rawRules {
            let categoryName: String
            switch call.category {
            case .literal(let value): categoryName = value
            case .enumCase(let caseName): categoryName = categoriesByCase[caseName]?.name ?? caseName
            }

            var id = call.id ?? derivedId(fromFileName: file.deletingPathExtension().lastPathComponent)
            if let count = seenIds[id] {
                seenIds[id] = count + 1
                id = "\(id)-\(count + 1)"
            } else {
                seenIds[id] = 1
            }

            rules.append(StaticRule(
                id: id,
                title: call.title,
                category: categoryName,
                disclosure: call.disclosure,
                rationale: call.rationale,
                howToFix: call.howToFix,
                badExample: call.badExample,
                goodExample: call.goodExample,
                definedIn: file
            ))
        }

        try checkCategoryNames(rules.map(\.category))

        var categoriesByName: [String: StaticCategory] = [:]
        for category in categoriesByCase.values { categoriesByName[category.name] = category }
        return StaticCatalog(rules: rules, categories: categoriesByName)
    }

    /// Two category names that differ only in case or punctuation ("viewmodel"
    /// and "view-model") would split one layer across two files.
    static func checkCategoryNames(_ names: [String]) throws {
        var byNormalized: [String: Set<String>] = [:]
        for name in names where !name.isEmpty {
            let key = name.lowercased().filter { $0.isLetter || $0.isNumber }
            byNormalized[key, default: []].insert(name)
        }
        let collisions = byNormalized.values.filter { $0.count > 1 }.map { $0.sorted().joined(separator: "' vs '") }.sorted()
        if !collisions.isEmpty {
            throw HarmonizeSkillsError("category names collide: '\(collisions.joined(separator: "'; '"))'. Use one spelling (define one RuleCategory enum).")
        }
    }

    private static func swiftFiles(under directory: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }
        return enumerator.compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" }
            .sorted { $0.path < $1.path }
    }

    private static let acronymBoundary = try! NSRegularExpression(pattern: "([A-Z]+)([A-Z][a-z])")
    private static let wordBoundary = try! NSRegularExpression(pattern: "([a-z0-9])([A-Z])")

    /// Mirrors `Rule.derivedId(fromFilePath:)` in the Harmonize library:
    /// `SomeRuleName` becomes `some-rule-name`.
    public static func derivedId(fromFileName name: String) -> String {
        var result = name
        for regex in [acronymBoundary, wordBoundary] {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "$1-$2"
            )
        }
        return result.lowercased()
    }
}

// MARK: - Rule(...) calls

private struct RuleCall {
    enum Category {
        case literal(String)
        case enumCase(String)
    }

    let id: String?
    let title: String
    let category: Category
    let disclosure: String
    let rationale: String
    let howToFix: String
    let badExample: String
    let goodExample: String
}

private final class RuleCallVisitor: SyntaxVisitor {
    private let file: URL
    private let converter: SourceLocationConverter
    var calls: [RuleCall] = []
    var problems: [String] = []

    init(file: URL, converter: SourceLocationConverter) {
        self.file = file
        self.converter = converter
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard isRuleInitializer(node.calledExpression) else { return .visitChildren }

        var strings: [String: String] = [:]
        var members: [String: String] = [:]
        for argument in node.arguments {
            guard let label = argument.label?.text else { continue }
            if let literal = argument.expression.as(StringLiteralExprSyntax.self) {
                guard let value = literal.representedLiteralValue else {
                    report(at: argument, "argument '\(label)' must be a plain string literal (no interpolation)")
                    return .skipChildren
                }
                strings[label] = value
            } else if let member = argument.expression.as(MemberAccessExprSyntax.self) {
                members[label] = member.declName.baseName.text
            } else {
                report(at: argument, "argument '\(label)' must be a literal, so that skills can be generated without running the rules")
                return .skipChildren
            }
        }

        guard let title = strings["title"] else {
            report(at: node, "Rule(...) has no literal 'title'")
            return .skipChildren
        }
        let category: RuleCall.Category
        if let literal = strings["category"] {
            category = .literal(literal)
        } else if let caseName = members["category"] {
            category = .enumCase(caseName)
        } else {
            report(at: node, "Rule(...) has no 'category'")
            return .skipChildren
        }

        calls.append(RuleCall(
            id: strings["id"],
            title: title,
            category: category,
            disclosure: members["disclosure"] ?? "progressive",
            rationale: strings["rationale"] ?? "",
            howToFix: strings["howToFix"] ?? "",
            badExample: strings["badExample"] ?? "",
            goodExample: strings["goodExample"] ?? ""
        ))
        return .skipChildren
    }

    private func isRuleInitializer(_ expression: ExprSyntax) -> Bool {
        if let reference = expression.as(DeclReferenceExprSyntax.self) {
            return reference.baseName.text == "Rule"
        }
        if let member = expression.as(MemberAccessExprSyntax.self) {
            return member.declName.baseName.text == "Rule"
        }
        return false
    }

    private func report(at node: some SyntaxProtocol, _ message: String) {
        let line = node.startLocation(converter: converter).line
        problems.append("\(file.path):\(line): \(message)")
    }
}

// MARK: - RuleCategory enum

private final class CategoryEnumVisitor: SyntaxVisitor {
    var categories: [StaticCategory] = []

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        let conformsToRuleCategory = node.inheritanceClause?.inheritedTypes.contains { inherited in
            inherited.type.as(IdentifierTypeSyntax.self)?.name.text == "RuleCategory"
        } ?? false
        guard conformsToRuleCategory else { return .visitChildren }

        var rawValues: [(caseName: String, rawValue: String)] = []
        var descriptions: [String: String] = [:]

        for member in node.memberBlock.members {
            if let enumCase = member.decl.as(EnumCaseDeclSyntax.self) {
                for element in enumCase.elements {
                    let name = element.name.text
                    let raw = element.rawValue?.value.as(StringLiteralExprSyntax.self)?.representedLiteralValue
                    rawValues.append((name, raw ?? name))
                }
            } else if let variable = member.decl.as(VariableDeclSyntax.self),
                      variable.bindings.contains(where: { $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "categoryDescription" }) {
                let switchVisitor = SwitchLiteralVisitor(viewMode: .sourceAccurate)
                switchVisitor.walk(variable)
                descriptions = switchVisitor.values
            }
        }

        for (caseName, rawValue) in rawValues {
            categories.append(StaticCategory(
                caseName: caseName,
                name: rawValue,
                description: descriptions[caseName] ?? ""
            ))
        }
        return .skipChildren
    }
}

/// Collects `case .x: "literal"` (or `return "literal"`) pairs from a switch.
private final class SwitchLiteralVisitor: SyntaxVisitor {
    var values: [String: String] = [:]

    override func visit(_ node: SwitchCaseSyntax) -> SyntaxVisitorContinueKind {
        guard let label = node.label.as(SwitchCaseLabelSyntax.self) else { return .skipChildren }
        let caseNames = label.caseItems.compactMap { item in
            item.pattern.as(ExpressionPatternSyntax.self)?
                .expression.as(MemberAccessExprSyntax.self)?
                .declName.baseName.text
        }
        guard let statement = node.statements.first?.item else { return .skipChildren }
        let literal = statement.as(StringLiteralExprSyntax.self)
            ?? statement.as(ReturnStmtSyntax.self)?.expression?.as(StringLiteralExprSyntax.self)
        guard let value = literal?.representedLiteralValue else { return .skipChildren }
        for caseName in caseNames { values[caseName] = value }
        return .skipChildren
    }
}
