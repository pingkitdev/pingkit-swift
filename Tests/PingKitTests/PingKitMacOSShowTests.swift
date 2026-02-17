#if os(macOS)
import XCTest
@testable import PingKit

@MainActor
final class PingKitMacOSShowTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        resetPingKitState()
    }

    func testIsShowingFeedbackPreventsSecondShow() {
        configurePingKit()
        PingKit.isShowingFeedback = true

        PingKit.show()

        // The duplicate guard should prevent sheetWindow from being set
        XCTAssertNil(PingKit.sheetWindow)
    }

    func testCleanUpFeedbackSheetResetsState() {
        PingKit.isShowingFeedback = true
        PingKit.sheetWindow = NSWindow()

        PingKit.cleanUpFeedbackSheet()

        XCTAssertNil(PingKit.sheetWindow)
        XCTAssertFalse(PingKit.isShowingFeedback)
    }

    func testShowBeforeConfigureIsNoOpOnMacOS() {
        // No apiKey configured — show() should bail immediately
        PingKit.show()

        XCTAssertNil(PingKit.sheetWindow)
        XCTAssertFalse(PingKit.isShowingFeedback)
    }

    func testShowWithoutVisibleWindowIsNoOp() {
        configurePingKit()

        // No visible NSApp windows in test environment — should bail at parent guard
        PingKit.show()

        // isShowingFeedback should not be set since we never got past the parent check
        // sheetWindow should remain nil
        XCTAssertNil(PingKit.sheetWindow)
    }
}

#endif
