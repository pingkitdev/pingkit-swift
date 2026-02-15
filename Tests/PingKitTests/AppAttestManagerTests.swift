import XCTest
@testable import PingKit

final class AppAttestManagerTests: XCTestCase {
    private var mockService: MockAttestService!
    private var mockKeychain: MockKeychainStore!

    override func setUp() {
        super.setUp()
        mockService = MockAttestService()
        mockKeychain = MockKeychainStore()
    }

    override func tearDown() {
        mockService = nil
        mockKeychain = nil
        super.tearDown()
    }

    private func makeManager() -> AppAttestManager {
        AppAttestManager(service: mockService, keychain: mockKeychain)
    }

    // MARK: - prepare()

    func testPrepareWhenSupportedGeneratesKey() async throws {
        let manager = makeManager()
        try await manager.prepare()

        XCTAssertTrue(mockService.generateKeyCalled)
        XCTAssertEqual(mockKeychain.load(key: "pingkit_attest_key_id"), "mock-key-id")
    }

    func testPrepareWhenUnsupportedSkips() async throws {
        mockService.isSupportedValue = false
        let manager = makeManager()
        try await manager.prepare()

        XCTAssertFalse(mockService.generateKeyCalled)
        XCTAssertNil(mockKeychain.load(key: "pingkit_attest_key_id"))
    }

    func testPrepareRestoresFromKeychain() async throws {
        mockKeychain.save(key: "pingkit_attest_key_id", value: "existing-key")
        mockKeychain.save(key: "pingkit_attest_completed", value: "true")

        let manager = makeManager()
        try await manager.prepare()

        XCTAssertFalse(mockService.generateKeyCalled)
    }

    func testPrepareRestoresKeyWithoutAttestCompleted() async throws {
        mockKeychain.save(key: "pingkit_attest_key_id", value: "existing-key")
        // No "pingkit_attest_completed" — key exists but wasn't attested

        let manager = makeManager()
        try await manager.prepare()

        XCTAssertFalse(mockService.generateKeyCalled)
    }

    // MARK: - generateAssertion()

    func testGenerateAssertionFirstTimeAttestsKey() async throws {
        let manager = makeManager()
        try await manager.prepare()

        let bodyData = Data("hello".utf8)
        let result = try await manager.generateAssertion(for: bodyData)

        XCTAssertNotNil(result)
        XCTAssertTrue(mockService.attestKeyCalled)
        XCTAssertTrue(mockService.generateAssertionCalled)
        XCTAssertEqual(mockKeychain.load(key: "pingkit_attest_completed"), "true")
    }

    func testGenerateAssertionSubsequentCallSkipsAttest() async throws {
        mockKeychain.save(key: "pingkit_attest_key_id", value: "existing-key")
        mockKeychain.save(key: "pingkit_attest_completed", value: "true")

        let manager = makeManager()
        try await manager.prepare()

        let result = try await manager.generateAssertion(for: Data("test".utf8))

        XCTAssertNotNil(result)
        XCTAssertFalse(mockService.attestKeyCalled)
        XCTAssertTrue(mockService.generateAssertionCalled)
    }

    func testGenerateAssertionUnsupportedReturnsNil() async throws {
        mockService.isSupportedValue = false
        let manager = makeManager()

        let result = try await manager.generateAssertion(for: Data("test".utf8))
        XCTAssertNil(result)
    }

    func testGenerateAssertionReturnsBase64() async throws {
        let manager = makeManager()
        try await manager.prepare()

        let result = try await manager.generateAssertion(for: Data("test".utf8))

        XCTAssertNotNil(result)
        // Verify the assertion is valid base64
        XCTAssertNotNil(Data(base64Encoded: result!.assertion))
        XCTAssertEqual(result!.keyId, "mock-key-id")
    }

    func testGenerateAssertionWithoutPrepareReturnsNil() async throws {
        let manager = makeManager()
        // Don't call prepare — no keyId set
        let result = try await manager.generateAssertion(for: Data("test".utf8))
        XCTAssertNil(result)
    }
}
