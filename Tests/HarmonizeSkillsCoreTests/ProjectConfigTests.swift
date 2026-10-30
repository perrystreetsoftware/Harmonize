//
//  ProjectConfigTests.swift
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

final class ProjectConfigTests: XCTestCase {
    func testDefaultsWhenTheConfigHasNoSkillsSection() throws {
        let repository = try FixtureRepository(harmonizeYAML: "excludes:\n  - Pods\n")
        defer { repository.remove() }

        let config = try ProjectConfig.load(startingAt: repository.rulesPackage)

        XCTAssertEqual(config.repoRoot.path, repository.root.path)
        XCTAssertEqual(config.skillsOutput.path, repository.root.appendingPathComponent(".agents/skills").path)
        XCTAssertEqual(config.skillName, "harmonize")
    }

    func testReadsOutputAndNameAndWalksUpFromANestedDirectory() throws {
        let repository = try FixtureRepository(harmonizeYAML: "skills:\n  output: .github/skills\n  name: arch\n")
        defer { repository.remove() }

        let config = try ProjectConfig.load(startingAt: repository.rulesPackage.appendingPathComponent("Tests/RulesTests"))

        XCTAssertEqual(config.skillsOutput.path, repository.root.appendingPathComponent(".github/skills").path)
        XCTAssertEqual(config.skillName, "arch")
    }

    func testEmptyConfigFileUsesDefaults() throws {
        let repository = try FixtureRepository(harmonizeYAML: "")
        defer { repository.remove() }

        XCTAssertEqual(try ProjectConfig.load(startingAt: repository.rulesPackage).skillName, "harmonize")
    }

    func testMissingConfigFileFails() throws {
        let orphan = FileManager.default.temporaryDirectory.appendingPathComponent("no-config-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: orphan, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: orphan) }

        XCTAssertThrowsError(try ProjectConfig.load(startingAt: orphan)) { error in
            XCTAssertTrue("\(error)".contains(".harmonize.yaml"))
        }
    }
}
