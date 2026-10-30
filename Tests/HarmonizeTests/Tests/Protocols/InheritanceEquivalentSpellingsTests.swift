import Foundation
import Harmonize
import XCTest

/// Equivalent Swift spellings of the same inheritance must match the same queries.
final class InheritanceEquivalentSpellingsTests: XCTestCase {
    private let source = """
    protocol A_EQS {}
    protocol B_EQS {}
    protocol C_EQS {}
    protocol Comma_EQS: A_EQS, B_EQS {}
    protocol Mid_EQS: B_EQS {}
    protocol Split_EQS: A_EQS, Mid_EQS {}
    class Base_EQS {}
    final class Escaped_EQS: `Base_EQS` {}
    final class EscapedMember_EQS: MyModule.`Base_EQS` {}
    final class Plain_EQS: Base_EQS {}
    """

    func testCompositionQueryMatchesCommaSeparatedInheritance() {
        let comma = Harmonize.on(source: source).protocols().withName("Comma_EQS")

        comma.assertTrue(strict: true) { $0.inherits(from: "A_EQS & B_EQS", includeTransitiveInheritance: false) }
        comma.assertFalse(strict: true) { $0.inherits(from: "A_EQS & C_EQS", includeTransitiveInheritance: false) }
    }

    func testCompositionQueryMatchesAcrossDirectAndTransitiveSupertypes() {
        let split = Harmonize.on(source: source).protocols().withName("Split_EQS")

        split.assertTrue(strict: true) { $0.inherits(from: "A_EQS & B_EQS") }
        split.assertFalse(strict: true) { $0.inherits(from: "A_EQS & B_EQS", includeTransitiveInheritance: false) }
    }

    func testNonStrictIgnoresIdentifierBackticks() {
        Harmonize.on(source: source).classes()
            .withName(["Escaped_EQS", "EscapedMember_EQS"])
            .assertTrue(strict: true) { $0.inherits(from: "Base_EQS") }
    }

    func testNonStrictIgnoresBackticksInTheRequestedName() {
        Harmonize.on(source: source).classes()
            .withName("Plain_EQS")
            .assertTrue(strict: true) { $0.inherits(from: "`Base_EQS`") }
    }
}
