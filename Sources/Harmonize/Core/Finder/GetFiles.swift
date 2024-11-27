//
//  GetFiles.swift
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

/// The internal implementation responsible for Swift File lookup through the source.
internal final class GetFiles {
    private let workingDirectory: URL
    private let config: Config

    init(_ file: StaticString) {
        self.workingDirectory = try! ResolveProjectWorkingDirectory()(file)
        self.config = Config(file: file)
    }
    
    init(_ workingDirectory: URL) {
        self.workingDirectory = workingDirectory
        self.config = Config(excludePaths: [])
    }
    
    internal func callAsFunction(
        folder: String?,
        inclusions: [String],
        exclusions: [String]
    ) -> [SwiftSourceCode] {
        var url = workingDirectory
        
        if let folder = folder, !folder.isEmpty {
            url = workingDirectory.appendingPathComponent(folder).standardized
            
            var isDirectory: ObjCBool = false
            
            let pathExistsAndIsDirectory = FileManager.default.fileExists(
                atPath: url.absoluteString,
                isDirectory: &isDirectory
            ) && isDirectory.boolValue
            
            if !pathExistsAndIsDirectory {
                return getFolders(
                    in: workingDirectory,
                    containing: folder
                )
                .flatMap { folder in
                    findSwiftFiles(
                        url: folder,
                        inclusions: inclusions,
                        exclusions: exclusions
                    )
                }
            }
        }
        
        return findSwiftFiles(url: url, inclusions: inclusions, exclusions: exclusions)
    }
    
    private func findSwiftFiles(
        url: URL,
        inclusions: [String],
        exclusions: [String]
    ) -> [SwiftSourceCode] {
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path {
            assert(!url.absoluteString.contains(documentsPath), "Harmonize does not work in the Documents folder because of MacOS sandboxing")
        }

        let urls = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )?
        .compactMap { $0 as? URL }
        .filter {
            includes(
                file: $0,
                basePath: url,
                inclusions: inclusions,
                exclusions: config.excludePaths + exclusions
            )
        } ?? []
        
        guard !urls.isEmpty else { return [] }
        
        var files = [SwiftSourceCode]()
        
        let queue = DispatchQueue(label: "harmonize.files.sync")

        DispatchQueue.concurrentPerform(iterations: urls.count) { index in
            if let file = SwiftSourceCode(url: urls[index]) {
                queue.sync {
                    files.append(file)
                }
            }
        }

        return files
    }
    
    private func includes(
        file: URL,
        basePath: URL,
        inclusions: [String],
        exclusions: [String]
    ) -> Bool {
        guard !file.hasDirectoryPath, file.pathExtension == "swift" else { return false }
        
        let parentUrlString = file.absoluteString.replacingOccurrences(of: basePath.absoluteString, with: "")
        let parentUrl = URL(fileURLWithPath: parentUrlString)
        
        func fileOrParentIsContainedInArray(array: [String]) -> Bool {
            array.contains { element in
                if element.hasSuffix(".swift") {
                    return element == file.lastPathComponent
                }
                
                return parentUrl.pathComponents.contains { $0.hasSuffix(element) }
            }
        }
        
        if fileOrParentIsContainedInArray(array: exclusions) {
            return false
        }

        if !inclusions.isEmpty {
            return fileOrParentIsContainedInArray(array: inclusions)
        }
                
        return true
    }
    
    /// The class responsible for looking through a given directory URL
    /// and finding all folders matching the given path component.
    ///
    /// Mostly useful for modularized projects aiming to lint specific repeating folders in different modules.
    private func getFolders(
        in directory: URL,
        containing pathComponent: String
    ) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        else { return [] }
        
        var folders = [URL]()
        
        for case let url as URL in enumerator {
            let isDirectory = try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory
            
            if isDirectory ?? false {
                if url.pathComponents.joined(separator: "/").contains(pathComponent) {
                    folders.append(url)
                    enumerator.skipDescendants()
                }
            }
        }
        
        return folders
    }
}
