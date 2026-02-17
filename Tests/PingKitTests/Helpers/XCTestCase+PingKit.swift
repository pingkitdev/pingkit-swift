import XCTest
@testable import PingKit

extension XCTestCase {
    func resetPingKitState() {
        PingKit.apiKey = nil
        PingKit.options = PingKitOptions()
        PingKit.theme = PingKitTheme()
        PingKit.httpClient = URLSession.shared
        #if os(macOS)
        PingKit.sheetWindow = nil
        PingKit.isShowingFeedback = false
        #endif
    }

    func configurePingKit(
        apiKey: String = "pk_proj_test",
        options: PingKitOptions = PingKitOptions(enableAppAttest: false),
        theme: PingKitTheme = PingKitTheme()
    ) {
        PingKit.apiKey = apiKey
        PingKit.options = options
        PingKit.theme = theme
    }
}
