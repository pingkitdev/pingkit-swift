import XCTest
@testable import PingKit

@MainActor
final class PingKitShowTests: XCTestCase {
    override func tearDown() {
        resetPingKitState()
        super.tearDown()
    }

    func testShowBeforeConfigureIsNoOp() {
        // Should not crash, just return silently
        PingKit.show()
    }

    func testShowWithoutWindowSceneIsNoOp() {
        configurePingKit()
        // In test environment, there's no UIWindowScene — should not crash
        PingKit.show()
    }

    func testShowDoesNotCrash() {
        configurePingKit()
        PingKit.show(email: .optional, type: .picker(["Bug", "Feature"]), metadata: ["key": "val"])
        // If we get here without crashing, the test passes
    }
}
