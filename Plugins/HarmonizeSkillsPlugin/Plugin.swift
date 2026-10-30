//
//  Plugin.swift
//  HarmonizeSkillsPlugin
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
import PackagePlugin

/// Generates the agent skill from the rule sources of the package that runs it:
///
/// ```sh
/// swift package --package-path <rules-package> \
///   --allow-writing-to-package-directory --allow-writing-to-directory <skills-dir> \
///   harmonize-skills
/// ```
///
/// It searches from the package toward the root for `.harmonize.yaml` and reads
/// the output directory and the skill name from it. It needs no build and no
/// test run. It reads the rule metadata from the `Rule(...)` declarations.
@main
struct HarmonizeSkillsPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let tool = try context.tool(named: "HarmonizeSkills")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool.path.string)
        process.arguments = ["--package-dir", context.package.directory.string] + arguments
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            Diagnostics.error("harmonize-skills exited with code \(process.terminationStatus)")
            return
        }
    }
}
