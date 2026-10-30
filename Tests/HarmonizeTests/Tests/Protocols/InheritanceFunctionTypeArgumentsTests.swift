import Foundation
import Harmonize
import XCTest

/// Generic arguments may contain function types, whose `->` arrow must not be
/// mistaken for the closing `>` of the generic argument list.
final class InheritanceFunctionTypeArgumentsTests: XCTestCase {
    private let source = """
    open class EventHandler_FTA<Payload> {}
    final class TapHandler_FTA: EventHandler_FTA<() -> Void> {}
    final class ResultHandler_FTA: EventHandler_FTA<(Int) throws -> Result<String, Error>> {}
    final class NestedHandler_FTA: Container_FTA<() -> Void>.BaseHandler_FTA {}
    final class TextHandler_FTA: EventHandler_FTA<String> {}
    """

    func testNonStrictMatchesGenericWithFunctionTypeArgument() {
        Harmonize.on(source: source).classes()
            .withName(["TapHandler_FTA", "ResultHandler_FTA"])
            .assertTrue(strict: true) { $0.inherits(from: "EventHandler_FTA") }
    }

    func testNonStrictKeepsNestedTypeAfterFunctionTypeArgument() {
        let nested = Harmonize.on(source: source).classes().withName("NestedHandler_FTA")

        nested.assertTrue(strict: true) { $0.inherits(from: "BaseHandler_FTA") }
        nested.assertFalse(strict: true) { $0.inherits(from: "Container_FTA") }
    }

    func testNonStrictNormalizesRequestedNameWithFunctionTypeArgument() {
        Harmonize.on(source: source).classes()
            .withName("TextHandler_FTA")
            .assertTrue(strict: true) { $0.inherits(from: "EventHandler_FTA<(String) -> Void>") }
    }
}
