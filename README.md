# Harmonize

[![Tests](https://github.com/perrystreetsoftware/Harmonize/actions/workflows/tests.yaml/badge.svg?branch=main)](https://github.com/perrystreetsoftware/Harmonize/actions/workflows/tests.yaml)

**Harmonize** is a modern linter for Swift that allows you to assert, validate, and harmonize your code’s structure and architecture by writing lint rules as unit tests—using [Quick](https://github.com/Quick/Quick), [XCTest](https://developer.apple.com/documentation/xctest/), or [Swift Testing](https://developer.apple.com/xcode/swift-testing/).

This allows your team to keep your codebase clean, maintainable, and consistent as it grows, without relying on manual code reviews.

Harmonize aims to solve the limitations of regex-based linters such as [SwiftLint](https://github.com/realm/SwiftLint), which focus primarily on Swift style and simple conventions. Inspired by [Konsist](https://github.com/LemonAppDev/konsist) for [Kotlin](https://proandroiddev.com/stop-debating-in-code-reviews-start-enforcing-with-lint-rules-6632c907ea94) and [ArchUnit](https://www.archunit.org/) for [Java](https://www.baeldung.com/java-archunit-intro), Harmonize provides a richer, semantic way to enforce your project's architecture and structural guidelines.

## Architectural linters in the era of AI-generated code

AI-generated code can help teams move faster, but it can also introduce architectural flaws and subtle bugs that are hard to spot in manual code reviews. Harmonize gives your codebase deterministic guardrails by turning your team’s architectural and structural rules into unit tests. When AI-generated code violates those rules, the tests fail, giving your AI agent clear feedback to fix its own mistakes.

## Usage

With Harmonize, you can write a lint rule similarly as you would write a unit test:

### Example using Quick:

```Swift
import Harmonize
import Quick

final class ViewModelsInheritBaseViewModelSpec: QuickSpec {
    override func spec() {
        describe("ViewModels") {
            let viewModels = Harmonize.productionCode().classes()
                .withNameEndingWith("ViewModel")

            it("should inherit from BaseViewModel") {
                viewModels.assertTrue(message: "All ViewModels must inherit from BaseViewModel") {
                    $0.inherits(from: "BaseViewModel")
                }
            }
        }
    }
}
```

### Example using XCTest:

```Swift
import Harmonize
import XCTest

final class ViewModelsInheritBaseViewModelSpec: XCTestCase {
    func testViewModels() throws {
        let viewModels = Harmonize.productionCode().classes()
            .withNameEndingWith("ViewModel")
        
        viewModels.assertTrue(message: "All ViewModels must inherit from BaseViewModel") {
            $0.inherits(from: "BaseViewModel")
        }
    }
}
```

### Example using Swift Testing:

```Swift
import Harmonize
import Testing

@Test
func viewModelsInheritBaseViewModel() {
    let viewModels = Harmonize.productionCode().classes()
        .withNameEndingWith("ViewModel")
        
    viewModels.assertTrue(message: "All ViewModels must inherit from BaseViewModel") {
        $0.inherits(from: "BaseViewModel")
    }
}
```

This lint rule enforces all ViewModels to inherit from `BaseViewModel`. Since it runs as a unit test, it will fail once it detects a violation. You can add exceptions or a baseline to this rule using the `withoutName` function:

```Swift
let viewModels = Harmonize.productionCode().classes()
    .withNameEndingWith("ViewModel")
    .withoutName(["LegacyViewModel"])
```

You can create similar rules for any architectural or structural pattern that you want to enforce.

Unlike regex-based linters such as SwiftLint, Harmonize provides you with a rich and simple API to directly access any component in your codebase—including files, packages, classes, functions, and properties—and make assertions about them.

## Declaring rules as values

As your lint rules grow into a set, you can declare each one as a `Rule` and group them
into a `RuleSet`. The query stays the same code you would write inline, now next to the
metadata that describes it:

```swift
import Harmonize

enum AppRules: RuleSet {
    static let rules: [Rule] = [viewModelsInheritBase]

    static let viewModelsInheritBase = Rule(
        id: "viewmodels-inherit-base",
        summary: "Every ViewModel must inherit from BaseViewModel.",
        why: "BaseViewModel owns subscription cancellation, a ViewModel that opts out leaks.",
        howToFix: "Declare the type as `final class MyViewModel: BaseViewModel`.",
        badExample: "final class ProfileViewModel {}",
        goodExample: "final class ProfileViewModel: BaseViewModel {}"
    ) { scope in
        scope.classes()
            .withNameEndingWith("ViewModel")
            .assertTrue { $0.inherits(from: "BaseViewModel") }
    }
}
```

Assertions inside a rule inherit its metadata, so there is no need to repeat `rule:` on
each one. A single unit test then runs them all:

```swift
final class ArchitectureTests: XCTestCase {
    func testArchitecture() {
        AppRules.assertAll()
    }
}
```

Since the rules can now be listed, Harmonize can also read them to write your documentation
and to check your examples.

### Generating instructions for your AI agents

Harmonize gives your agents feedback once they break a rule. A `RuleSet` also lets you tell
them the rules before they start, by generating the Markdown they read:

```swift
final class ArchitectureTests: XCTestCase {
    func testAgentInstructionsAreInSync() {
        AppRules.syncContext(at: "HARMONIZE.md")
    }
}
```

Regenerate it after changing a rule, and let CI verify it on every run afterwards:

```bash
HARMONIZE_UPDATE_CONTEXT=1 swift test --filter testAgentInstructionsAreInSync
```

Then point your agent at the generated file from wherever it reads its instructions. In
Claude Code a single import is enough, and your own `CLAUDE.md` stays as short as you want
it:

```markdown
# CLAUDE.md

Run the tests with `swift test`.

@HARMONIZE.md
```

Instructions written by hand get out of date as the codebase grows. Generating them means
your rules are only written once, and this test fails whenever the file and the rules don't
match. Commit the generated file, so a fresh clone has it and every change to a rule shows
up in review as a change to the instructions your agents follow.

If you would rather keep the rules inside a file you already maintain, point `syncContext`
at it instead. Only the section between the `<!-- harmonize:start -->` and
`<!-- harmonize:end -->` markers is written, so everything around it is left untouched.

### Verifying your rule examples

The `badExample` and `goodExample` snippets are documentation your agents rely on, so
Harmonize evaluates each rule against them: the bad one must trigger the rule, the good one
must not.

```swift
func testRuleExamplesAreAccurate() {
    AppRules.assertExamples()
}
```

A rule scoped to a directory only sees its examples when they stand inside it, so give it
an `examplePath`:

```swift
Rule(
    id: "screens-do-not-style-directly",
    badExample: "...",
    goodExample: "...",
    examplePath: "Sources/Screens/ProfileScreen.swift"
) { scope in
    scope.sources()
        .filter { $0.filePath?.path.contains("Sources/Screens") == true }
        .assertTrue { !$0.source.contains(".padding(") }
}
```

You can also evaluate a rule against source directly while writing it, since a query
matching nothing looks the same as a clean codebase:

```swift
AppRules.viewModelsInheritBase.assertFires(on: "final class ProfileViewModel {}")
AppRules.viewModelsInheritBase.assertPasses(on: "final class ProfileViewModel: BaseViewModel {}")
```

Finally, `AppRules.assertRulesAreValid()` checks that your rule ids are unique and that
every rule says what it checks and why.

## Installation

### Swift Package Manager (SPM)

To add **Harmonize** using Swift Package Manager, follow these steps:

In Xcode:
- Go to **File > Add Package Dependencies...**.
- Enter the repository URL: `https://github.com/perrystreetsoftware/Harmonize.git`.
- Add it as a dependency to your test target

Or, manually add it to your `Package.swift` file:

```swift
.package(url: "https://github.com/perrystreetsoftware/Harmonize.git", from: "0.2.0"),
```

You can optionally create a dedicated Swift package for your Harmonize lint rules to separate them from the rest of the unit tests.

## Configuration

Add an empty `.harmonize.yaml` file to the root of your project.
This file is **required** for Harmonize to correctly detect the project root and apply your lint rules.

You can also optionally specify which files or folders you want to exclude from all lint rules, using the `excludes` key:

```yaml
excludes:
  - Package.swift
```

## Integrating with CI/CD

Since Harmonize lint rules run as unit tests, you can integrate them easily into your existing CI/CD pipeline and automate them, similarly as you would automate your unit tests. Here’s an example of a GitHub Action that runs all your Harmonize lint rules when a pull request is opened:

```yaml
name: Run Harmonize Lint Rules
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  harmonize:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Harmonize Rules (macOS)
        run: |
          xcodebuild -scheme YourHarmonizeTestScheme -sdk macosx test
```

## Articles
- [Architectural Linting for Swift made Easy](https://medium.com/perry-street-software-engineering/architectural-linting-for-swift-made-easy-75d7f9f569cd)
- [Goodbye Code Reviews, Hello Harmonize: Enforce Your Architecture in Swift](https://itnext.io/goodbye-code-reviews-hello-harmonize-0a49e2872b5a)

## Example project

You can see an example project that [uses Harmonize here](https://github.com/perrystreetsoftware/DemoAppIOS).

## Contributing

All contributions are welcome through pull requests, issues, or discussions.
