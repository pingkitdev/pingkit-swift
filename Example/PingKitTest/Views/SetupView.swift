import SwiftUI
import PingKit

struct SetupView: View {
    @AppStorage("apiKey") private var apiKey = ""
    @State private var inputKey = ""
    @AppStorage("customEndpoint") private var customEndpoint = "https://app.pingkit.dev"
    @AppStorage("enableAppAttest") private var enableAppAttest = true
    @AppStorage("maxImageSizeMB") private var maxImageSizeMB = 5.0
    @State private var showConfigured = false

    // Theme
    @State private var accentColor: PresetColor = .system
    @State private var useDarkBackground = false
    @State private var cornerRadius: Double = 20
    @State private var selectedFont: PresetFont = .body

    var body: some View {
        Form {
            Section("API Key") {
                HStack {
                    TextField("pk_proj_xxxxxxxxxxxx", text: $inputKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))

                    if !apiKey.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button {
                    configure()
                } label: {
                    HStack {
                        Spacer()
                        if showConfigured {
                            Label("Configured", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Text("Configure")
                        }
                        Spacer()
                    }
                    .font(.headline)
                }
                .disabled(inputKey.isEmpty)
            }

            Section {
                DisclosureGroup("Advanced") {
                    TextField("Endpoint", text: $customEndpoint)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))

                    Toggle("App Attest", isOn: $enableAppAttest)

                    VStack(alignment: .leading) {
                        Text("Max Image Size: \(Int(maxImageSizeMB)) MB")
                        Slider(value: $maxImageSizeMB, in: 1...20, step: 1)
                    }
                }
            }

            Section("Theme") {
                HStack(spacing: 12) {
                    ForEach(PresetColor.allCases, id: \.self) { preset in
                        Circle()
                            .fill(preset.color)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .strokeBorder(.primary, lineWidth: accentColor == preset ? 2 : 0)
                            )
                            .onTapGesture { accentColor = preset }
                    }
                }
                .padding(.vertical, 4)

                Toggle("Dark Background", isOn: $useDarkBackground)

                VStack(alignment: .leading) {
                    Text("Corner Radius: \(Int(cornerRadius))")
                    Slider(value: $cornerRadius, in: 0...40, step: 2)
                }

                Picker("Font", selection: $selectedFont) {
                    ForEach(PresetFont.allCases, id: \.self) { font in
                        Text(font.rawValue).tag(font)
                    }
                }
            }

        }
        .navigationTitle("Setup")
        .onAppear { inputKey = apiKey }
    }

    private func configure() {
        apiKey = inputKey

        let bgColor: Color = useDarkBackground
            ? .black
            : Color(uiColor: .systemBackground)

        PingKit.configure(
            apiKey: inputKey,
            options: PingKitOptions(
                endpoint: customEndpoint,
                enableAppAttest: enableAppAttest,
                maxImageSizeMB: maxImageSizeMB
            ),
            theme: PingKitTheme(
                accentColor: accentColor.color,
                backgroundColor: bgColor,
                cornerRadius: CGFloat(cornerRadius),
                font: selectedFont.font
            )
        )
        withAnimation { showConfigured = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { showConfigured = false }
        }
    }
}

// MARK: - Preset Color

enum PresetColor: String, CaseIterable {
    case blue = "Blue"
    case red = "Red"
    case green = "Green"
    case purple = "Purple"
    case orange = "Orange"
    case pink = "Pink"
    case system = "System"

    var color: Color {
        switch self {
        case .blue: return .blue
        case .red: return .red
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        case .pink: return .pink
        case .system: return .accentColor
        }
    }
}

// MARK: - Preset Font

enum PresetFont: String, CaseIterable {
    case body = "Body"
    case title = "Title"
    case caption = "Caption"
    case largeTitle = "Large Title"
    case monospaced = "Monospaced"

    var font: Font {
        switch self {
        case .body: return .body
        case .title: return .title3
        case .caption: return .caption
        case .largeTitle: return .largeTitle
        case .monospaced: return .system(.body, design: .monospaced)
        }
    }
}

#Preview {
    NavigationStack {
        SetupView()
    }
}
