import XCTest
@testable import PingKit

final class APIClientTests: XCTestCase {
    private var mock: MockHTTPClient!

    override func setUp() {
        super.setUp()
        mock = MockHTTPClient()
    }

    override func tearDown() {
        mock = nil
        super.tearDown()
    }

    // MARK: - Success

    func testSubmit201ReturnsResult() async throws {
        mock.setSuccessResponse(id: "fb_abc123", status: "new")
        mock.statusCode = 201

        let result = try await APIClient.submitFeedback(
            text: "Great app!",
            imageData: nil,
            metadata: nil,
            customMetadata: nil,
            endpoint: "https://test.pingkit.dev",
            apiKey: "pk_proj_test",
            attestAssertion: nil,
            attestKeyId: nil,
            httpClient: mock
        )

        XCTAssertEqual(result.id, "fb_abc123")
        XCTAssertEqual(result.status, "new")
    }

    // MARK: - Error status codes

    func testSubmit401ThrowsUnauthorized() async {
        mock.statusCode = 401
        mock.responseData = Data()

        await assertThrowsPingKitError(.unauthorized) {
            try await APIClient.submitFeedback(
                text: "test", imageData: nil, metadata: nil, customMetadata: nil,
                endpoint: "https://test.pingkit.dev", apiKey: "bad_key",
                attestAssertion: nil, attestKeyId: nil, httpClient: mock
            )
        }
    }

    func testSubmit403ThrowsAttestRequired() async {
        mock.statusCode = 403
        mock.responseData = Data()

        await assertThrowsPingKitError(.attestRequired) {
            try await APIClient.submitFeedback(
                text: "test", imageData: nil, metadata: nil, customMetadata: nil,
                endpoint: "https://test.pingkit.dev", apiKey: "pk_proj_test",
                attestAssertion: nil, attestKeyId: nil, httpClient: mock
            )
        }
    }

    func testSubmit413ThrowsImageTooLarge() async {
        mock.statusCode = 413
        mock.responseData = Data()

        await assertThrowsPingKitError(.imageTooLarge) {
            try await APIClient.submitFeedback(
                text: "test", imageData: nil, metadata: nil, customMetadata: nil,
                endpoint: "https://test.pingkit.dev", apiKey: "pk_proj_test",
                attestAssertion: nil, attestKeyId: nil, httpClient: mock
            )
        }
    }

    func testSubmit429ThrowsRateLimited() async {
        mock.statusCode = 429
        mock.setErrorResponse(code: "RATE_LIMIT", message: "Too many requests")

        do {
            _ = try await APIClient.submitFeedback(
                text: "test", imageData: nil, metadata: nil, customMetadata: nil,
                endpoint: "https://test.pingkit.dev", apiKey: "pk_proj_test",
                attestAssertion: nil, attestKeyId: nil, httpClient: mock
            )
            XCTFail("Expected rateLimited error")
        } catch let error as PingKitError {
            if case .rateLimited = error {
                // Expected
            } else {
                XCTFail("Expected .rateLimited, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSubmit429WithPlanLimitThrowsPlanLimitReached() async {
        mock.statusCode = 429
        mock.setErrorResponse(code: "PLAN_LIMIT", message: "Monthly limit reached")

        await assertThrowsPingKitError(.planLimitReached) {
            try await APIClient.submitFeedback(
                text: "test", imageData: nil, metadata: nil, customMetadata: nil,
                endpoint: "https://test.pingkit.dev", apiKey: "pk_proj_test",
                attestAssertion: nil, attestKeyId: nil, httpClient: mock
            )
        }
    }

    func testSubmit500ThrowsServerError() async {
        mock.statusCode = 500
        mock.setErrorResponse(code: "INTERNAL", message: "Something broke")

        do {
            _ = try await APIClient.submitFeedback(
                text: "test", imageData: nil, metadata: nil, customMetadata: nil,
                endpoint: "https://test.pingkit.dev", apiKey: "pk_proj_test",
                attestAssertion: nil, attestKeyId: nil, httpClient: mock
            )
            XCTFail("Expected serverError")
        } catch let error as PingKitError {
            if case .serverError(let code, let message) = error {
                XCTAssertEqual(code, "INTERNAL")
                XCTAssertEqual(message, "Something broke")
            } else {
                XCTFail("Expected .serverError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSubmit500WithUnparseableBodyUsesDefaults() async {
        mock.statusCode = 500
        mock.responseData = Data("not json".utf8)

        do {
            _ = try await APIClient.submitFeedback(
                text: "test", imageData: nil, metadata: nil, customMetadata: nil,
                endpoint: "https://test.pingkit.dev", apiKey: "pk_proj_test",
                attestAssertion: nil, attestKeyId: nil, httpClient: mock
            )
            XCTFail("Expected serverError")
        } catch let error as PingKitError {
            if case .serverError(let code, let message) = error {
                XCTAssertEqual(code, "UNKNOWN")
                XCTAssertEqual(message, "An unexpected error occurred")
            } else {
                XCTFail("Expected .serverError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Network errors

    func testNetworkErrorThrowsNetworkError() async {
        mock.error = URLError(.notConnectedToInternet)

        do {
            _ = try await APIClient.submitFeedback(
                text: "test", imageData: nil, metadata: nil, customMetadata: nil,
                endpoint: "https://test.pingkit.dev", apiKey: "pk_proj_test",
                attestAssertion: nil, attestKeyId: nil, httpClient: mock
            )
            XCTFail("Expected networkError")
        } catch let error as PingKitError {
            if case .networkError(let underlying) = error {
                XCTAssertTrue(underlying is URLError)
            } else {
                XCTFail("Expected .networkError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testTimeoutErrorThrowsNetworkError() async {
        mock.error = URLError(.timedOut)

        do {
            _ = try await APIClient.submitFeedback(
                text: "test", imageData: nil, metadata: nil, customMetadata: nil,
                endpoint: "https://test.pingkit.dev", apiKey: "pk_proj_test",
                attestAssertion: nil, attestKeyId: nil, httpClient: mock
            )
            XCTFail("Expected networkError")
        } catch let error as PingKitError {
            if case .networkError = error {
                // Expected
            } else {
                XCTFail("Expected .networkError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Request format

    func testJSONRequestFormat() async throws {
        mock.setSuccessResponse()
        mock.statusCode = 201

        _ = try await APIClient.submitFeedback(
            text: "Hello",
            imageData: nil,
            metadata: nil,
            customMetadata: nil,
            endpoint: "https://test.pingkit.dev",
            apiKey: "pk_proj_test",
            attestAssertion: nil,
            attestKeyId: nil,
            httpClient: mock
        )

        let request = mock.lastRequest!
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.httpMethod, "POST")

        let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
        XCTAssertEqual(body["text"] as? String, "Hello")
    }

    func testMultipartRequestFormat() async throws {
        mock.setSuccessResponse()
        mock.statusCode = 201

        let imageData = Data(repeating: 0xFF, count: 100)
        _ = try await APIClient.submitFeedback(
            text: "Bug report",
            imageData: imageData,
            metadata: nil,
            customMetadata: nil,
            endpoint: "https://test.pingkit.dev",
            apiKey: "pk_proj_test",
            attestAssertion: nil,
            attestKeyId: nil,
            httpClient: mock
        )

        let request = mock.lastRequest!
        let contentType = request.value(forHTTPHeaderField: "Content-Type")!
        XCTAssertTrue(contentType.starts(with: "multipart/form-data; boundary="))
    }

    func testAPIKeyHeader() async throws {
        mock.setSuccessResponse()
        mock.statusCode = 201

        _ = try await APIClient.submitFeedback(
            text: "test", imageData: nil, metadata: nil, customMetadata: nil,
            endpoint: "https://test.pingkit.dev", apiKey: "pk_proj_mykey",
            attestAssertion: nil, attestKeyId: nil, httpClient: mock
        )

        XCTAssertEqual(mock.lastRequest?.value(forHTTPHeaderField: "X-API-Key"), "pk_proj_mykey")
    }

    func testAttestHeaders() async throws {
        mock.setSuccessResponse()
        mock.statusCode = 201

        _ = try await APIClient.submitFeedback(
            text: "test", imageData: nil, metadata: nil, customMetadata: nil,
            endpoint: "https://test.pingkit.dev", apiKey: "pk_proj_test",
            attestAssertion: "assertion123", attestKeyId: "keyid456",
            httpClient: mock
        )

        XCTAssertEqual(mock.lastRequest?.value(forHTTPHeaderField: "X-Apple-Attest-Assertion"), "assertion123")
        XCTAssertEqual(mock.lastRequest?.value(forHTTPHeaderField: "X-Apple-Attest-Key-Id"), "keyid456")
    }

    func testNoAttestHeadersWhenNil() async throws {
        mock.setSuccessResponse()
        mock.statusCode = 201

        _ = try await APIClient.submitFeedback(
            text: "test", imageData: nil, metadata: nil, customMetadata: nil,
            endpoint: "https://test.pingkit.dev", apiKey: "pk_proj_test",
            attestAssertion: nil, attestKeyId: nil, httpClient: mock
        )

        XCTAssertNil(mock.lastRequest?.value(forHTTPHeaderField: "X-Apple-Attest-Assertion"))
        XCTAssertNil(mock.lastRequest?.value(forHTTPHeaderField: "X-Apple-Attest-Key-Id"))
    }

    func testEndpointURL() async throws {
        mock.setSuccessResponse()
        mock.statusCode = 201

        _ = try await APIClient.submitFeedback(
            text: "test", imageData: nil, metadata: nil, customMetadata: nil,
            endpoint: "https://custom.example.com", apiKey: "pk_proj_test",
            attestAssertion: nil, attestKeyId: nil, httpClient: mock
        )

        XCTAssertEqual(mock.lastRequest?.url?.absoluteString, "https://custom.example.com/v1/feedback")
    }

    func testMetadataIncludedInBody() async throws {
        mock.setSuccessResponse()
        mock.statusCode = 201

        let metadata = DeviceMetadata(
            deviceModel: "iPhone15,2",
            osVersion: "17.0",
            appVersion: "1.0",
            appBuild: "42",
            locale: "en_US",
            timezone: "America/New_York"
        )

        _ = try await APIClient.submitFeedback(
            text: "test", imageData: nil, metadata: metadata, customMetadata: ["key": "value"],
            endpoint: "https://test.pingkit.dev", apiKey: "pk_proj_test",
            attestAssertion: nil, attestKeyId: nil, httpClient: mock
        )

        let body = try JSONSerialization.jsonObject(with: mock.lastRequest!.httpBody!) as! [String: Any]
        XCTAssertEqual(body["device_model"] as? String, "iPhone15,2")
        XCTAssertEqual(body["os_version"] as? String, "17.0")
        XCTAssertEqual(body["app_version"] as? String, "1.0")
        XCTAssertEqual(body["app_build"] as? String, "42")
        XCTAssertEqual(body["locale"] as? String, "en_US")
        XCTAssertEqual(body["timezone"] as? String, "America/New_York")

        let custom = body["custom_metadata"] as? [String: String]
        XCTAssertEqual(custom?["key"], "value")
    }

    func testTimeoutIntervalIs30() async throws {
        mock.setSuccessResponse()
        mock.statusCode = 201

        _ = try await APIClient.submitFeedback(
            text: "test", imageData: nil, metadata: nil, customMetadata: nil,
            endpoint: "https://test.pingkit.dev", apiKey: "pk_proj_test",
            attestAssertion: nil, attestKeyId: nil, httpClient: mock
        )

        XCTAssertEqual(mock.lastRequest?.timeoutInterval, 30)
    }

    // MARK: - Helpers

    private func assertThrowsPingKitError(
        _ expected: PingKitError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ block: () async throws -> some Any
    ) async {
        do {
            _ = try await block()
            XCTFail("Expected PingKitError", file: file, line: line)
        } catch let error as PingKitError {
            switch (error, expected) {
            case (.unauthorized, .unauthorized),
                 (.attestRequired, .attestRequired),
                 (.imageTooLarge, .imageTooLarge),
                 (.planLimitReached, .planLimitReached),
                 (.notConfigured, .notConfigured):
                break // Match
            default:
                XCTFail("Expected \(expected), got \(error)", file: file, line: line)
            }
        } catch {
            XCTFail("Unexpected error type: \(error)", file: file, line: line)
        }
    }
}
