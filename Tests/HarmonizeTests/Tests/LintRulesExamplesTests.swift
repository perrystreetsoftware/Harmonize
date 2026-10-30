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
            .assertEmpty(rule: Rule(
                id: "no-side-effects-in-initializers",
                title: "Initializers must not have side effects.",
                category: "viewmodel",
                rationale: "Side effects in initializers are hard to test with test schedulers.",
                howToFix: "Move the work to a method the caller invokes after init.",
                badExample: "init() { load() }",
                goodExample: "init() {}\nfunc start() { load() }"
            ))
    }
    
    // This is just an example
    func testNoIfOnInitializers() throws {
        Harmonize.on { Self.ViewModel }
            .classes()
            .withInitializers { $0.hasIfs() }
            .assertEmpty(rule: Rule(
                id: "no-if-in-initializers",
                title: "Initializers must not contain if-else conditions.",
                category: "viewmodel",
                rationale: "Branching in initializers hides the object's initial state.",
                howToFix: "Compute the value before init, or inject it.",
                badExample: "init(flag: Bool) { if flag { x = 1 } else { x = 2 } }",
                goodExample: "init(x: Int) { self.x = x }"
            ))
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
