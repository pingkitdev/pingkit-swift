import SwiftUI
import PhotosUI

struct FeedbackView: View {
    let emailMode: EmailMode?
    let typeMode: TypeMode?
    let customMetadata: [String: String]?

    @Environment(\.dismiss) private var dismiss

    @State private var feedbackText = ""
    @State private var emailText = ""
    @State private var selectedType = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var imageThumbnail: Image?
    @State private var includeDeviceInfo = true
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    private var theme: PingKitTheme { PingKit.theme }

    private var typeOptions: [String] {
        if case .picker(let options) = typeMode { return options }
        return []
    }

    private var canSubmit: Bool {
        let textValid = !feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let emailValid: Bool
        if case .required = emailMode {
            emailValid = !emailText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            emailValid = true
        }
        return textValid && emailValid && !isSubmitting
    }

    @MainActor
    private var deviceMetadata: DeviceMetadata {
        MetadataCollector.collect()
    }

    private var imageSizeDescription: String? {
        guard let imageData else { return nil }
        let bytes = imageData.count
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return "\(bytes / 1024) KB"
        } else {
            let mb = Double(bytes) / (1024 * 1024)
            return String(format: "%.1f MB", mb)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Type picker
                if !typeOptions.isEmpty {
                    Section {
                        Picker("Category", selection: $selectedType) {
                            Text("None").tag("")
                            ForEach(typeOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                    }
                    .cardBackground(theme.cardColor)
                }

                // Feedback text
                Section {
                    ZStack(alignment: .topLeading) {
                        if feedbackText.isEmpty {
                            Text("What's on your mind?")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                        }
                        TextEditor(text: $feedbackText)
                            .frame(minHeight: 150)
                    }
                } header: {
                    Text("Feedback")
                } footer: {
                    Text("\(feedbackText.count)/5000")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .cardBackground(theme.cardColor)

                // Email
                if emailMode != nil {
                    Section {
                        TextField("you@example.com", text: $emailText)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } header: {
                        HStack(spacing: 2) {
                            Text("Email")
                            if case .required = emailMode {
                                Text("(required)")
                            } else if case .optional = emailMode {
                                Text("(optional)")
                            }
                        }
                    }
                    .cardBackground(theme.cardColor)
                }

                // Screenshot
                Section {
                    if let imageThumbnail {
                        HStack(spacing: 12) {
                            imageThumbnail
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Screenshot")
                                    .font(.body)
                                if let size = imageSizeDescription {
                                    Text(size)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Button(role: .destructive) {
                                selectedPhoto = nil
                                imageData = nil
                                self.imageThumbnail = nil
                            } label: {
                                Image(systemName: "trash")
                                    .font(.body)
                            }
                        }
                    }

                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label(
                            imageData == nil ? "Attach Screenshot" : "Change Screenshot",
                            systemImage: "photo"
                        )
                    }
                }
                .cardBackground(theme.cardColor)

                // Error
                if let errorMessage {
                    Section {
                        Label {
                            Text(errorMessage)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                    .cardBackground(theme.cardColor)
                }

                // Success
                if showSuccess {
                    Section {
                        Label {
                            Text("Feedback sent! Thank you.")
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .cardBackground(theme.cardColor)
                }

                // Device info
                Section {
                    Toggle("Include Device Info", isOn: $includeDeviceInfo)

                    if includeDeviceInfo {
                        DisclosureGroup("Data collected") {
                            DeviceInfoRow(label: "Device", value: deviceMetadata.deviceModel)
                            DeviceInfoRow(label: "OS", value: "iOS \(deviceMetadata.osVersion)")
                            DeviceInfoRow(label: "App Version", value: "\(deviceMetadata.appVersion) (\(deviceMetadata.appBuild))")
                            DeviceInfoRow(label: "Locale", value: deviceMetadata.locale)
                            DeviceInfoRow(label: "Timezone", value: deviceMetadata.timezone)
                        }
                        .font(.subheadline)
                    }
                } footer: {
                    Text("Helps developers diagnose issues on your device.")
                }
                .cardBackground(theme.cardColor)

                // Submit
                Section {
                    Button {
                        Task { await submitFeedback() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Text("Submit")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!canSubmit)
                }
                .cardBackground(theme.cardColor)
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.backgroundColor)
            .tint(theme.accentColor)
            .font(theme.font)
            .onChange(of: selectedPhoto) { newValue in
                Task { await loadImage(from: newValue) }
            }
            .onAppear {
                if case .prefilled(let email) = emailMode {
                    emailText = email
                }
            }
        }
    }

    // MARK: - Actions

    @MainActor
    private func submitFeedback() async {
        isSubmitting = true
        errorMessage = nil

        do {
            let email = emailText.trimmingCharacters(in: .whitespacesAndNewlines)
            let type = selectedType.isEmpty ? nil : selectedType

            try await PingKit.submit(
                text: feedbackText,
                image: imageData,
                email: email.isEmpty ? nil : email,
                type: type,
                metadata: customMetadata,
                includeDeviceInfo: includeDeviceInfo
            )

            showSuccess = true
            try? await Task.sleep(for: .seconds(1.5))
            dismiss()
        } catch let error as PingKitError {
            switch error {
            case .rateLimited:
                errorMessage = "Too many submissions. Please try again later."
            case .planLimitReached:
                errorMessage = "Feedback limit reached. Please try again later."
            case .unauthorized:
                errorMessage = "Unable to send feedback. Please try again."
                if PingKit.options.verbose { print("[PingKit] Warning: Invalid API key") }
            case .invalidInput(let msg):
                errorMessage = msg
            case .imageTooLarge:
                errorMessage = "Image is too large. Please choose a smaller image."
            case .networkError:
                errorMessage = "Network error. Please check your connection and try again."
            case .serverError(_, let message):
                errorMessage = message
            case .notConfigured:
                errorMessage = "Feedback is temporarily unavailable."
            case .attestRequired:
                errorMessage = "Device verification required."
            }
        } catch {
            errorMessage = "Something went wrong. Please try again."
            if PingKit.options.verbose { print("[PingKit] Unexpected error: \(error)") }
        }

        isSubmitting = false
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        imageData = data
        if let uiImage = UIImage(data: data) {
            imageThumbnail = Image(uiImage: uiImage)
        }
    }
}

// MARK: - Conditional List Row Background

private extension View {
    @ViewBuilder
    func cardBackground(_ color: Color?) -> some View {
        if let color {
            self.listRowBackground(color)
        } else {
            self
        }
    }
}

// MARK: - Device Info Row

private struct DeviceInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(.primary)
        }
    }
}
