# Harmonize

[![Tests](https://github.com/perrystreetsoftware/Harmonize/actions/workflows/tests.yaml/badge.svg?branch=main)](https://github.com/perrystreetsoftware/Harmonize/actions/workflows/tests.yaml)

**Harmonize** is a modern linter for Swift that allows you to assert, validate, and harmonize your code’s structure and architecture by writing lint rules as unit tests—using [Quick](https://github.com/Quick/Quick), [XCTest](https://developer.apple.com/documentation/xctest/), or [Swift Testing](https://developer.apple.com/xcode/swift-testing/).

This allows your team to keep your codebase clean, maintainable, and consistent as it grows, without relying on manual code reviews.

Harmonize aims to solve the limitations of regex-based linters such as [SwiftLint](https://github.com/realm/SwiftLint), which focus primarily on Swift style and simple conventions. Inspired by [Konsist](https://github.com/LemonAppDev/konsist), Harmonize provides a richer, semantic way to enforce your project's architecture and structural guidelines.

## Usage

With Harmonize, you can write a lint rule similarly as you would write a unit test:

### Example using Quick:

```Swift
import Quick
import Harmonize

class ViewModelsInheritFromBaseViewModel: QuickSpec {
    override class func spec() {
        describe("Given a ViewModel") {
            let viewModels = Harmonize.classesProduction.withNameEndingWith("ViewModel")
            
            it("inherits from BaseViewModel") {
                viewModels.assertTrue(message: "All ViewModels must inherit from the BaseViewModel") {
                    $0.inherits(from: BaseViewModel.self)
                }
            }
        }
    }
}
```

### Example using XCTest:

```Swift
import XCTest
import Harmonize

final class ViewModelsInheritFromBaseViewModel: XCTestCase {
    func testViewModel() throws {
        let viewModels = Harmonize.classesProduction.withNameEndingWith("ViewModel")
        
        viewModels.assertTrue(message: "All ViewModels must inherit from the BaseViewModel") {
            $0.inherits(from: BaseViewModel.self)
        }
    }
}
```

This lint rule enforces all ViewModels to inherit from the `BaseViewModel`. Since it runs as a unit test, it will fail once it detects a violation. You can add exceptions or a baseline to this rule using the `withoutName` function:

```Swift
// ...
let viewModels = Harmonize.classesProduction.withNameEndingWith("ViewModels")
    .withoutName(["LegacyViewModel"])
// ...
```

You can create similar rules for any architectural or structural pattern that you want to enforce.

Unlike regex-based linters such as SwiftLint, Harmonize provides you with a rich and simple API to directly access any component in your codebase—including files, packages, classes, functions, and properties—and make assertions about them.

## Installation

### Swift Package Manager (SPM)

To add **Harmonize** using Swift Package Manager, follow these steps:

In Xcode:
- Go to **File > Add Package Dependencies...**.
- Enter the repository URL: `https://github.com/perrystreetsoftware/Harmonize.git`.
- Add it as a dependency to your test target

Or, manually add it to your `Package.swift` file:

```swift
.package(url: "https://github.com/perrystreetsoftware/Harmonize.git", from: "0.1.0"),
```

You can optionally create a dedicated Swift package for your Harmonize lint rules to separate them from the rest of the unit tests.

## Configuration

Add a `.harmonize.yaml` file in your project’s root directory to specify which files or folders you want to exclude from your lint rules, using the `excludes` key:

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

## Contributing

All contributions are welcome through pull requests, issues, or discussions.
