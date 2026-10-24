import Foundation
import Harmonize
import XCTest

final class IntermediateInheritanceTests: XCTestCase {
    private let source = """
    open class BaseViewModel_IIT: NSObject {}
    open class ListViewModel_IIT: BaseViewModel_IIT {}
    final class FeedViewModel_IIT: ListViewModel_IIT {}
    final class DeepFeedViewModel_IIT: FeedViewModel_IIT {}
    """

    func testTransitiveInheritanceFindsIntermediateSupertype() {
        let classes = Harmonize.on(source: source).classes()
            .withName(["FeedViewModel_IIT", "DeepFeedViewModel_IIT"])

        XCTAssertEqual(classes.count, 2)
        classes.assertTrue { $0.inherits(from: "BaseViewModel_IIT", strict: true) }
        classes.assertTrue { $0.inherits(from: "NSObject", strict: true) }
        classes.assertTrue { $0.inherits(from: "ListViewModel_IIT", strict: true) }
    }

    func testNonTransitiveInheritanceStillIgnoresIntermediateSupertype() {
        Harmonize.on(source: source).classes()
            .withName("FeedViewModel_IIT")
            .assertFalse { $0.inherits(from: "BaseViewModel_IIT", includeTransitiveInheritance: false) }
    }
}

final class MultipleInheritanceBranchesTests: XCTestCase {
    private let source = """
    protocol Trackable_MIB {}
    protocol Screen_MIB: Trackable_MIB {}
    open class Base_MIB {}
    open class Middle_MIB: Base_MIB {}
    final class Home_MIB: Middle_MIB, Screen_MIB {}
    """

    func testTransitiveInheritanceFollowsEveryBranch() {
        let home = Harmonize.on(source: source).classes().withName("Home_MIB")

        XCTAssertEqual(home.count, 1)
        home.assertTrue { $0.inherits(from: "Base_MIB", strict: true) }
        home.assertTrue { $0.conforms(to: "Trackable_MIB", strict: true) }
    }
}
