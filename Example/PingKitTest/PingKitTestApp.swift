import SwiftUI
import PingKit

@main
struct PingKitTestApp: App {
    @AppStorage("apiKey") private var apiKey = ""
    @AppStorage("customEndpoint") private var customEndpoint = "https://app.pingkit.dev"
    @AppStorage("enableAppAttest") private var enableAppAttest = true
    @AppStorage("maxImageSizeMB") private var maxImageSizeMB = 5

    init() {
        let savedKey = UserDefaults.standard.string(forKey: "apiKey") ?? ""
        if !savedKey.isEmpty {
            let endpoint = UserDefaults.standard.string(forKey: "customEndpoint") ?? "https://app.pingkit.dev"
            let attest = UserDefaults.standard.object(forKey: "enableAppAttest") as? Bool ?? true
            let imageSize = UserDefaults.standard.object(forKey: "maxImageSizeMB") as? Double ?? 5.0
            PingKit.configure(
                apiKey: savedKey,
                options: PingKitOptions(
                    endpoint: endpoint,
                    enableAppAttest: attest,
                    maxImageSizeMB: imageSize
                )
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
