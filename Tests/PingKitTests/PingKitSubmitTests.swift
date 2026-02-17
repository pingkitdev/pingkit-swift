import XCTest
@testable import PingKit

@MainActor
final class PingKitSubmitTests: XCTestCase {
    private var mock: MockHTTPClient!

    override func setUp() {
        super.setUp()
        mock = MockHTTPClient()
        mock.setSuccessResponse()
        mock.statusCode = 201
        configurePingKit()
        PingKit.httpClient = mock
    }

    override func tearDown() {
        resetPingKitState()
        mock = nil
        super.tearDown()
    }

    // MARK: - Validation

    func testSubmitWithoutConfigureThrows() async {
        PingKit.apiKey = nil
        do {
            try await PingKit.submit(text: "test")
            XCTFail("Expected notConfigured")
        } catch let error as PingKitError {
            if case .notConfigured = error {} else {
                XCTFail("Expected .notConfigured, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSubmitRejectsEmptyText() async {
        do {
            try await PingKit.submit(text: "")
            XCTFail("Expected invalidInput")
        } catch let error as PingKitError {
            if case .invalidInput = error {} else {
                XCTFail("Expected .invalidInput, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSubmitRejectsWhitespaceOnly() async {
        do {
            try await PingKit.submit(text: "   \n\t  ")
            XCTFail("Expected invalidInput")
        } catch let error as PingKitError {
            if case .invalidInput = error {} else {
                XCTFail("Expected .invalidInput, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSubmitAccepts5000Characters() async throws {
        let text = String(repeating: "a", count: 5000)
        let result = try await PingKit.submit(text: text)
        XCTAssertEqual(result.id, "fb_test123")
    }

    func testSubmitRejects5001Characters() async {
        let text = String(repeating: "a", count: 5001)
        do {
            try await PingKit.submit(text: text)
            XCTFail("Expected invalidInput")
        } catch let error as PingKitError {
            if case .invalidInput = error {} else {
                XCTFail("Expected .invalidInput, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Reserved metadata keys

    func testEmailAddedAsReservedKey() async throws {
        _ = try await PingKit.submit(text: "test", email: "user@example.com")

        let body = try JSONSerialization.jsonObject(with: mock.lastRequest!.httpBody!) as! [String: Any]
        let custom = body["custom_metadata"] as? [String: String]
        XCTAssertEqual(custom?["_email"], "user@example.com")
    }

    func testTypeAddedAsReservedKey() async throws {
        _ = try await PingKit.submit(text: "test", type: "Bug")

        let body = try JSONSerialization.jsonObject(with: mock.lastRequest!.httpBody!) as! [String: Any]
        let custom = body["custom_metadata"] as? [String: String]
        XCTAssertEqual(custom?["_type"], "Bug")
    }

    func testCustomMetadataMergedWithReservedKeys() async throws {
        _ = try await PingKit.submit(
            text: "test",
            email: "a@b.com",
            type: "Feature",
            metadata: ["source": "settings"]
        )

        let body = try JSONSerialization.jsonObject(with: mock.lastRequest!.httpBody!) as! [String: Any]
        let custom = body["custom_metadata"] as? [String: String]
        XCTAssertEqual(custom?["_email"], "a@b.com")
        XCTAssertEqual(custom?["_type"], "Feature")
        XCTAssertEqual(custom?["source"], "settings")
    }

    // MARK: - Device info toggle

    func testDeviceInfoIncludedByDefault() async throws {
        _ = try await PingKit.submit(text: "test")

        let body = try JSONSerialization.jsonObject(with: mock.lastRequest!.httpBody!) as! [String: Any]
        XCTAssertNotNil(body["device_model"])
        XCTAssertNotNil(body["os_version"])
    }

    func testDeviceInfoExcludedWhenDisabled() async throws {
        _ = try await PingKit.submit(text: "test", includeDeviceInfo: false)

        let body = try JSONSerialization.jsonObject(with: mock.lastRequest!.httpBody!) as! [String: Any]
        XCTAssertNil(body["device_model"])
        XCTAssertNil(body["os_version"])
    }

    // MARK: - Request properties

    func testAPIKeyHeaderPassedThrough() async throws {
        configurePingKit(apiKey: "pk_proj_myspecialkey")
        PingKit.httpClient = mock
        _ = try await PingKit.submit(text: "test")

        XCTAssertEqual(mock.lastRequest?.value(forHTTPHeaderField: "X-API-Key"), "pk_proj_myspecialkey")
    }

    func testEndpointURLUsedFromOptions() async throws {
        configurePingKit(options: PingKitOptions(endpoint: "https://custom.example.com", enableAppAttest: false))
        PingKit.httpClient = mock
        _ = try await PingKit.submit(text: "test")

        XCTAssertEqual(mock.lastRequest?.url?.absoluteString, "https://custom.example.com/v1/feedback")
    }

    // MARK: - Result passthrough

    func testServerResultPassedThrough() async throws {
        mock.setSuccessResponse(id: "fb_server456", status: "new")
        let result = try await PingKit.submit(text: "test")

        XCTAssertEqual(result.id, "fb_server456")
        XCTAssertEqual(result.status, "new")
    }
}
