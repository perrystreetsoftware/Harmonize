import Foundation
import Harmonize
import XCTest

final class InheritanceNameMatchingTests: XCTestCase {
    private let source = """
    open class BaseViewModel_INM {}
    open class LegacyBaseViewModel_INMShim {}
    final class SettingsViewModel_INM: LegacyBaseViewModel_INMShim {}
    final class ProfileViewModel_INM: BaseViewModel_INM {}
    final class ModuleViewModel_INM: MyModule.BaseViewModel_INM {}
    final class GenericViewModel_INM: GenericBase_INM<String> {}
    final class Store_INM: ObservableObject, Sendable {}
    final class NestedViewModel_INM: Container_INM<Int>.BaseViewModel_INM {}
    """

    func testNonStrictDoesNotMatchTypesThatOnlyContainTheName() {
        Harmonize.on(source: source).classes()
            .withName("SettingsViewModel_INM")
            .assertFalse { $0.inherits(from: "BaseViewModel_INM") }
    }

    func testNonStrictMatchesQualifiedAndGenericNames() {
        let scope = Harmonize.on(source: source).classes()

        scope.withName(["ProfileViewModel_INM", "ModuleViewModel_INM"])
            .assertTrue(strict: true) { $0.inherits(from: "BaseViewModel_INM") }
        scope.withName("GenericViewModel_INM")
            .assertTrue(strict: true) { $0.inherits(from: "GenericBase_INM") }
        scope.withName("Store_INM")
            .assertTrue(strict: true) { $0.conforms(to: "Sendable") }
    }

    func testNonStrictNormalizesTheRequestedName() {
        let scope = Harmonize.on(source: source).classes()

        scope.withName("ModuleViewModel_INM")
            .assertTrue(strict: true) { $0.inherits(from: "MyModule.BaseViewModel_INM") }
        scope.withName("GenericViewModel_INM")
            .assertTrue(strict: true) { $0.inherits(from: "GenericBase_INM<String>") }
    }

    func testNonStrictKeepsNestedTypeAfterGenericContainer() {
        let nested = Harmonize.on(source: source).classes().withName("NestedViewModel_INM")

        nested.assertTrue(strict: true) { $0.inherits(from: "BaseViewModel_INM") }
        nested.assertFalse(strict: true) { $0.inherits(from: "Container_INM") }
    }
}
