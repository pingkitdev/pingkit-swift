import XCTest
@testable import PingKit

/// An HTTPClient wrapper that injects the X-Synthetic-Token header to bypass App Attest in non-production environments.
private struct SyntheticTokenClient: HTTPClient {
    let token: String

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        var req = request
        req.setValue(token, forHTTPHeaderField: "X-Synthetic-Token")
        return try await URLSession.shared.data(for: req)
    }
}

@MainActor
final class IntegrationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        resetPingKitState()
    }

    override func tearDown() {
        super.tearDown()
        resetPingKitState()
    }

    private func loadEnv() -> [String: String] {
        // Try environment variables first, then fall back to .env file
        var env: [String: String] = [:]
        let processEnv = ProcessInfo.processInfo.environment

        // Read .env as baseline
        let testFile = URL(fileURLWithPath: #file)
        let packageRoot = testFile.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let envFile = packageRoot.appendingPathComponent(".env")
        if let contents = try? String(contentsOf: envFile, encoding: .utf8) {
            for line in contents.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
                guard let eq = trimmed.firstIndex(of: "=") else { continue }
                let key = String(trimmed[trimmed.startIndex..<eq])
                let value = String(trimmed[trimmed.index(after: eq)...])
                if !value.isEmpty { env[key] = value }
            }
        }

        // Process env overrides .env file
        for key in ["PINGKIT_TEST_API_KEY", "PINGKIT_SYNTHETIC_TOKEN"] {
            if let val = processEnv[key], !val.isEmpty { env[key] = val }
        }

        return env
    }

    private func configureForIntegration() throws {
        let env = loadEnv()

        guard let apiKey = env["PINGKIT_TEST_API_KEY"] else {
            throw XCTSkip("PINGKIT_TEST_API_KEY not set — skipping integration tests")
        }

        PingKit.configure(apiKey: apiKey, options: PingKitOptions(enableAppAttest: false))

        if let token = env["PINGKIT_SYNTHETIC_TOKEN"] {
            PingKit.httpClient = SyntheticTokenClient(token: token)
        }
    }

    func testBasicSubmit() async throws {
        try configureForIntegration()

        let result = try await PingKit.submit(text: "Integration test — basic submit")

        XCTAssertFalse(result.id.isEmpty)
        XCTAssertEqual(result.status, "new")
    }

    func testSubmitWithAllOptions() async throws {
        try configureForIntegration()

        let result = try await PingKit.submit(
            text: "Integration test — all options",
            email: "test@example.com",
            type: "bug",
            metadata: ["source": "integration_test"]
        )

        XCTAssertFalse(result.id.isEmpty)
        XCTAssertEqual(result.status, "new")
    }

    func testSubmitWithDeviceInfoDisabled() async throws {
        try configureForIntegration()

        let result = try await PingKit.submit(
            text: "Integration test — no device info",
            includeDeviceInfo: false
        )

        XCTAssertFalse(result.id.isEmpty)
        XCTAssertEqual(result.status, "new")
    }

    func testUnauthorizedWithInvalidKey() async throws {
        PingKit.configure(apiKey: "pk_proj_invalid_key", options: PingKitOptions(enableAppAttest: false))

        do {
            _ = try await PingKit.submit(text: "Should fail with unauthorized")
            XCTFail("Expected PingKitError.unauthorized")
        } catch let error as PingKitError {
            guard case .unauthorized = error else {
                XCTFail("Expected .unauthorized, got \(error)")
                return
            }
        }
    }
}
