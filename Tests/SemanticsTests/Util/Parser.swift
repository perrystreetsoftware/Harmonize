//
//  Parser.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import SwiftSyntax
import SwiftOperators
import SwiftParser

extension String {
    func parsed() -> SourceFileSyntax {
        let parsed = Parser.parse(source: self)
        
        return OperatorTable.standardOperators
            .foldAll(parsed) { _ in }
            .as(SourceFileSyntax.self) ?? parsed
    }
}
