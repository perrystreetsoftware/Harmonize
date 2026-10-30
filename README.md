# Harmonize

[![Tests](https://github.com/perrystreetsoftware/Harmonize/actions/workflows/tests.yaml/badge.svg?branch=main)](https://github.com/perrystreetsoftware/Harmonize/actions/workflows/tests.yaml)

> 🎤 **Harmonize is coming to a conference near you!** We'll be presenting it at [NSSpain](https://nsspain.com) (Logroño, September 16–18, 2026) and [Swift Connection](https://swiftconnection.io) (Paris, November 2–3, 2026). Come say hi!

**Harmonize** is a modern linter for Swift that allows you to assert, validate, and harmonize your code’s structure and architecture by writing lint rules as unit tests—using [Quick](https://github.com/Quick/Quick), [XCTest](https://developer.apple.com/documentation/xctest/), or [Swift Testing](https://developer.apple.com/xcode/swift-testing/).

This allows your team to keep your codebase clean, maintainable, and consistent as it grows, without relying on manual code reviews.

Harmonize aims to solve the limitations of regex-based linters such as [SwiftLint](https://github.com/realm/SwiftLint), which focus primarily on Swift style and simple conventions. Inspired by [Konsist](https://github.com/LemonAppDev/konsist) for [Kotlin](https://proandroiddev.com/stop-debating-in-code-reviews-start-enforcing-with-lint-rules-6632c907ea94) and [ArchUnit](https://www.archunit.org/) for [Java](https://www.baeldung.com/java-archunit-intro), Harmonize provides a richer, semantic way to enforce your project's architecture and structural guidelines.

## Architectural linters in the era of AI-generated code

AI-generated code can help teams move faster, but it can also introduce architectural flaws and subtle bugs that are hard to spot in manual code reviews. Harmonize gives your codebase deterministic guardrails by turning your team’s architectural and structural rules into unit tests. When AI-generated code violates those rules, the tests fail, giving your AI agent clear feedback to fix its own mistakes.

Harmonize can also provide the rules to AI agents before agents write any code. See [Integrate Harmonize with AI agents](#integrate-harmonize-with-ai-agents).

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
                viewModels.assertTrue(rule: Self.rule) {
                    $0.inherits(from: "BaseViewModel")
                }
            }
        }
    }

    private static let rule = Rule(
        title: "ViewModels must inherit from BaseViewModel.",
        category: "viewmodel",
        rationale: "BaseViewModel owns the lifecycle and the error handling.",
        howToFix: "Declare the class as `final class MyViewModel: BaseViewModel`.",
        badExample: "final class MyViewModel: ObservableObject { }",
        goodExample: "final class MyViewModel: BaseViewModel { }"
    )
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
        
        viewModels.assertTrue(rule: Self.rule) {
            $0.inherits(from: "BaseViewModel")
        }
    }

    private static let rule = Rule(/* the same fields as in the Quick example */)
}
```

### Example using Swift Testing:

```Swift
import Harmonize
import Testing

private let rule = Rule(/* the same fields as in the Quick example */)

@Test
func viewModelsInheritBaseViewModel() {
    let viewModels = Harmonize.productionCode().classes()
        .withNameEndingWith("ViewModel")

    viewModels.assertTrue(rule: rule) {
        $0.inherits(from: "BaseViewModel")
    }
}
```

This lint rule enforces all ViewModels to inherit from `BaseViewModel`. Since it runs as a unit test, it will fail once it detects a violation. The failure shows the `Rule` metadata: the title, the rationale, the fix and the two examples (see [What a failure shows](#what-a-failure-shows)). To exclude a declaration from a rule, use the `withoutName` function:

```Swift
let viewModels = Harmonize.productionCode().classes()
    .withNameEndingWith("ViewModel")
    .withoutName(["LegacyViewModel"])
```

To accept known violations, pass their names to the `baseline:` parameter of the assertion. Harmonize reports an error when a baseline entry passes the rule. This prevents stale entries:

```Swift
viewModels.assertTrue(rule: Self.rule, baseline: ["LegacyViewModel"]) {
    $0.inherits(from: "BaseViewModel")
}
```

You can create similar rules for any architectural or structural pattern that you want to enforce.

Unlike regex-based linters such as SwiftLint, Harmonize provides you with a rich and simple API to directly access any component in your codebase—including files, packages, classes, functions, and properties—and make assertions about them.

### What a failure shows

When the assertion fails, Harmonize reports each violation at its source location with the full rule:

```
RULE: ViewModels must inherit from BaseViewModel.

WHY: BaseViewModel owns the lifecycle and the error handling.

HOW TO FIX: Declare the class as `final class MyViewModel: BaseViewModel`.

❌ BAD:
final class MyViewModel: ObservableObject { }

✅ GOOD:
final class MyViewModel: BaseViewModel { }
```

## Installation

### Swift Package Manager (SPM)

To add **Harmonize** using Swift Package Manager, follow these steps:

In Xcode:
- Go to **File > Add Package Dependencies...**.
- Enter the repository URL: `https://github.com/perrystreetsoftware/Harmonize.git`.
- Add it as a dependency to your test target

Or, manually add it to your `Package.swift` file:

```swift
.package(url: "https://github.com/perrystreetsoftware/Harmonize.git", from: "1.3.0"),
```

The Harmonize integration with AI agents is currently in beta:

```swift
.package(url: "https://github.com/perrystreetsoftware/Harmonize.git", exact: "2.0.0-beta.1"),
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

The optional `skills` key configures the generated agent skill. See [Generate the skill](#generate-the-skill).

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

## Integrate Harmonize with AI agents

Harmonize becomes even more powerful when you integrate it with your AI agents. Your AI agents can run the lint rules after every task, detect the violations, and correct them. Harmonize can also generate a skill for your architecture from your lint rules. AI agents read it before they implement a task.

This integration is available in version `2.0.0-beta.1`. See [Installation](#installation).

### Run the rules after a task

Add this instruction to your `AGENTS.md` or `CLAUDE.md` file:

```markdown
- After you implement a task, run the Harmonize lint rules with the `run-harmonize` skill.
```

Then give the agent the skill. Copy [`skills/run-harmonize/SKILL.md`](skills/run-harmonize/SKILL.md) into the skills folder of your project, or install the [Claude Code plugin](#claude-code-plugin). The skill finds the rules package, runs the rules, and explains how to fix each violation.

### The `Rule` type

Pass a `Rule` to `assertTrue`, `assertFalse` or `assertEmpty` with the `rule:` parameter. The `message:` parameter is deprecated. It still works, but a later version will remove it.

| Field | Content |
| --- | --- |
| `id` | A stable identifier. Harmonize derives it from the file name (`ViewModelsInheritBase.swift` → `view-models-inherit-base`). Set the id to get a better name. If one file has more than one rule, give the rules explicit ids. Use lowercase letters, digits, and single hyphens. Do not change an id after you publish it. |
| `title` | One sentence that says what the rule checks. |
| `category` | The layer the rule belongs to. Pass a case of your category enum (see below). |
| `disclosure` | When an agent must learn the rule: `.upfront`, `.progressive` (the default) or `.deferred`. The value does not change enforcement. |
| `rationale` | Why the rule exists. |
| `howToFix` | How to correct a violation. |
| `badExample` | A short code sample that violates the rule. |
| `goodExample` | A short code sample that obeys the rule. |

### Categories

Define the categories of your project as an enum that conforms to `RuleCategory`:

```swift
enum Categories: String, RuleCategory {
    case viewmodel, logic, networking

    var categoryName: String { rawValue }

    var categoryDescription: String {
        switch self {
        case .viewmodel: "Rules for ViewModels. Read before you create or change a ViewModel."
        case .logic: "Rules for Logic classes. Read before you add business logic."
        case .networking: "Rules for APIs and DTOs. Read before you change network code."
        }
    }
}
```

The description appears next to the layer in the generated skill. Write it as a trigger: what the layer is, and when to read its rules.

### Disclosure

An agent has a limited context window. The `disclosure` value says when the agent must read a rule:

- `.upfront`: the rule applies to almost every task. The skill shows it on its first page. Use it for a small number of rules. Each upfront title goes into the skill description, and the description has a limit of 1024 characters.
- `.progressive`: the rule applies to one layer. The skill lists it in the file of that layer. This is the default.
- `.deferred`: the skill does not list the rule. The test failure explains the fix.

Harmonize enforces every lint rule as a unit test, regardless of its disclosure. The disclosure only changes the generated skill.

### Generate the skill

Harmonize includes a Swift package command plugin. It generates one agent skill from your lint rules: a `SKILL.md` file and its reference files. It reads the `Rule(...)` declarations from the source code.

1. Add the output location to `.harmonize.yaml`. Both keys are optional:

   ```yaml
   skills:
     output: .agents/skills   # holds the skill folder, relative to the repository root (default)
     name: harmonize          # the skill folder and the skill name (default)
   ```

2. Run the plugin from the repository root. The `--allow-writing-to-directory` value must match the `output` key:

   ```bash
   swift package --package-path <rules-package> \
     --allow-writing-to-package-directory --allow-writing-to-directory .agents/skills \
     harmonize-skills
   ```

3. Commit the generated folder:

   ```
   .agents/skills/harmonize/
     SKILL.md                        the .upfront rules and the list of layers
     references/<category>.md        the rules of one layer, with links
     references/<category>/<id>.md   one rule: why, how to fix, bad and good example
   ```

4. Tell your agent to use the skill before it writes code. For example, in `AGENTS.md`:

   > Before you write or change Swift code, use the `harmonize` skill. It lists the lint rules for each layer. CI fails on any violation.

The first run builds the generator. This takes some minutes. Later runs only take seconds. To override the configuration for one run, append `--output <dir>` or `--name <skill-name>` to the command.

### Keep the skill up to date

To keep the generated skill up to date with your lint rules, use these two mechanisms:

- A pre-commit hook regenerates the skill when a commit contains a rule file. Copy [`hooks/pre-commit.example`](hooks/pre-commit.example) and set its variables. The hook runs the built generator binary directly, so it takes less than one second. If the binary does not exist, the hook shows a warning and permits the commit.
- A CI check regenerates the skill and fails when the result differs from the commit:

  ```yaml
  - name: Check that the generated skills are current
    run: |
      swift package --package-path <rules-package> \
        --allow-writing-to-package-directory --allow-writing-to-directory .agents/skills \
        harmonize-skills
      git add -A -- .agents/skills/harmonize
      git diff --cached --quiet || { git diff --cached --stat; exit 1; }
  ```

### Claude Code plugin

The repository also contains a Claude Code plugin with two skills. [`run-harmonize`](skills/run-harmonize/SKILL.md) runs the rules and explains the output. [`write-harmonize-rule`](skills/write-harmonize-rule/SKILL.md) guides an agent that writes a new rule. Install it with:

```
/plugin marketplace add perrystreetsoftware/Harmonize
/plugin install harmonize@harmonize
```

## Articles
- [Architectural Linting for Swift made Easy](https://medium.com/perry-street-software-engineering/architectural-linting-for-swift-made-easy-75d7f9f569cd)
- [Goodbye Code Reviews, Hello Harmonize: Enforce Your Architecture in Swift](https://itnext.io/goodbye-code-reviews-hello-harmonize-0a49e2872b5a)

## Example project

See how our [Woof demo app](https://github.com/perrystreetsoftware/woof-demo) is using Harmonize to enforce its architecture. Woof mirrors the patterns we use in our production iOS apps, so its lint rules are a good starting point for your own project.

## Contributing

All contributions are welcome through pull requests, issues, or discussions.
