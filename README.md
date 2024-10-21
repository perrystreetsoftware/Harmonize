# 🧩 Harmonize

Harmonize is a Swift project with powerful linting capabilities, allowing developers to easily assert, validate, and harmonize code structure and architecture through declarative tests. It can enforce best practices to ensure a clean, maintainable, and consistent codebase aligned with your project guidelines.

Harmonize lint rules are written as unit tests using [XCTest](https://developer.apple.com/documentation/xctest/) or [Quick](https://github.com/Quick/Quick).

> [!WARNING]  
> Harmonize is currently being developed in public and is used internally. It is considered an early alpha version, and its API is subject to change.

## Installation

### Swift Package Manager (SPM)

Add the following to your package dependencies:

```swift
// Product Dependencies block
.package(url: "https://github.com/perrystreetsoftware/harmonize.git", branch: "main")

// Target dependencies block
.product(name: "Harmonize", package: "Harmonize")
```

We recommend importing `Harmonize` as part of your test target. While Harmonize can be used on any Swift package, you can also create a separate Swift package specifically for Harmonize rules to keep it decoupled from your main codebase.

### Configuration File

To enable Harmonize to query your project files and provide the semantics API for your tests, you need to create a `.harmonize.yaml` configuration file at the root level of your project. Currently, the only supported configuration is `excludes`, which allows you to exclude specific files or folders from your project.

```yaml
excludes:
  - Package.swift
```

> [!NOTE]  
> We plan to build a CLI that will automate this process, but for the alpha version, this step is mandatory.

## Usage

Using Harmonize is as simple as writing a unit test.

```swift
import XCTest
import Harmonize

final class ViewModelsTests: XCTestCase {
    func testViewModelsBaseViewModelConformance() throws {
        Harmonize.on("ViewModels").classes()
            .assertTrue(message: "ViewModels must conform to AppLifecycleViewModel") {
                $0.conforms(to: AppLifecycleViewModel.self)
            }
    }
}
```

![](assets/viewmodels-rule.png)

## Contributing

Contributions are welcome through pull requests, issues, or feedback. We are still working on building a code of conduct.

## Considerations

This project is heavily inspired by [SwiftLint](https://github.com/realm/SwiftLint/tree/main) and [Konsist](https://github.com/LemonAppDev/konsist) (a linter for Kotlin where this idea originated).

We see this project as a companion to your preferred compile-time linter, allowing you to create custom lint rules that align with your team and project architecture using unit tests.

Our Semantics module, built using [Swift Syntax](https://github.com/swiftlang/swift-syntax) to parse the language Abstract Syntax Tree (AST), is inspired by the now-archived [SwiftDocc Semantics](https://github.com/swiftlang/swift-docc).

> [!NOTE]  
> We are aware of potential performance issues when querying large codebases and parsing the AST. We are continuously working on improvements to make Harmonize faster.
