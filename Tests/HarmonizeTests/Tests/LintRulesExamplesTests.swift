//
//  LintRulesExamplesTests.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

import Foundation
import Harmonize
import XCTest

final class LintRulesExamplesTests: XCTestCase {
    override var testRunClass: AnyClass? {
        return AssertionsFailuresTests.ExpectedFailureTestCaseRun.self
    }
    
    func testNoSideEffects() throws {
        Harmonize.on { Self.ViewModel }
            .classes()
            .initializers()
            .withFunctionCalls { functionCalls in
                let closures = functionCalls.compactMap(\.closure)
                let hasAssignmentToSelf = closures.filter {
                    $0.body?.assignments.contains { $0.leftOperand.contains("self") } == true
                }
                
                return hasAssignmentToSelf.isNotEmpty
            }
            .assertEmpty(message: "Side-effect are not allowed in initializers since they are hard to test when using test schedulers")
    }
    
    // This is just an example
    func testNoIfOnInitializers() throws {
        Harmonize.on { Self.ViewModel }
            .classes()
            .withInitializers { $0.hasIfStatements() }
            .assertEmpty(message: "We don't like if-else conditions in initializers. Consider cleaning up your code.")
    }
    
    private static let ViewModel: String = """
        class UserViewModel: ObservableObject {
            private var cancellables = Set<AnyCancellable>()
            @Published var userName: String = "Loading..."
           
            init(userId: Int) {
                if userId == 42 {
                    self.userName = "Offline Profile #42"
                } else {
                    self.userName = "Loading Profile #0"
                }
    
                fetchUserIO(userId: userId) {
                    self.userName = $0
                }
            }
            
            private func fetchUserIO(userId: Int, completion: @escaping (String) -> Void) {
                URLSession.shared.dataTaskPublisher(for: URL(string: "https://example.com/users/\\(userId)")!)
                    .map { data, _ in
                        String(data: data, encoding: .utf8) ?? "Unknown User"
                    }
                    .replaceError(with: "Error fetching user")
                    .sink { userName in
                        completion(userName)
                    }
                    .store(in: &cancellables)
            }
        }

    """
}
