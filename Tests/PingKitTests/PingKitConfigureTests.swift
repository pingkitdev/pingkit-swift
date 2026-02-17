import XCTest
@testable import PingKit

final class PingKitConfigureTests: XCTestCase {
    override func tearDown() {
        resetPingKitState()
        super.tearDown()
    }

    func testConfigureSetsApiKey() {
        PingKit.configure(apiKey: "pk_proj_testkey123")
        XCTAssertEqual(PingKit.apiKey, "pk_proj_testkey123")
    }

    func testConfigureSetsCustomOptions() {
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
        XCTAssertEqual(PingKit.options.endpoint, "https://pingkit.dev")
        XCTAssertTrue(PingKit.options.enableAppAttest)
        XCTAssertEqual(PingKit.options.maxImageSizeMB, 5)
    }

    func testConfigureSetsCustomTheme() {
        let theme = PingKitTheme(cornerRadius: 30)
        PingKit.configure(apiKey: "pk_proj_test", theme: theme)
        XCTAssertEqual(PingKit.theme.cornerRadius, 30)
    }

    func testConfigureSetsDefaultTheme() {
        PingKit.configure(apiKey: "pk_proj_test")
        XCTAssertEqual(PingKit.theme.cornerRadius, 20)
        XCTAssertNil(PingKit.theme.cardColor)
    }

    func testReconfigureOverwritesPrevious() {
        PingKit.configure(apiKey: "pk_proj_first")
        PingKit.configure(apiKey: "pk_proj_second")
        XCTAssertEqual(PingKit.apiKey, "pk_proj_second")
    }

    func testVerboseFlag() {
        let options = PingKitOptions(verbose: true)
        PingKit.configure(apiKey: "pk_proj_test", options: options)
        XCTAssertTrue(PingKit.options.verbose)
    }

    func testDefaultVerboseIsFalse() {
        PingKit.configure(apiKey: "pk_proj_test")
        XCTAssertFalse(PingKit.options.verbose)
    }
}
