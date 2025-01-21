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
                    $0.assigns(to: "self")
                }
                
                return hasAssignmentToSelf.isNotEmpty
            }
            .assertEmpty(message: "Side-effect are not allowed in initializers since they are hard to test when using test schedulers")
    }
    
    // This is just an example
    func testNoIfOnInitializers() throws {
        Harmonize.on { Self.ViewModel }
            .classes()
            .withInitializers { $0.hasIfs() }
            .assertEmpty(message: "We don't like if-else conditions in initializers. Consider cleaning up your code.")
    }
    
    func testFunctionCallClosures() throws {
        Harmonize.on { Self.FunctionCalls }
            .functions()
            .filter {
                $0.hasAnyClosureWithSelfReference && $0.closures().allSatisfy { $0.isCapturingWeak(valueOf: "self") }
            }
            .assertNotEmpty()
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
    
    private static let FunctionCalls: String = """
    private func listenToSomeStream() {
            setupStream()
                .sink { data in
                    guard let self else { return }
                    let result = data.result
                    let additionalResult = data.additionalResult
                    switch result {
                    case .success(let viewData):
                        self.handleSuccess(data: viewData, additionalData: additionalResult)
                    case .error(let error):
                        self.handleError(error)
                    case .loading:
                        self.state = .loading(data: self.placeholders)
                    }
                }
                .store(in: &cancellables)
    }
    """
}
