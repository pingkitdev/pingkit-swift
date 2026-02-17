import XCTest
@testable import PingKit

final class ErrorMappingTests: XCTestCase {

    func testRateLimitedMessage() {
        let msg = userMessage(for: .rateLimited(retryAfter: 60))
        XCTAssertEqual(msg, "Too many submissions. Please try again later.")
    }

    func testRateLimitedNilRetryAfterMessage() {
        let msg = userMessage(for: .rateLimited(retryAfter: nil))
        XCTAssertEqual(msg, "Too many submissions. Please try again later.")
    }

    func testPlanLimitReachedMessage() {
        let msg = userMessage(for: .planLimitReached)
        XCTAssertEqual(msg, "Feedback limit reached. Please try again later.")
    }

    func testUnauthorizedMessage() {
        let msg = userMessage(for: .unauthorized)
        XCTAssertEqual(msg, "Unable to send feedback. Please try again.")
    }

    func testInvalidInputMessage() {
        let msg = userMessage(for: .invalidInput("Text too long"))
        XCTAssertEqual(msg, "Text too long")
    }

    func testImageTooLargeMessage() {
        let msg = userMessage(for: .imageTooLarge)
        XCTAssertEqual(msg, "Image is too large. Please choose a smaller image.")
    }

    func testNetworkErrorMessage() {
        let msg = userMessage(for: .networkError(URLError(.notConnectedToInternet)))
        XCTAssertEqual(msg, "Network error. Please check your connection and try again.")
    }

    func testServerErrorMessage() {
        let msg = userMessage(for: .serverError(code: "INTERNAL", message: "Database timeout"))
        XCTAssertEqual(msg, "Database timeout")
    }

    func testNotConfiguredMessage() {
        let msg = userMessage(for: .notConfigured)
        XCTAssertEqual(msg, "Feedback is temporarily unavailable.")
    }

    func testAttestRequiredMessage() {
        let msg = userMessage(for: .attestRequired)
        XCTAssertEqual(msg, "Device verification required.")
    }
}
