import Foundation
#if canImport(DeviceCheck)
import DeviceCheck
#endif
import CryptoKit

// MARK: - Protocols for testability

protocol AttestService: Sendable {
    var isSupported: Bool { get }
    func generateKey() async throws -> String
    func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data
    func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data
}

#if os(iOS)
extension DCAppAttestService: AttestService {}
#endif

protocol KeychainStore: Sendable {
    func save(key: String, value: String)
    func load(key: String) -> String?
}

struct SystemKeychainStore: KeychainStore {
    func save(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - AppAttestManager

actor AppAttestManager {
    private var keyId: String?
    private var isAttested = false
    private let service: AttestService
    private let keychain: KeychainStore

    var isSupported: Bool {
        service.isSupported
    }

    #if os(iOS)
    init(service: AttestService = DCAppAttestService.shared, keychain: KeychainStore = SystemKeychainStore()) {
        self.service = service
        self.keychain = keychain
    }
    #else
    init(service: AttestService, keychain: KeychainStore = SystemKeychainStore()) {
        self.service = service
        self.keychain = keychain
    }

    init() {
        self.service = UnsupportedAttestService()
        self.keychain = SystemKeychainStore()
    }
    #endif

    func prepare() async throws {
        guard service.isSupported else { return }

        // Check Keychain for existing key ID
        if let existingKeyId = keychain.load(key: "pingkit_attest_key_id") {
            keyId = existingKeyId
            // If we have a stored key ID, it was attested in a previous session
            isAttested = keychain.load(key: "pingkit_attest_completed") != nil
            return
        }

        // Generate new key
        let newKeyId = try await service.generateKey()
        keyId = newKeyId
        keychain.save(key: "pingkit_attest_key_id", value: newKeyId)
    }

    func generateAssertion(for bodyData: Data) async throws -> (assertion: String, keyId: String)? {
        guard service.isSupported, let keyId else { return nil }

        // Attest the key if not yet attested
        if !isAttested {
            let attestHash = Data(SHA256.hash(data: Data("pingkit-attest".utf8)))
            _ = try await service.attestKey(keyId, clientDataHash: attestHash)
            isAttested = true
            keychain.save(key: "pingkit_attest_completed", value: "true")
        }

        let hash = SHA256.hash(data: bodyData)
        let clientDataHash = Data(hash)

        let assertion = try await service.generateAssertion(keyId, clientDataHash: clientDataHash)
        return (assertion: assertion.base64EncodedString(), keyId: keyId)
    }
}

#if !os(iOS)
private struct UnsupportedAttestService: AttestService {
    var isSupported: Bool { false }
    func generateKey() async throws -> String { fatalError("Not supported") }
    func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data { fatalError("Not supported") }
    func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data { fatalError("Not supported") }
}
#endif
