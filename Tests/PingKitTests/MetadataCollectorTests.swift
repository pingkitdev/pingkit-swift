import XCTest
@testable import PingKit

@MainActor
final class MetadataCollectorTests: XCTestCase {

    func testDeviceModelNotEmpty() {
        let metadata = MetadataCollector.collect()
        XCTAssertFalse(metadata.deviceModel.isEmpty)
    }

    func testOSVersionNotEmpty() {
        let metadata = MetadataCollector.collect()
        XCTAssertFalse(metadata.osVersion.isEmpty)
    }

    func testAppVersionNotEmpty() {
        let metadata = MetadataCollector.collect()
        // In test bundle, may be "unknown" but should not be empty
        XCTAssertFalse(metadata.appVersion.isEmpty)
    }

    func testLocaleNotEmpty() {
        let metadata = MetadataCollector.collect()
        XCTAssertFalse(metadata.locale.isEmpty)
    }

    func testTimezoneNotEmpty() {
        let metadata = MetadataCollector.collect()
        XCTAssertFalse(metadata.timezone.isEmpty)
    }
}
