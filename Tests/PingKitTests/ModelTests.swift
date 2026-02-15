import XCTest
@testable import PingKit

final class ModelTests: XCTestCase {

    // MARK: - PingKitOptions

    func testOptionsDefaults() {
        let options = PingKitOptions()
        XCTAssertEqual(options.endpoint, "https://pingkit.dev")
        XCTAssertTrue(options.enableAppAttest)
        XCTAssertEqual(options.maxImageSizeMB, 5)
        XCTAssertFalse(options.verbose)
    }

    func testOptionsCustomValues() {
        let options = PingKitOptions(
            endpoint: "https://custom.dev",
            enableAppAttest: false,
            maxImageSizeMB: 10,
            verbose: true
        )
        XCTAssertEqual(options.endpoint, "https://custom.dev")
        XCTAssertFalse(options.enableAppAttest)
        XCTAssertEqual(options.maxImageSizeMB, 10)
        XCTAssertTrue(options.verbose)
    }

    // MARK: - PingKitTheme

    func testThemeDefaults() {
        let theme = PingKitTheme()
        XCTAssertEqual(theme.cornerRadius, 20)
        XCTAssertNil(theme.cardColor)
    }

    func testThemeCustomValues() {
        let theme = PingKitTheme(cornerRadius: 12)
        XCTAssertEqual(theme.cornerRadius, 12)
    }

    // MARK: - EmailMode

    func testEmailModeOptional() {
        let mode = EmailMode.optional
        if case .optional = mode {} else {
            XCTFail("Expected .optional")
        }
    }

    func testEmailModeRequired() {
        let mode = EmailMode.required
        if case .required = mode {} else {
            XCTFail("Expected .required")
        }
    }

    func testEmailModePrefilled() {
        let mode = EmailMode.prefilled("test@example.com")
        if case .prefilled(let email) = mode {
            XCTAssertEqual(email, "test@example.com")
        } else {
            XCTFail("Expected .prefilled")
        }
    }

    // MARK: - TypeMode

    func testTypeModePickerOptions() {
        let mode = TypeMode.picker(["Bug", "Feature", "Other"])
        if case .picker(let options) = mode {
            XCTAssertEqual(options, ["Bug", "Feature", "Other"])
        } else {
            XCTFail("Expected .picker")
        }
    }

    // MARK: - FeedbackResult

    func testFeedbackResultFields() {
        let result = FeedbackResult(id: "fb_abc123", status: "new")
        XCTAssertEqual(result.id, "fb_abc123")
        XCTAssertEqual(result.status, "new")
    }

    // MARK: - PingKitError

    func testPingKitErrorNotConfigured() {
        let error = PingKitError.notConfigured
        if case .notConfigured = error {} else {
            XCTFail("Expected .notConfigured")
        }
    }

    func testPingKitErrorInvalidInput() {
        let error = PingKitError.invalidInput("too long")
        if case .invalidInput(let msg) = error {
            XCTAssertEqual(msg, "too long")
        } else {
            XCTFail("Expected .invalidInput")
        }
    }

    func testPingKitErrorServerError() {
        let error = PingKitError.serverError(code: "ERR", message: "msg")
        if case .serverError(let code, let message) = error {
            XCTAssertEqual(code, "ERR")
            XCTAssertEqual(message, "msg")
        } else {
            XCTFail("Expected .serverError")
        }
    }
}
