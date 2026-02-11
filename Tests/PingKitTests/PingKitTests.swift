import XCTest
@testable import PingKit

final class PingKitTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        // Reset state between tests
        PingKit.apiKey = nil
    }

    func testConfigureSetsApiKey() {
        PingKit.configure(apiKey: "pk_proj_testkey123")
        XCTAssertEqual(PingKit.apiKey, "pk_proj_testkey123")
    }

    func testConfigureSetsOptions() {
        let options = PingKitOptions(
            endpoint: "https://custom.example.com",
            enableAppAttest: false,
            maxImageSizeMB: 3
        )
        PingKit.configure(apiKey: "pk_proj_test", options: options)
        XCTAssertEqual(PingKit.options.endpoint, "https://custom.example.com")
        XCTAssertFalse(PingKit.options.enableAppAttest)
        XCTAssertEqual(PingKit.options.maxImageSizeMB, 3)
    }

    func testConfigureSetsDefaultOptions() {
        PingKit.configure(apiKey: "pk_proj_test")
        XCTAssertEqual(PingKit.options.endpoint, "https://app.pingkit.dev")
        XCTAssertTrue(PingKit.options.enableAppAttest)
        XCTAssertEqual(PingKit.options.maxImageSizeMB, 5)
    }

    func testSubmitWithoutConfigureThrows() async {
        do {
            try await PingKit.submit(text: "test")
            XCTFail("Expected PingKitError.notConfigured")
        } catch let error as PingKitError {
            if case .notConfigured = error {
                // Expected
            } else {
                XCTFail("Expected .notConfigured, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSubmitRejectsEmptyText() async {
        PingKit.configure(apiKey: "pk_proj_test")
        do {
            try await PingKit.submit(text: "")
            XCTFail("Expected PingKitError.invalidInput")
        } catch let error as PingKitError {
            if case .invalidInput = error {
                // Expected
            } else {
                XCTFail("Expected .invalidInput, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSubmitRejectsWhitespaceOnlyText() async {
        PingKit.configure(apiKey: "pk_proj_test")
        do {
            try await PingKit.submit(text: "   \n\t  ")
            XCTFail("Expected PingKitError.invalidInput")
        } catch let error as PingKitError {
            if case .invalidInput = error {
                // Expected
            } else {
                XCTFail("Expected .invalidInput, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSubmitRejectsOverlongText() async {
        PingKit.configure(apiKey: "pk_proj_test")
        let longText = String(repeating: "a", count: 5001)
        do {
            try await PingKit.submit(text: longText)
            XCTFail("Expected PingKitError.invalidInput")
        } catch let error as PingKitError {
            if case .invalidInput = error {
                // Expected
            } else {
                XCTFail("Expected .invalidInput, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
