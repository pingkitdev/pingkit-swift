import Foundation
@testable import PingKit

final class MockAttestService: AttestService, @unchecked Sendable {
    var isSupportedValue = true
    var generatedKeyId = "mock-key-id"
    var attestKeyError: Error?
    var generateAssertionError: Error?
    var generateKeyError: Error?

    private(set) var attestKeyCalled = false
    private(set) var generateAssertionCalled = false
    private(set) var generateKeyCalled = false

    var isSupported: Bool { isSupportedValue }

    func generateKey() async throws -> String {
        generateKeyCalled = true
        if let error = generateKeyError { throw error }
        return generatedKeyId
    }

    func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data {
        attestKeyCalled = true
        if let error = attestKeyError { throw error }
        return Data("mock-attestation".utf8)
    }

    func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data {
        generateAssertionCalled = true
        if let error = generateAssertionError { throw error }
        return Data("mock-assertion".utf8)
    }
}
