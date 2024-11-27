//
//  ResolveProjectWorkingDirectory.swift
//  Harmonize
//
//  Copyright 2024 Perry Street Software Inc.

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

/// This class is responsible for finding the project's working directory by searching through directories
/// until it locates the `.harmonize.yaml` file.
///
/// While we could search for `Package.swift`, that would only work for Swift Package Manager (SPM) projects.
/// Since there's no reliable way to automatically determine the project’s working directory, library's users needs
/// to include a `.harmonize.yaml` file so the library can locate the project’s root directory.
internal final class ResolveProjectWorkingDirectory {
    func callAsFunction(_ file: StaticString) throws -> URL {
        let currentFile = file.withUTF8Buffer {
            String(decoding: $0, as: UTF8.self)
        }
        
        var startingDirectory = URL(fileURLWithPath: currentFile)
        
        repeat {
            startingDirectory.appendPathComponent("..")
            startingDirectory.standardize()

            if configFileExists(at: startingDirectory) {
                return startingDirectory
            }
        } while startingDirectory.path != "/"
        
        throw Config.FileError.configFileNotFound
    }
    
    private func configFileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(
            atPath: url.appendingPathComponent(".harmonize.yaml").path
        )
    }
}
