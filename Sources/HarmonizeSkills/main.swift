//
//  main.swift
//  harmonize-skills
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

// Generates one agent skill from a project's Harmonize rule sources. It reads
// the `Rule(...)` declarations statically: no build of the project and no test
// run.
//
// Usage (normally through the plugin):
//     swift package --package-path <rules-package> harmonize-skills
//     harmonize-skills --package-dir <rules-package> [-o <skills-dir>] [--name <skill-name>]

import Foundation
import HarmonizeSkillsCore

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("harmonize-skills: error: \(message)\n".utf8))
    exit(1)
}

var packageDir: String?
var outputOverride: String?
var nameOverride: String?

var iterator = CommandLine.arguments.dropFirst().makeIterator()
while let argument = iterator.next() {
    switch argument {
    case "--package-dir":
        guard let value = iterator.next() else { fail("--package-dir requires a value") }
        packageDir = value
    case "-o", "--output":
        guard let value = iterator.next() else { fail("\(argument) requires a value") }
        outputOverride = value
    case "--name":
        guard let value = iterator.next() else { fail("--name requires a value") }
        nameOverride = value
    case "-h", "--help":
        print("""
        Usage: harmonize-skills --package-dir <rules-package> [-o <skills-dir>] [--name <skill-name>]

        Generates one skill folder: SKILL.md, references/<category>.md per category, and
        references/<category>/<rule-id>.md per rule. It reads the Rule(...) declarations
        statically (no build, no test run). Defaults come from .harmonize.yaml:
          skills: { output: \(ProjectConfig.defaultOutput), name: \(ProjectConfig.defaultName) }
        """)
        exit(0)
    default:
        fail("unexpected argument '\(argument)'")
    }
}

guard let packageDir else { fail("missing --package-dir (the rules package)") }
guard FileManager.default.fileExists(atPath: packageDir) else { fail("no such directory: \(packageDir)") }
let packageURL = canonicalURL(URL(fileURLWithPath: packageDir))

do {
    var config = try ProjectConfig.load(startingAt: packageURL)
    if outputOverride != nil || nameOverride != nil {
        config = ProjectConfig(
            repoRoot: config.repoRoot,
            skillsOutput: outputOverride.map { URL(fileURLWithPath: $0, relativeTo: config.repoRoot).absoluteURL.standardized } ?? config.skillsOutput,
            skillName: nameOverride ?? config.skillName
        )
    }

    let catalog = try StaticCatalogLoader.load(rulesPackage: packageURL)
    guard !catalog.rules.isEmpty else {
        fail("no Rule(...) declarations found under \(packageURL.appendingPathComponent("Tests").path)")
    }

    let relativePackage = relativePath(to: packageURL.path, from: config.repoRoot)
    let hint = "swift package --package-path \(relativePackage) harmonize-skills"
    let result = try SkillsEmitter.render(catalog, config: config, generatorHint: hint)
    for warning in result.warnings {
        FileHandle.standardError.write(Data("harmonize-skills: warning: \(warning)\n".utf8))
    }
    let summary = try SkillsEmitter.write(result.files, config: config)

    let skillRelative = relativePath(to: config.skillsOutput.appendingPathComponent(config.skillName).path, from: config.repoRoot)
    let layerCount = catalog.documentedCategories.count
    let ruleFileCount = result.files.count - 1 - layerCount
    print("harmonize-skills: \(catalog.rules.count) rules → skill \(skillRelative)/ with \(layerCount) layer files and \(ruleFileCount) rule files (\(summary.written.count) written, \(summary.unchanged.count) unchanged, \(summary.removed.count) removed)")
} catch let error as HarmonizeSkillsError {
    fail(error.message)
} catch {
    fail("\(error)")
}
