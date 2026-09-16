//
//  WorkingDirectoryTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2026. All Rights Reserved.
//

import Foundation
import XCTest
@testable import Harmonize

final class WorkingDirectoryTests: XCTestCase {
    func testExclusionsIgnoreTheProcessWorkingDirectory() throws {
        let expected = Harmonize.productionCode().excluding("NoSuchFolder").sources().count
        XCTAssertGreaterThan(expected, 0)

        let directoryNamedLikeAnExclusion = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("Tests")
        try FileManager.default.createDirectory(at: directoryNamedLikeAnExclusion, withIntermediateDirectories: true)

        let originalWorkingDirectory = FileManager.default.currentDirectoryPath
        XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(directoryNamedLikeAnExclusion.path))
        defer { FileManager.default.changeCurrentDirectoryPath(originalWorkingDirectory) }

        let actual = Harmonize.productionCode().excluding("NoSuchFolderEither").sources().count

        XCTAssertEqual(actual, expected)
    }
}
