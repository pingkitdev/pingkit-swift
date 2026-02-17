import SwiftUI
import PingKit

struct ModalTab: View {
    @State private var showFeedback = false
    @State private var emailMode: EmailModeOption = .optional
    @State private var enableTypePicker = true
    @State private var customTypes = "Bug, Feature, Other"

    var body: some View {
        Form {
            Section {
                Picker("Email Field", selection: $emailMode) {
                    ForEach(EmailModeOption.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                Toggle("Show Type Picker", isOn: $enableTypePicker)

                if enableTypePicker {
                    TextField("Types (comma-separated)", text: $customTypes)
                }
            } header: {
                Text("Modal Options")
            }

            Section {
                Button("Show Feedback Modal") {
                    showFeedback = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(PingKit.apiKey == nil)

                if PingKit.apiKey == nil {
                    Label("Configure PingKit first", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }

            Section {
                Button("Show via PingKit.show()") {
                    let email = emailMode.toPingKit()
                    let type: TypeMode? = enableTypePicker
                        ? .picker(customTypes.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
                        : nil

                    PingKit.show(
                        email: email,
                        type: type,
                        metadata: ["source": "mac-example"]
                    )
                }
                .buttonStyle(.bordered)
                .disabled(PingKit.apiKey == nil)
            } header: {
                Text("Direct API (shows feedback sheet)")
            }
        }
        .formStyle(.grouped)
        .padding()
        .sheet(isPresented: $showFeedback) {
            FeedbackSheetView(
                emailMode: emailMode,
                enableTypePicker: enableTypePicker,
                customTypes: customTypes
            )
        }
    }
}

// MARK: - Email Mode Picker

enum EmailModeOption: String, CaseIterable, Identifiable {
    case hidden = "Hidden"
    case optional = "Optional"
    case required = "Required"
    case prefilled = "Prefilled"

    var id: String { rawValue }

    func toPingKit() -> EmailMode? {
        switch self {
        case .hidden: return nil
        case .optional: return .optional
        case .required: return .required
        case .prefilled: return .prefilled("user@example.com")
        }
    }
}

// MARK: - Feedback Sheet

struct FeedbackSheetView: View {
    let emailMode: EmailModeOption
    let enableTypePicker: Bool
    let customTypes: String

    @Environment(\.dismiss) private var dismiss
    @State private var feedbackText = ""
    @State private var emailText = ""
    @State private var selectedType = ""
    @State private var isSubmitting = false
    @State private var result: String?
    @State private var errorMessage: String?

    private var typeOptions: [String] {
        guard enableTypePicker else { return [] }
        return customTypes.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Text("Send Feedback")
                    .font(.headline)
                Spacer()
                Button("Submit") {
                    Task { await submit() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            }
            .padding()

            Divider()

            // Body
            Form {
                if !typeOptions.isEmpty {
                    Picker("Category", selection: $selectedType) {
                        Text("None").tag("")
                        ForEach(typeOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }

                Section("Feedback") {
                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 120)
                    Text("\(feedbackText.count)/5000")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                if emailMode != .hidden {
                    Section {
                        TextField("you@example.com", text: $emailText)
                            .autocorrectionDisabled()
                    } header: {
                        HStack(spacing: 2) {
                            Text("Email")
                            if emailMode == .required {
                                Text("(required)")
                            } else {
                                Text("(optional)")
                            }
                        }
                    }
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }

                if let result {
                    Label(result, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 480, height: 500)
        .onAppear {
            if emailMode == .prefilled {
                emailText = "user@example.com"
            }
        }
    }

    @MainActor
    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        result = nil

        do {
            let email = emailText.trimmingCharacters(in: .whitespacesAndNewlines)
            let type = selectedType.isEmpty ? nil : selectedType

            let feedback = try await PingKit.submit(
                text: feedbackText,
                email: email.isEmpty ? nil : email,
                type: type,
                metadata: ["source": "mac-example-sheet"]
            )

            result = "Sent! ID: \(feedback.id)"
            try? await Task.sleep(for: .seconds(1.5))
            dismiss()
        } catch let error as PingKitError {
            errorMessage = describeError(error)
        } catch {
            errorMessage = "Something went wrong."
        }

        isSubmitting = false
    }
}
