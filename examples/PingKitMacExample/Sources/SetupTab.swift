import SwiftUI
import PingKit

struct SetupTab: View {
    @AppStorage("pingkit_api_key") private var apiKey = ""
    @State private var verbose = true
    @State private var enableAppAttest = false
    @State private var isConfigured = false

    var body: some View {
        Form {
            Section {
                TextField("API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)

                Toggle("Verbose Logging", isOn: $verbose)
                Toggle("App Attest (iOS only)", isOn: $enableAppAttest)
            } header: {
                Text("Configuration")
            }

            Section {
                Button("Configure PingKit") {
                    PingKit.configure(
                        apiKey: apiKey,
                        options: PingKitOptions(
                            enableAppAttest: enableAppAttest,
                            verbose: verbose
                        )
                    )
                    isConfigured = true
                }
                .disabled(apiKey.isEmpty)
                .buttonStyle(.borderedProminent)

                if isConfigured {
                    Label("PingKit configured", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key: \(PingKit.apiKey ?? "not set")")
                    Text("Endpoint: \(PingKit.options.endpoint)")
                    Text("Verbose: \(PingKit.options.verbose ? "on" : "off")")
                }
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
            } header: {
                Text("Current State")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
