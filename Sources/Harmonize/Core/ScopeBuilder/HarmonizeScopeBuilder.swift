//
//  HarmonizeScopeBuilder.swift
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
import HarmonizeSemantics
import HarmonizeUtils

/// The default Harmonize scope builder implementation.
/// Provides all declarations and files from a given path.
internal class HarmonizeScopeBuilder {
    private let file: StaticString
    private let getFiles: GetFiles
    
    private var folder: String?
    private var includingOnly: [String] = []
    private var exclusions: [String] = []

    private func cacheKey(
        folder: String?,
        includingOnly: [String],
        exclusions: [String]
    ) -> String {
        let directoryKey = getFiles.workingDirectory.path
        let configKey = getFiles.config.excludePaths.joined(separator: ",")
        let folderKey = folder ?? "nil"
        let inclusionsKey = includingOnly.joined(separator: ",")
        let exclusionsKey = exclusions.joined(separator: ",")
        return "dir:\(directoryKey)|config:\(configKey)|folder:\(folderKey)|including:\(inclusionsKey)|excluding:\(exclusionsKey)"
    }

    /// Shared cache across all HarmonizeScopeBuilder instances.
    /// This allows different builders to share already-loaded files, avoiding redundant file discovery and parsing.
    private static let sharedFilesCache: ConcurrentDictionary<String, [SwiftSourceCode]> = ConcurrentDictionary()

    private var files: [SwiftSourceCode] {
        let key = cacheKey(folder: folder, includingOnly: includingOnly, exclusions: exclusions)

        if let cachedFiles = Self.sharedFilesCache[key] {
            return cachedFiles
        }

        let newFiles = getFiles(folder: folder, inclusions: includingOnly, exclusions: exclusions)
        Self.warmUp(newFiles)
        Self.sharedFilesCache[key] = newFiles

        return newFiles
    }

    /// Materializes syntax trees and declarations for all files in parallel.
    ///
    /// Parsing is CPU-bound and independent per file; left to the lazy
    /// `resolver`, it happens serially on first access and keeps all but one
    /// core idle. Each file is warmed by exactly one iteration, which is what
    /// makes touching its lazy `resolver` from here thread-safe. Files already
    /// parsed under another scope resolve instantly from the shared caches.
    private static func warmUp(_ files: [SwiftSourceCode]) {
        // concurrentPerform inherits the caller's QoS; XCTest builds test
        // suites at a low QoS, which confines the work to efficiency cores.
        // Hop to an explicit user-initiated context so the warm-up actually
        // fans out across performance cores.
        DispatchQueue.global(qos: .userInitiated).sync {
            DispatchQueue.concurrentPerform(iterations: files.count) { index in
                _ = files[index].resolver
            }
        }
    }

    internal init(
        file: StaticString,
        folder: String? = nil,
        includingOnly: [String] = [],
        exclusions: [String] = []
    ) {
        self.file = file
        self.getFiles = GetFiles(file)
        self.folder = folder
        self.includingOnly = includingOnly
        self.exclusions = exclusions
    }
}

// MARK: - On

extension HarmonizeScopeBuilder: On {
    func on(_ folder: String) -> Excluding {
        return self.copy(folder: folder)
    }
}

// MARK: - Excluding

extension HarmonizeScopeBuilder: Excluding {
    func excluding(_ excludes: String...) -> HarmonizeScope {
        return self.copy(exclusions: excludes + self.exclusions)
    }

    func excluding(_ excludes: [String]) -> HarmonizeScope {
        return self.copy(exclusions: excludes + self.exclusions)
    }
}

// MARK: - HarmonizeScope

extension HarmonizeScopeBuilder: HarmonizeScope {
    func classes(includeNested: Bool) -> [Class] {
        sources().flatMap {
            $0.classes(includeNested: includeNested)
        }
    }
    
    func classes() -> [Class] {
        classes(includeNested: false)
    }
    
    func enums(includeNested: Bool) -> [Enum] {
        sources().flatMap {
            $0.enums(includeNested: includeNested)
        }
    }
    
    func enums() -> [Enum] {
        enums(includeNested: false)
    }
    
    func extensions() -> [Extension] {
        sources().flatMap { $0.extensions() }
    }
    
    func sources() -> [SwiftSourceCode] {
        files
    }
    
    func functions(includeNested: Bool) -> [Function] {
        sources().flatMap { $0.functions(includeNested: includeNested) }
    }
    
    func functions() -> [Function] {
        functions(includeNested: false)
    }
    
    func imports() -> [Import] {
        sources().flatMap { $0.imports() }
    }
    
    func initializers() -> [Initializer] {
        sources().flatMap { $0.initializers() }
    }
    
    func variables(includeNested: Bool) -> [Variable] {
        sources().flatMap { $0.variables(includeNested: includeNested )}
    }
    
    func variables() -> [Variable] {
        variables(includeNested: false)
    }
    
    func protocols(includeNested: Bool) -> [ProtocolDeclaration] {
        sources().flatMap { $0.protocols(includeNested: includeNested )}
    }
    
    func protocols() -> [ProtocolDeclaration] {
        protocols(includeNested: false)
    }
    
    func structs(includeNested: Bool) -> [Struct] {
        sources().flatMap { $0.structs(includeNested: includeNested )}

    }
    
    func structs() -> [Struct] {
        structs(includeNested: false)
    }
}

extension HarmonizeScopeBuilder {
    public func copy(
        file: StaticString? = nil,
        folder: String? = nil,
        includingOnly: [String]? = nil,
        exclusions: [String]? = nil
    ) -> HarmonizeScopeBuilder {
        return HarmonizeScopeBuilder(
            file: file ?? self.file,
            folder: folder ?? self.folder,
            includingOnly: includingOnly ?? self.includingOnly,
            exclusions: exclusions ?? self.exclusions
        )
    }
}
