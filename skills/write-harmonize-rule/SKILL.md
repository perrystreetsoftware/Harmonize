---
name: write-harmonize-rule
description: Guide for writing a new Harmonize architectural lint rule as a unit test, with structured Rule metadata that tools and AI agents can read. Use when asked to write a lint rule, enforce an architectural pattern or convention, or prevent a class of mistake in a Swift codebase.
---

# Write a Harmonize rule

Harmonize rules are unit tests. They query the syntax tree of the codebase and assert architectural conventions. Write one rule per file. Name the file after the rule (for example `ViewModelsInheritBaseViewModel.swift`). Put it in the rules package of the project (see the `run-harmonize` skill). Use the test framework the package already uses: XCTest, Quick or swift-testing.

## Template (XCTest)

```swift
import Harmonize
import XCTest

final class ViewModelsInheritBaseViewModel: XCTestCase {
    func testViewModelsInheritBaseViewModel() {
        Harmonize.productionCode()
            .classes()
            .withNameEndingWith("ViewModel")
            .assertTrue(rule: Self.rule) { $0.inherits(from: "BaseViewModel") }
    }

    private static let rule = Rule(
        title: "ViewModels must inherit from BaseViewModel.",
        category: Categories.viewmodel,
        disclosure: .progressive,
        rationale: """
            Lifecycle handling, state publishing, and error routing live in \
            BaseViewModel. A ViewModel outside the hierarchy loses them.
            """,
        howToFix: "Declare the class as `final class MyViewModel: BaseViewModel`.",
        badExample: "final class MyViewModel: ObservableObject { }",
        goodExample: "final class MyViewModel: BaseViewModel { }"
    )
}
```

## Always provide the Rule metadata

Pass `rule:` to `assertTrue`, `assertFalse` or `assertEmpty`. The `message:` parameter is deprecated. All fields are required. Pass an empty string only when a field does not apply.

| Field         | Purpose                                                                  |
| ------------- | ------------------------------------------------------------------------ |
| `id`          | A stable kebab-case identifier. Harmonize derives it from the file name (`ViewModelsInheritBase.swift` → `view-models-inherit-base`). Set it only for a better name, when a file has several rules (derived ids that collide get the suffixes `-2`, `-3`, ...), or when the derived form breaks an acronym. Do not change an id after you publish it. |
| `title`       | One sentence that says what the rule checks.                             |
| `category`    | The layer of the rule. Pass a case of the category enum of the project (see below). |
| `disclosure`  | When agents must learn the rule. `.upfront`: the rule applies to almost every task. Use it rarely, because each upfront title goes into the skill description and the description has a limit of 1024 characters. `.progressive`: the rule applies to one layer (the default). `.deferred`: the fix is mechanical, and the test failure explains it. The value does not change enforcement. |
| `rationale`   | Why the rule exists. Without it, agents and teammates avoid the rule instead of correcting the code. |
| `howToFix`    | The steps that correct a violation. Generated docs show it next to the title, so make it complete for the common case. |
| `badExample`  | A short code sample that violates the rule.                              |
| `goodExample` | A short code sample that obeys the rule.                                 |

Each rule becomes documentation. The `harmonize-skills` plugin reads the declarations from the source code and generates the `harmonize` agent skill: one reference page per layer and one per rule. For this reason, every value must be a literal: a string literal or an enum case. Do not use `Self.sharedText` or string interpolation. If you do, the generator stops with an error at that line.

### Category vocabulary

Define the categories of the project once, as an enum that conforms to `RuleCategory`. Always pass a case. The compiler then rejects a misspelled category (`"view-model"` against `"viewmodel"`). The skill generator also stops when two category names differ only in case or punctuation.

```swift
enum Categories: String, RuleCategory {
    case viewmodel, logic, networking
    var categoryName: String { rawValue }
    var categoryDescription: String {
        switch self {
        case .viewmodel: "Rules for ViewModels and UIModels. Read before you create or change a ViewModel."
        case .logic: "Rules for Logic classes (use cases). Read before you add business logic."
        case .networking: "Rules for APIs and DTOs. Read before you change network code."
        }
    }
}
```

Give each case a `categoryDescription` of one or two sentences. The generated skill shows it next to the layer. Write it as a trigger ("Rules for X. Read before you create or change Y."). Before you add a case, check whether an existing category covers the layer. Each category becomes one reference page in the skill.

## Scope and filter

- Scope with `Harmonize.productionCode()`, `.testCode()` or `.on("path/Or/Folder")`. If the project has its own scope helpers (a class that wraps `Harmonize`), use them.
- Prefer the built-in filters (`withNameEndingWith`, `withoutModifier`, `conforming(to:)`, `withImport`, ...) to `.filter { }` closures and regular expressions.
- If you need a regular expression, compile it once as a `static let`. Do not construct it inside a per-element predicate.

## Record the known violations

Pass the known violations to the `baseline:` parameter of the assertion. Use declaration names or `File.swift` names:

```swift
.assertTrue(rule: Self.rule, baseline: ["LegacyViewModel"]) { ... }
```

The assertion reports a stale baseline error when an entry starts to pass, or when it matches nothing. The list then becomes shorter over time. Do not filter the scope with `.withoutName(baseline)`. That hides stale entries. Omit `baseline:` when there are no violations.

## Verify

1. Run the new rule alone (see `run-harmonize`). Expect a failure on each known violation and a pass otherwise.
2. Add a temporary violation to confirm that the rule catches it. Then remove it.
3. Run the full rule suite to confirm that nothing else broke.
4. Regenerate the agent skill (`swift package ... harmonize-skills`, see `run-harmonize`), or let the pre-commit hook do it. Commit the skill with the rule.
