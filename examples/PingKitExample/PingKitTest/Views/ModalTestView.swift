import SwiftUI
import PingKit

struct ModalTestView: View {
    enum EmailSelection: String, CaseIterable {
        case none = "None"
        case optional = "Optional"
        case required = "Required"
        case prefilled = "Prefilled"
    }

    @State private var emailMode: EmailSelection = .none
    @State private var prefilledEmail = "user@example.com"
    @State private var enableTypePicker = false
    @State private var categories = ["Bug", "Feature", "Other"]
    @State private var enableMetadata = false
    @State private var metadataScreen = "checkout"
    @State private var metadataTier = "premium"
    @AppStorage("apiKey") private var apiKey = ""

    var body: some View {
        Form {
            Section("Email") {
                Picker("Mode", selection: $emailMode) {
                    ForEach(EmailSelection.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if emailMode == .prefilled {
                    TextField("Prefilled email", text: $prefilledEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
            }

            Section("Type Picker") {
                Toggle("Enable", isOn: $enableTypePicker)
                if enableTypePicker {
                    Text(categories.joined(separator: ", "))
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            Section("Metadata") {
                Toggle("Enable", isOn: $enableMetadata)
                if enableMetadata {
                    LabeledContent("screen") {
                        TextField("value", text: $metadataScreen)
                    }
                    LabeledContent("user_tier") {
                        TextField("value", text: $metadataTier)
                    }
                }
            }

            Section {
                Button {
                    showModal()
                } label: {
                    Text("Show Modal")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .disabled(apiKey.isEmpty)
            }

            Section("Generated Code") {
                Text(generatedCode)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            if apiKey.isEmpty {
                Section {
                    Label("Configure an API key in Setup first", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("Modal")
    }

    private func showModal() {
        let email: EmailMode? = {
            switch emailMode {
            case .none: return nil
            case .optional: return .optional
            case .required: return .required
            case .prefilled: return .prefilled(prefilledEmail)
            }
        }()

        let type: TypeMode? = enableTypePicker ? .picker(categories) : nil
        let metadata: [String: String]? = enableMetadata
            ? ["screen": metadataScreen, "user_tier": metadataTier]
            : nil

        PingKit.show(email: email, type: type, metadata: metadata)
    }

    private var generatedCode: String {
        var parts: [String] = []

        switch emailMode {
        case .none: break
        case .optional: parts.append("email: .optional")
        case .required: parts.append("email: .required")
        case .prefilled: parts.append("email: .prefilled(\"\(prefilledEmail)\")")
        }

        if enableTypePicker {
            parts.append("type: .picker([\(categories.map { "\"\($0)\"" }.joined(separator: ", "))])")
        }

        if enableMetadata {
            parts.append("metadata: [\"screen\": \"\(metadataScreen)\", \"user_tier\": \"\(metadataTier)\"]")
        }

        if parts.isEmpty {
            return "PingKit.show()"
        }

        return "PingKit.show(\n  \(parts.joined(separator: ",\n  "))\n)"
    }
}

#Preview {
    NavigationStack {
        ModalTestView()
    }
}
