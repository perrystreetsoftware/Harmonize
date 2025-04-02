//
//  String+Extensions.swift
//  Harmonize
//
//  Created by Oscar Gonzalez on 01/04/25.
//

public extension String {
    
    func endsWithAny(_ suffixes: [String]) -> Bool {
        suffixes.contains { suffix in
            self.hasSuffix(suffix)
        }
    }
}
