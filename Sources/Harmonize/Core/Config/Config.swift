//
//  Config.swift
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
import Yams

/// The model representation for `.harmonize.yaml`.
/// This model is that simple because it is more of a workaround to get the project working directory.
///
/// Harmonize shall work normally even if these properties are empty because we have APIs to resolve packages, folders
/// and test folders.
public struct Config: Equatable {
    /// The collection of paths were Harmonize will not include when searching for Swift Files.
    public let excludePaths: [String]
    
    public init(excludePaths: [String]) {
        self.excludePaths = excludePaths
    }
}

// MARK: - FileError

public extension Config {
    enum FileError: Error, Equatable, CustomStringConvertible {
        case configFileNotFound
        case noPermissionToViewFile
        
        public var description: String {
            switch self {
            case .configFileNotFound:
                "Harmonize is unable to locate the `.harmonize.yaml` file. Did you create it in the top-level directory of your project?"
            case .noPermissionToViewFile:
                """
                Harmonize is unable to read the files of your project. This may be caused by App Sandboxing.
                If your project is located in the Documents folder, you can try moving it to another folder or you can also try disabling Sandboxing.
                """
            }
        }
    }
}

// MARK: - Decodable

extension Config: Decodable {
    private enum CodingKeys: String, CodingKey {
        case excludes
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let excludes = try? values.decode([String].self, forKey: .excludes)
        
        excludePaths = excludes ?? []
    }
    
    internal init(file: StaticString) {
        let resolveProjectConfigFilePath = ResolveProjectConfigFilePath()
        let content = try! String(contentsOfFile: resolveProjectConfigFilePath(file).path)
        try! self.init(content)
    }
    
    internal init(_ yaml: String) throws {
        guard !yaml.isEmpty else {
            excludePaths = []
            return
        }
        
        let decoded = try YAMLDecoder().decode(Self.self, from: yaml)
        excludePaths = decoded.excludePaths
    }
}
