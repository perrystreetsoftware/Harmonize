//
//  ProjectConfig.swift
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
import Yams

/// The generator settings from the `.harmonize.yaml` file of the project:
///
/// ```yaml
/// skills:
///   output: .github/skills   # default: .agents/skills
///   name: harmonize          # default: harmonize (the skill folder and skill name)
/// ```
public struct ProjectConfig: Equatable {
    public static let defaultOutput = ".agents/skills"
    public static let defaultName = "harmonize"

    /// The directory that contains `.harmonize.yaml`.
    public let repoRoot: URL

    /// The directory that holds the skill folder.
    public let skillsOutput: URL

    /// The skill folder name, also the skill `name`.
    public let skillName: String

    public init(repoRoot: URL, skillsOutput: URL, skillName: String) {
        self.repoRoot = repoRoot
        self.skillsOutput = skillsOutput
        self.skillName = skillName
    }

    /// Searches from `startDirectory` toward the root for the directory that
    /// contains `.harmonize.yaml`, as the Harmonize engine does.
    public static func load(startingAt startDirectory: URL) throws -> ProjectConfig {
        var directory = canonicalURL(startDirectory)
        while true {
            let candidate = directory.appendingPathComponent(".harmonize.yaml")
            if FileManager.default.fileExists(atPath: candidate.path) {
                return try parse(configFile: candidate, repoRoot: directory)
            }
            // At the file system root, `deletingLastPathComponent()` gives `/..`.
            // Compare the standardized paths to stop the search.
            let parent = directory.deletingLastPathComponent().standardized
            if directory.pathComponents.count <= 1 || parent.path == directory.path {
                throw HarmonizeSkillsError("cannot find .harmonize.yaml in \(startDirectory.path) or any parent directory")
            }
            directory = parent
        }
    }

    private static func parse(configFile: URL, repoRoot: URL) throws -> ProjectConfig {
        var output = defaultOutput
        var name = defaultName

        let text = try String(contentsOf: configFile, encoding: .utf8)
        if !text.isEmpty {
            let yaml: Any?
            do {
                yaml = try Yams.load(yaml: text)
            } catch {
                throw HarmonizeSkillsError("cannot parse \(configFile.path): \(error)")
            }
            if let root = yaml as? [String: Any], let skills = root["skills"] as? [String: Any] {
                if let value = skills["output"] as? String, !value.isEmpty { output = value }
                if let value = skills["name"] as? String, !value.isEmpty { name = value }
            }
        }

        return ProjectConfig(
            repoRoot: repoRoot,
            skillsOutput: URL(fileURLWithPath: output, relativeTo: repoRoot).absoluteURL.standardized,
            skillName: name
        )
    }
}
