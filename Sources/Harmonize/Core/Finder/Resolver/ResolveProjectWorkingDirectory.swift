//
//  ResolveProjectWorkingDirectory.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
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
                if !configFileIsReadable(at: startingDirectory) {
                    throw Config.FileError.noPermissionToViewFile
                }
                
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
    
    private func configFileIsReadable(at url: URL) -> Bool {
        FileManager.default.isReadableFile(atPath: url.appendingPathComponent(".harmonize.yaml").path)
    }
}
