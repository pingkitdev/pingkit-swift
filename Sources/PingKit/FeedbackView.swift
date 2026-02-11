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
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showMetadataInfo = false

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Type picker
                    if !typeOptions.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Picker("Category", selection: $selectedType) {
                                Text("Select...").tag("")
                                ForEach(typeOptions, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    // Text field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Feedback")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $feedbackText)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(alignment: .topLeading) {
                                if feedbackText.isEmpty {
                                    Text("What's on your mind?")
                                        .foregroundStyle(.tertiary)
                                        .padding(.horizontal, 13)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                }
                            }

                        Text("\(feedbackText.count)/5000")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    // Email field
                    if emailMode != nil {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Email")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if case .required = emailMode {
                                    Text("Required")
                                        .font(.caption2)
                                        .foregroundStyle(theme.accentColor)
                                }
                            }

                            TextField("Email", text: $emailText)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .padding(12)
                                .background(Color(uiColor: .secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }

                    // Screenshot
                    VStack(alignment: .leading, spacing: 8) {
                        if let imageThumbnail {
                            HStack {
                                imageThumbnail
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                Button(role: .destructive) {
                                    selectedPhoto = nil
                                    imageData = nil
                                    self.imageThumbnail = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
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
                            .font(.subheadline)
                        }
                    }

                    // Metadata info
                    Button {
                        withAnimation { showMetadataInfo.toggle() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                            Text("Device info will be attached")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    if showMetadataInfo {
                        VStack(alignment: .leading, spacing: 4) {
                            metadataRow("Device", value: "model & OS version")
                            metadataRow("App", value: "version & build number")
                            metadataRow("Locale", value: "language & region")
                            metadataRow("Timezone", value: "current timezone")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .background(Color(uiColor: .tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Error message
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Success message
                    if showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Feedback sent! Thank you.")
                                .font(.subheadline)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            }
            .background(theme.backgroundColor)
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await submitFeedback() }
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Send")
                                .bold()
                        }
                    }
                    .disabled(!canSubmit)
                    .tint(theme.accentColor)
                }
            }
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
                metadata: customMetadata
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
                print("[PingKit] Warning: Invalid API key")
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

    // MARK: - Helpers

    private func metadataRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
            Spacer()
            Text(value)
        }
    }
}
