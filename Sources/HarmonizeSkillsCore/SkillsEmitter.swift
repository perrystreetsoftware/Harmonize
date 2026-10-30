//
//  SkillsEmitter.swift
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

/// One generated file, with its path relative to the skill directory.
public struct GeneratedFile: Equatable {
    public let relativePath: String
    public let content: String

    public init(relativePath: String, content: String) {
        self.relativePath = relativePath
        self.content = content
    }
}

public struct RenderResult {
    public let files: [GeneratedFile]
    public let warnings: [String]
}

public struct WriteSummary: Equatable {
    public var written: [String] = []
    public var unchanged: [String] = []
    public var removed: [String] = []

    public init() {}
}

/// Renders the static catalog as one agent skill (agentskills.io format)
/// with three levels of disclosure:
///
/// ```
/// <output>/<name>/
///   SKILL.md                         description: layer keywords + .upfront titles
///                                    body: the .upfront rules and a table of layers
///   references/<category>.md         the .progressive rule titles of one layer, linked
///   references/<category>/<id>.md    one rule: why, how to fix, bad and good example, source
/// ```
///
/// The emitter does not render `.deferred` rules. The test failure explains them.
public enum SkillsEmitter {
    public static let maxDescriptionLength = 1024
    public static let maxNameLength = 64

    public static func render(_ catalog: StaticCatalog, config: ProjectConfig, generatorHint: String) throws -> RenderResult {
        let name = try validatedSkillName(config.skillName)
        let skillDirectory = config.skillsOutput.appendingPathComponent(name)
        var files: [GeneratedFile] = []
        var warnings: [String] = []

        for category in catalog.documentedCategories {
            let folder = try folderName(forCategory: category)
            let rules = catalog.progressiveRules(in: category)
            let description: String
            if let known = catalog.categories[category]?.description, !known.isEmpty {
                description = known
            } else {
                warnings.append("category '\(category)' has no categoryDescription; using a generic one")
                description = "Harmonize architecture rules for the \(category) layer. Read before you write code in this layer."
            }

            var layer: [String] = []
            layer.append("# \(category) rules")
            layer.append("")
            layer.append(description)
            layer.append("")
            for rule in rules {
                layer.append("- [\(linkText(singleLine(rule.title)))](\(folder)/\(rule.id).md)")
            }
            layer.append("")
            files.append(GeneratedFile(relativePath: "references/\(folder).md", content: layer.joined(separator: "\n")))

            for rule in rules {
                files.append(GeneratedFile(
                    relativePath: "references/\(folder)/\(rule.id).md",
                    content: ruleFile(rule, in: skillDirectory.appendingPathComponent("references/\(folder)"))
                ))
            }
        }

        for rule in catalog.upfrontRules {
            let path = try rulePath(rule)
            guard !files.contains(where: { $0.relativePath == path }) else { continue }
            files.append(GeneratedFile(
                relativePath: path,
                content: ruleFile(rule, in: skillDirectory.appendingPathComponent(path).deletingLastPathComponent())
            ))
        }

        files.insert(try skillFile(catalog, name: name, generatorHint: generatorHint), at: 0)
        return RenderResult(files: files, warnings: warnings)
    }

    // MARK: - SKILL.md

    private static func skillFile(_ catalog: StaticCatalog, name: String, generatorHint: String) throws -> GeneratedFile {
        let upfront = catalog.upfrontRules
        let layers = catalog.documentedCategories

        var description = "Architecture rules enforced by Harmonize lint rules (tests that fail CI)"
        if !layers.isEmpty {
            description += " for these layers: " + layers.joined(separator: ", ")
        }
        description += ". Use before you create or change Swift code in one of these layers. Open the layer file that this skill lists, then the rule files that you need."
        if !upfront.isEmpty {
            description += " Always: " + upfront.map { trimmingTrailingPeriod(singleLine($0.title)) }.joined(separator: "; ") + "."
        }
        if description.count > maxDescriptionLength {
            throw HarmonizeSkillsError("the skill description is \(description.count) characters; the limit is \(maxDescriptionLength). Change some `.upfront` rules to `.progressive`.")
        }

        var body: [String] = []
        body.append("# Harmonize architecture rules")
        body.append("")
        body.append(generatedMarker(generatorHint))
        body.append("")
        body.append("This project enforces its architecture with [Harmonize](https://github.com/perrystreetsoftware/Harmonize) lint rules. The rules run as unit tests. CI fails on any violation. Run the rules after you implement a task.")
        body.append("")
        if !upfront.isEmpty {
            body.append("## Always")
            body.append("")
            for rule in upfront {
                body.append("### \(singleLine(rule.title))")
                if !rule.howToFix.isEmpty {
                    body.append("")
                    body.append("**How to fix:** \(rule.howToFix.trimmingCharacters(in: .whitespacesAndNewlines))")
                }
                body.append("")
                body.append("Full rule: [\(rule.id)](\(try rulePath(rule)))")
                body.append("")
            }
        }
        body.append("## Rules by layer")
        body.append("")
        body.append("Before you write code in a layer, read its file. Each file lists the rules of that layer. Each rule file gives the rationale, the fix, and examples.")
        body.append("")
        for category in layers {
            let folder = try folderName(forCategory: category)
            let count = catalog.progressiveRules(in: category).count
            let description = catalog.categories[category]?.description ?? ""
            let suffix = description.isEmpty ? "" : ": \(description)"
            body.append("- [\(category)](references/\(folder).md) (\(count) rule\(count == 1 ? "" : "s"))\(suffix)")
        }
        body.append("")
        body.append("Harmonize also enforces the rules that are not listed here. Their test failures explain the fix.")

        let content = """
        ---
        name: \(name)
        description: \(yamlQuoted(description))
        ---
        \(body.joined(separator: "\n"))
        """
        return GeneratedFile(relativePath: "SKILL.md", content: content)
    }

    // MARK: - Rule files

    private static func ruleFile(_ rule: StaticRule, in directory: URL) -> String {
        var lines: [String] = []
        lines.append("# \(singleLine(rule.title))")
        lines.append("")
        lines.append("`\(rule.id)` · layer: \(rule.category.isEmpty ? "all" : rule.category) · disclosure: \(rule.disclosure)")
        if !rule.rationale.isEmpty {
            lines.append("")
            lines.append("## Why")
            lines.append("")
            lines.append(rule.rationale.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if !rule.howToFix.isEmpty {
            lines.append("")
            lines.append("## How to fix")
            lines.append("")
            lines.append(rule.howToFix.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if !rule.badExample.isEmpty {
            lines.append("")
            lines.append("## Bad")
            lines.append("")
            lines.append("```swift")
            lines.append(trimmingTrailingWhitespace(rule.badExample))
            lines.append("```")
        }
        if !rule.goodExample.isEmpty {
            lines.append("")
            lines.append("## Good")
            lines.append("")
            lines.append("```swift")
            lines.append(trimmingTrailingWhitespace(rule.goodExample))
            lines.append("```")
        }
        lines.append("")
        lines.append("Source: [\(rule.definedIn.lastPathComponent)](\(relativePath(to: rule.definedIn.path, from: directory)))")
        lines.append("")
        return lines.joined(separator: "\n")
    }

    // MARK: - Names and paths

    static func rulePath(_ rule: StaticRule) throws -> String {
        "references/\(try folderName(forCategory: rule.category))/\(rule.id).md"
    }

    /// The reference folder for a category. An empty category (an `.upfront`
    /// rule that applies everywhere) goes to `all`.
    static func folderName(forCategory category: String) throws -> String {
        if category.isEmpty { return "all" }
        let folder = String(category.lowercased().map { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" ? $0 : "-" })
        guard !folder.isEmpty, folder != "all" else {
            throw HarmonizeSkillsError("category '\(category)' cannot be used as a folder name")
        }
        return folder
    }

    /// Enforces the agentskills.io name rules: 1-64 characters, lowercase
    /// letters, digits and hyphens, no leading, trailing or double hyphen.
    static func validatedSkillName(_ name: String) throws -> String {
        let valid = !name.isEmpty
            && name.count <= maxNameLength
            && name.allSatisfy { ($0.isLetter && $0.isLowercase) || $0.isNumber || $0 == "-" }
            && !name.hasPrefix("-") && !name.hasSuffix("-") && !name.contains("--")
        guard valid else {
            throw HarmonizeSkillsError("skill name '\(name)' is not valid: use 1-\(maxNameLength) lowercase letters, digits and single hyphens (set `skills.name` in .harmonize.yaml)")
        }
        return name
    }

    /// A title is one sentence, but a multi-line string literal in the source
    /// can split it. Headings, links and the description need one line.
    static func singleLine(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// Markdown link text: square brackets would end the link early.
    static func linkText(_ text: String) -> String {
        text.replacingOccurrences(of: "[", with: "\\[").replacingOccurrences(of: "]", with: "\\]")
    }

    /// Only `SKILL.md` carries the marker. The layer and rule files are
    /// short, and the marker would repeat on every one of them.
    private static func generatedMarker(_ hint: String) -> String {
        "<!-- Generated by harmonize-skills from the Harmonize rule sources. Do not edit; regenerate with `\(hint)`. -->"
    }

    // MARK: - Writing

    /// Writes the files that changed and removes the files under `references/`
    /// that this run did not produce. The generator owns the skill directory.
    /// Do not add files to it by hand.
    public static func write(_ files: [GeneratedFile], config: ProjectConfig) throws -> WriteSummary {
        let fileManager = FileManager.default
        let skillDirectory = config.skillsOutput.appendingPathComponent(try validatedSkillName(config.skillName))
        var summary = WriteSummary()
        let produced = Set(files.map(\.relativePath))

        for file in files {
            let url = skillDirectory.appendingPathComponent(file.relativePath)
            let content = file.content + "\n"
            if let existing = try? String(contentsOf: url, encoding: .utf8), existing == content {
                summary.unchanged.append(file.relativePath)
                continue
            }
            do {
                try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try content.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                throw HarmonizeSkillsError("cannot write \(url.path): \(error)")
            }
            summary.written.append(file.relativePath)
        }

        let referencesDirectory = skillDirectory.appendingPathComponent("references")
        if let enumerator = fileManager.enumerator(atPath: referencesDirectory.path) {
            var stale: [String] = []
            for case let relative as String in enumerator {
                var isDirectory: ObjCBool = false
                let path = referencesDirectory.appendingPathComponent(relative).path
                guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory), !isDirectory.boolValue else { continue }
                if !produced.contains("references/\(relative)") { stale.append(relative) }
            }
            for relative in stale.sorted() {
                do {
                    try fileManager.removeItem(at: referencesDirectory.appendingPathComponent(relative))
                } catch {
                    throw HarmonizeSkillsError("cannot remove stale file references/\(relative): \(error)")
                }
                summary.removed.append("references/\(relative)")
            }
            removeEmptyDirectories(under: referencesDirectory)
        }
        return summary
    }

    private static func removeEmptyDirectories(under directory: URL) {
        let fileManager = FileManager.default
        guard let entries = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey]) else { return }
        for entry in entries {
            let isDirectory = (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            guard isDirectory else { continue }
            removeEmptyDirectories(under: entry)
            if (try? fileManager.contentsOfDirectory(atPath: entry.path))?.isEmpty == true {
                try? fileManager.removeItem(at: entry)
            }
        }
    }

    // MARK: - Text helpers

    private static func yamlQuoted(_ text: String) -> String {
        let oneLine = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
        return "\"\(oneLine)\""
    }

    private static func trimmingTrailingPeriod(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasSuffix(".") ? String(trimmed.dropLast()) : trimmed
    }

    private static func trimmingTrailingWhitespace(_ text: String) -> String {
        var result = Substring(text)
        while let last = result.last, last.isWhitespace { result = result.dropLast() }
        return String(result)
    }
}
