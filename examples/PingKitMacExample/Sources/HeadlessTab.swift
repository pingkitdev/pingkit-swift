import SwiftUI
import PingKit

struct HeadlessTab: View {
    @State private var feedbackText = "Test feedback from macOS example app"
    @State private var email = ""
    @State private var type = ""
    @State private var metadataKey = ""
    @State private var metadataValue = ""
    @State private var customMetadata: [String: String] = [:]
    @State private var includeDeviceInfo = true
    @State private var isSubmitting = false
    @State private var result: String?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                TextEditor(text: $feedbackText)
                    .frame(minHeight: 80)
                Text("\(feedbackText.count)/5000")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } header: {
                Text("Feedback Text")
            }

            Section {
                TextField("Email (optional)", text: $email)
                TextField("Type (optional)", text: $type)
                Toggle("Include Device Info", isOn: $includeDeviceInfo)
            } header: {
                Text("Options")
            }

            Section {
                HStack {
                    TextField("Key", text: $metadataKey)
                    TextField("Value", text: $metadataValue)
                    Button("Add") {
                        guard !metadataKey.isEmpty else { return }
                        customMetadata[metadataKey] = metadataValue
                        metadataKey = ""
                        metadataValue = ""
                    }
                    .disabled(metadataKey.isEmpty)
                }

                ForEach(Array(customMetadata.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Text(customMetadata[key] ?? "")
                            .foregroundStyle(.secondary)
                        Button(role: .destructive) {
                            customMetadata.removeValue(forKey: key)
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            } header: {
                Text("Custom Metadata")
            }

            Section {
                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .controlSize(.small)
                            Text("Submitting...")
                        } else {
                            Text("Submit via PingKit.submit()")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting || feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || PingKit.apiKey == nil)

                if PingKit.apiKey == nil {
                    Label("Configure PingKit first", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }

            // Results
            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                } header: {
                    Text("Error")
                }
            }

            if let result {
                Section {
                    Text(result)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                } header: {
                    Text("Result")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    @MainActor
    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        result = nil

        do {
            let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let type = type.trimmingCharacters(in: .whitespacesAndNewlines)

            let metadata = customMetadata.isEmpty ? nil : customMetadata

            let feedback = try await PingKit.submit(
                text: feedbackText,
                email: email.isEmpty ? nil : email,
                type: type.isEmpty ? nil : type,
                metadata: metadata,
                includeDeviceInfo: includeDeviceInfo
            )

            result = """
            id: \(feedback.id)
            status: \(feedback.status)
            """
        } catch let error as PingKitError {
            errorMessage = describeError(error)
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }

        isSubmitting = false
    }
}
