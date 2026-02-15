import Foundation
@testable import PingKit

final class MockKeychainStore: KeychainStore, @unchecked Sendable {
    private var storage: [String: String] = [:]

    func save(key: String, value: String) {
        storage[key] = value
    }

    func load(key: String) -> String? {
        storage[key]
    }

    func reset() {
        storage.removeAll()
    }
}
