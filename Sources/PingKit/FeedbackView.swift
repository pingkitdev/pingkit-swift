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

    private let borderColor = Color.primary.opacity(0.15)
    private let errorColor = Color(red: 0.9, green: 0.3, blue: 0.3)
    private let successColor = Color(red: 0.3, green: 0.8, blue: 0.5)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Scrollable content area — type picker + text editor
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Type picker — pill toggle buttons
                        if !typeOptions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("CATEGORY")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .kerning(0.8)

                                HStack(spacing: 8) {
                                    ForEach(typeOptions, id: \.self) { option in
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                selectedType = selectedType == option ? "" : option
                                            }
                                        } label: {
                                            Text(option)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 7)
                                                .background(
                                                    selectedType == option
                                                        ? Color.primary.opacity(0.08)
                                                        : Color.clear
                                                )
                                                .foregroundStyle(
                                                    selectedType == option
                                                        ? Color.primary
                                                        : Color.secondary
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .strokeBorder(
                                                            selectedType == option
                                                                ? Color.primary.opacity(0.3)
                                                                : borderColor,
                                                            lineWidth: 1
                                                        )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Text editor — border-based input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("FEEDBACK")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .kerning(0.8)

                            TextEditor(text: $feedbackText)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 140)
                                .padding(10)
                                .background(Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(borderColor, lineWidth: 1)
                                )
                                .overlay(alignment: .topLeading) {
                                    if feedbackText.isEmpty {
                                        Text("What's on your mind?")
                                            .foregroundStyle(Color.secondary.opacity(0.7))
                                            .padding(.horizontal, 15)
                                            .padding(.vertical, 18)
                                            .allowsHitTesting(false)
                                    }
                                }

                            Text("\(feedbackText.count)/5000")
                                .font(.caption2)
                                .foregroundStyle(Color.secondary.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }

                        // Error banner
                        if let errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundStyle(errorColor)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundStyle(errorColor)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(errorColor.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(errorColor.opacity(0.3), lineWidth: 1)
                            )
                        }

                        // Success banner
                        if showSuccess {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(successColor)
                                Text("Feedback sent! Thank you.")
                                    .font(.caption)
                                    .foregroundStyle(successColor)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(successColor.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(successColor.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }

                // Fixed footer
                VStack(spacing: 0) {
                    divider

                    // Email field
                    if emailMode != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 2) {
                                Text("EMAIL")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .kerning(0.8)
                                if case .required = emailMode {
                                    Text("*")
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                }
                            }

                            TextField("you@example.com", text: $emailText)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .font(.subheadline)
                                .padding(10)
                                .background(Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(borderColor, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                        divider
                    }

                    // Screenshot attachment zone
                    Group {
                        if let imageThumbnail {
                            // Attached state
                            HStack(spacing: 12) {
                                imageThumbnail
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(borderColor, lineWidth: 1)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Screenshot attached")
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    if let size = imageSizeDescription {
                                        Text(size)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Button {
                                    selectedPhoto = nil
                                    imageData = nil
                                    self.imageThumbnail = nil
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 28, height: 28)
                                        .background(Color.primary.opacity(0.06))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        } else {
                            // Empty state — dashed attachment zone
                            PhotosPicker(
                                selection: $selectedPhoto,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                HStack(spacing: 10) {
                                    Image(systemName: "camera")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("Attach screenshot")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Image(systemName: "plus")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(Color.secondary.opacity(0.7))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(
                                            style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                                        )
                                        .foregroundStyle(borderColor)
                                )
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                    }

                    divider

                    // Metadata info line
                    HStack(spacing: 5) {
                        Image(systemName: "shield")
                            .font(.caption2)
                        Text("Device info is automatically attached")
                            .font(.caption2)
                    }
                    .foregroundStyle(Color.secondary.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)

                    divider

                    // Send button — full width
                    Button {
                        Task { await submitFeedback() }
                    } label: {
                        Group {
                            if isSubmitting {
                                ProgressView()
                                    .tint(Color(uiColor: .systemBackground))
                            } else {
                                Text("Send Feedback")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .background(Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.4)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 16)
                }
                .background(theme.backgroundColor)
            }
            .background(theme.backgroundColor)
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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

    // MARK: - UI Components

    private var divider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.1))
            .frame(height: 1)
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
}
