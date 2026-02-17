#if os(macOS)
import XCTest
@testable import PingKit

final class FeedbackViewDismissTests: XCTestCase {

    func testOnDismissClosureIsStoredAndCallable() {
        var called = false
        let view = FeedbackView(
            emailMode: nil,
            typeMode: nil,
            customMetadata: nil,
            onDismiss: { called = true }
        )

        view.onDismiss?()

        XCTAssertTrue(called)
    }

    func testOnDismissDefaultsToNil() {
        let view = FeedbackView(
            emailMode: nil,
            typeMode: nil,
            customMetadata: nil
        )

        XCTAssertNil(view.onDismiss)
    }
}

#endif
