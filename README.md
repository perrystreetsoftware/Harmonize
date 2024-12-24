# Harmonize

[![Tests](https://github.com/perrystreetsoftware/Harmonize/actions/workflows/tests.yaml/badge.svg?branch=main)](https://github.com/perrystreetsoftware/Harmonize/actions/workflows/tests.yaml)

**Harmonize** is a modern linter for Swift that allows you to assert, validate, and harmonize your code’s structure and architecture via lint rules written as unit tests — using [XCTest](https://developer.apple.com/documentation/xctest/) or [Quick](https://github.com/Quick/Quick).

This allows your team to keep your codebase clean, maintainable, and consistent as it grows, without relying on manual code reviews.

**Harmonize** is inspired by [SwiftLint](https://github.com/realm/SwiftLint) (a linter focused on Swift style and conventions) and [Konsist](https://github.com/LemonAppDev/konsist) (a linter for Kotlin focused on code structure & architecture).

> [!WARNING]
> Harmonize is currently in early access. Its API may change as we work toward a stable release.

## Usage

With **Harmonize** you can write a lint rule similarly as you would write a unit test:

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

This lint rule enforces all ViewModels to conform to the `AppLifecycleViewModel` and will fail once it detects a violation. You can create similar rules for any architectural or structural pattern that you want to enforce.

## Installation

### Swift Package Manager (SPM)

Add **Harmonize** to your `Package.swift`:

```swift
// Inside the dependencies array
.package(url: "https://github.com/perrystreetsoftware/Harmonize.git", branch: "main"),

// Inside a target’s dependencies
.product(name: "Harmonize", package: "Harmonize")
```

We recommend importing **Harmonize** into your test target or keeping your Harmonize rules in a dedicated Swift package to decouple them from the rest of your tests.

### Configuration

Add a `.harmonize.yaml` file in your project’s root to allow **Harmonize** to inspect and analyze your codebase. You can use the `excludes` key to omit specific files or folders:

```yaml
excludes:
  - Package.swift
```

## Roadmap

- **January – February 2025**
  - Finalize the API for the initial alpha release
  - Publish the official documentation website 
  - Launch a dedicated Slack channel
  - Release the initial alpha version

- **March 2025**
  - API improvements and bug fixes per community feedback

- **April 2025**
  - Release version 1.0

## Contributing

Contributions are welcome through pull requests, issues, or feedback.
