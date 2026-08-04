//
//  DemoRules.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2026. All Rights Reserved.
//

import Foundation
import Harmonize

/// A catalog used to exercise the rule APIs end to end.
///
/// Every rule here carries examples so `assertExamples()` has something to verify.
enum DemoRules: RuleSet {
    static let rules: [Rule] = [
        viewModelsInheritBase,
        domainDoesNotImportUIKit,
        noSideEffectsInInitializers,
        screensDoNotStyleDirectly
    ]

    static let viewModelsInheritBase = Rule(
        id: "viewmodels-inherit-base",
        summary: "Every ViewModel must inherit from BaseViewModel.",
        why: """
        Every ViewModel must inherit from BaseViewModel, which owns subscription \
        cancellation and lifecycle. A ViewModel that opts out leaks its subscriptions.
        """,
        howToFix: "Declare the type as `final class MyViewModel: BaseViewModel`.",
        badExample: """
        final class ProfileViewModel {
            @Published var name: String = ""
        }
        """,
        goodExample: """
        final class ProfileViewModel: BaseViewModel {
            @Published var name: String = ""
        }
        """
    ) { scope in
        scope.classes()
            .withNameEndingWith("ViewModel")
            .assertTrue { $0.inherits(from: "BaseViewModel") }
    }

    static let domainDoesNotImportUIKit = Rule(
        id: "domain-does-not-import-uikit",
        summary: "Domain code must not import UIKit.",
        why: """
        Domain code must stay free of UI framework dependencies so it remains \
        testable off-device and reusable across targets.
        """,
        howToFix: "Move the UIKit-dependent code into the presentation layer and pass plain values into the domain.",
        badExample: """
        import Foundation
        import UIKit

        struct FetchUserUseCase {
            func callAsFunction(id: Int) async throws -> UIImage { fatalError() }
        }
        """,
        goodExample: """
        import Foundation

        struct FetchUserUseCase {
            func callAsFunction(id: Int) async throws -> User { fatalError() }
        }
        """
    ) { scope in
        scope.sources()
            .withImport("UIKit")
            .assertEmpty()
    }

    static let noSideEffectsInInitializers = Rule(
        id: "no-side-effects-in-initializers",
        summary: "Initializers must not start asynchronous work.",
        why: """
        Initializers must not kick off asynchronous work. Side effects in `init` \
        run before a test scheduler can be installed, which makes the type \
        impossible to test deterministically.
        """,
        howToFix: "Move the work into an explicit `start()` or `load()` the caller invokes.",
        badExample: """
        final class UserViewModel: BaseViewModel {
            init(userId: Int) {
                fetchUser(userId: userId) { self.userName = $0 }
            }
        }
        """,
        goodExample: """
        final class UserViewModel: BaseViewModel {
            private let userId: Int

            init(userId: Int) {
                self.userId = userId
            }

            func load() {
                fetchUser(userId: userId) { self.userName = $0 }
            }
        }
        """
    ) { scope in
        scope.classes()
            .initializers()
            .withFunctionCalls { calls in
                calls.compactMap(\.closure).contains { $0.assigns(to: "self") }
            }
            .assertEmpty()
    }
}

// MARK: - Path scoped

extension DemoRules {
    /// Scoped to a directory, so its examples have to stand inside that directory to be seen.
    static let screensDoNotStyleDirectly = Rule(
        id: "screens-do-not-style-directly",
        summary: "Screens must not apply styling modifiers directly.",
        why: """
        Styling belongs in the design system components. A screen applying it directly \
        duplicates decisions those components already own.
        """,
        howToFix: "Move the styling into a design system component and use that instead.",
        badExample: """
        struct ProfileScreen: View {
            var body: some View {
                Text("Hello").padding(16)
            }
        }
        """,
        goodExample: """
        struct ProfileScreen: View {
            var body: some View {
                AtomText(text: "Hello")
            }
        }
        """,
        examplePath: "Sources/Screens/ProfileScreen.swift"
    ) { scope in
        scope.sources()
            .filter { $0.filePath?.path.contains("Sources/Screens") == true }
            .assertTrue { !$0.source.contains(".padding(") }
    }
}
