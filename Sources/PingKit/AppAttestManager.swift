import Foundation
import DeviceCheck
import CryptoKit

actor AppAttestManager {
    private var keyId: String?
    private var isAttested = false
    private let service = DCAppAttestService.shared

    var isSupported: Bool {
        service.isSupported
    }

    func prepare() async throws {
        guard service.isSupported else { return }

        // Check Keychain for existing key ID
        if let existingKeyId = KeychainHelper.load(key: "pingkit_attest_key_id") {
            keyId = existingKeyId
            // If we have a stored key ID, it was attested in a previous session
            isAttested = KeychainHelper.load(key: "pingkit_attest_completed") != nil
            return
        }

        // Generate new key
        let newKeyId = try await service.generateKey()
        keyId = newKeyId
        KeychainHelper.save(key: "pingkit_attest_key_id", value: newKeyId)
    }

    func generateAssertion(for bodyData: Data) async throws -> (assertion: String, keyId: String)? {
        guard service.isSupported, let keyId else { return nil }

        // Attest the key if not yet attested
        if !isAttested {
            let attestHash = Data(SHA256.hash(data: Data("pingkit-attest".utf8)))
            _ = try await service.attestKey(keyId, clientDataHash: attestHash)
            isAttested = true
            KeychainHelper.save(key: "pingkit_attest_completed", value: "true")
        }

        let hash = SHA256.hash(data: bodyData)
        let clientDataHash = Data(hash)

        let assertion = try await service.generateAssertion(keyId, clientDataHash: clientDataHash)
        return (assertion: assertion.base64EncodedString(), keyId: keyId)
    }
}

// MARK: - Keychain helper

private enum KeychainHelper {
    static func save(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(key: String) -> String? {
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
