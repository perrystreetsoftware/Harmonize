//
//  ImportsTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import HarmonizeSemantics
import XCTest

final class ImportsTests: XCTestCase {
    private var sourceSyntax = """
    import Foundation.FoundationErrors
    import struct Foundation.AffineTransform
    import var Foundation.FoundationErrors.NSFileNoSuchFileError
    import protocol Combine.Subscriber
    import Combine
    @testable import Harmonize
    """.parsed()
    
    private lazy var visitor = {
        DeclarationsCollector(
            sourceCodeLocation: SourceCodeLocation(
                sourceFilePath: nil,
                sourceFileTree: sourceSyntax
            )
        )
    }()
    
    override func setUp() {
        visitor.walk(sourceSyntax)
    }
    
    func testParseImports() throws {
        let imports = visitor.imports
        let names = imports.map { $0.name }
        
        XCTAssertEqual(imports.count, 6)
        XCTAssertEqual(
            names,
            [
                "Foundation.FoundationErrors",
                "Foundation.AffineTransform",
                "Foundation.FoundationErrors.NSFileNoSuchFileError",
                "Combine.Subscriber",
                "Combine",
                "Harmonize"
            ]
        )
    }
    
    func testParseDeclarationImports() throws {
        let imports = visitor.imports
        let kinds = imports.map { $0.kind }
        
        XCTAssertEqual(kinds, [nil, .struct, .var, .protocol, .none, .none])
    }
    
    func testParseAttributes() throws {
        let imports = visitor.imports
        let attributes = imports.flatMap { $0.attributes }.map { $0.annotation }
        
        XCTAssertEqual(attributes, [.testable])
    }
}
