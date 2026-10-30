import Foundation
import Harmonize
import XCTest

/// A protocol composition such as `A & B` inherits from each composed type.
final class InheritanceCompositionTests: XCTestCase {
    private let source = """
    protocol A_CMP {}
    protocol B_CMP {}
    protocol C_CMP {}
    protocol Both_CMP: A_CMP & B_CMP {}
    protocol Qualified_CMP: MyModule.A_CMP & Generic_CMP<() -> Void> {}
    final class Screen_CMP: Both_CMP {}
    """

    func testNonStrictMatchesEachComposedType() {
        let both = Harmonize.on(source: source).protocols().withName("Both_CMP")

        both.assertTrue(strict: true) { $0.inherits(from: "A_CMP") }
        both.assertTrue(strict: true) { $0.inherits(from: "B_CMP") }
        both.assertFalse(strict: true) { $0.inherits(from: "C_CMP") }
    }

    func testNonStrictNormalizesComposedTypes() {
        let qualified = Harmonize.on(source: source).protocols().withName("Qualified_CMP")

        qualified.assertTrue(strict: true) { $0.inherits(from: "A_CMP") }
        qualified.assertTrue(strict: true) { $0.inherits(from: "Generic_CMP") }
    }

    func testNonStrictCompositionQueryRequiresEveryComposedType() {
        let both = Harmonize.on(source: source).protocols().withName("Both_CMP")

        both.assertTrue(strict: true) { $0.inherits(from: "B_CMP & A_CMP") }
        both.assertFalse(strict: true) { $0.inherits(from: "A_CMP & C_CMP") }
    }

    func testTransitiveInheritanceThroughComposition() {
        Harmonize.on(source: source).classes()
            .withName("Screen_CMP")
            .assertTrue(strict: true) { $0.conforms(to: "B_CMP") }
    }

    func testStrictStillRequiresTheExactComposition() {
        let both = Harmonize.on(source: source).protocols().withName("Both_CMP")

        both.assertTrue(strict: true) { $0.inherits(from: "A_CMP & B_CMP", strict: true) }
        both.assertFalse(strict: true) { $0.inherits(from: "A_CMP", strict: true) }
    }
}
