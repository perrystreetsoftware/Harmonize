//
//  SwitchTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import HarmonizeSemantics
import XCTest
import SwiftSyntax

final class SwitchTests: XCTestCase {
    private var sourceSyntax = """
    public final class ViewController {
        private var state: ViewState = .loading
        private var handler: Handler = UiViewHandler()
    
        public func onViewAppear() {
            switch state {
            case .loading:
                self.showLoading()
            case .success:
                handler.post {
                    self.hideLoading()
                }
            }
        }
    
        public func safeOnViewAppear() {
            switch state {
            case .loading:
                self.showLoading()
            case .success:
                self.hideLoading()
            }
        }
    
        public func hideLoading() {}
        public func showLoading() {}
    }
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
    
    func testParsesSwitch() throws {
        let function = visitor.classes.first!.functions.first!
        let `switch` = function.switches().first!
        XCTAssertTrue(`switch`.cases.count == 2)
    }
    
    func testParsesSwitchCases() throws {
        let function = visitor.classes.first!.functions.first!
        let `switch` = function.switches().first!
        let cases = `switch`.cases
        
        let items = cases.flatMap(\.items).compactMap {
            if case .literalExpression(let member) = $0 {
                return member
            }
            
            return nil
        }
        
        XCTAssertTrue(items.count == 2)
        XCTAssertEqual(
            [".loading", ".success"],
            items
        )
    }
    
    func testParsesSwitchCasesWithSelfReference() throws {
        let function = visitor.classes.first!.functions.first!
        let `switch` = function.switches().first!
        
        XCTAssertTrue(`switch`.hasAnyClosureWithSelfReference)
    }
    
    func testParsesSwitchCasesWithNoSelfReference() throws {
        let function = visitor.classes.first!.functions[1]
        let `switch` = function.switches().first!
        
        XCTAssertFalse(`switch`.hasAnyClosureWithSelfReference)
    }
}
