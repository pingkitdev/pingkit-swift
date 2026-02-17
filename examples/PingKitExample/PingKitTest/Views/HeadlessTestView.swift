import SwiftUI
import PhotosUI
import PingKit

struct HeadlessTestView: View {
    @State private var feedbackText = ""
    @State private var email = ""
    @State private var feedbackType = "bug"
    @State private var metadataScreen = "editor"
    @State private var includeDeviceInfo = true
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var imageThumbnail: Image?
    @State private var isSubmitting = false
    @State private var resultMessage = ""
    @State private var resultIsError = false
    @AppStorage("apiKey") private var apiKey = ""

    let feedbackTypes = ["bug", "feature", "question", "other"]

    var body: some View {
        Form {
            Section("Feedback") {
                TextEditor(text: $feedbackText)
                    .frame(minHeight: 100)
            }

            Section("Options") {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)

                Picker("Type", selection: $feedbackType) {
                    ForEach(feedbackTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }

                LabeledContent("Metadata (screen)") {
                    TextField("screen name", text: $metadataScreen)
                }

                Toggle("Include Device Info", isOn: $includeDeviceInfo)
            }

            Section("Screenshot") {
                if let imageThumbnail {
                    HStack(spacing: 12) {
                        imageThumbnail
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Spacer()

                        Button(role: .destructive) {
                            self.imageData = nil
                            self.imageThumbnail = nil
                            self.selectedPhoto = nil
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label(
                        imageData == nil ? "Attach Screenshot" : "Change Screenshot",
                        systemImage: "photo"
                    )
                }
            }

            Section {
                Button {
                    submit()
                } label: {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView()
                                .padding(.trailing, 4)
                        }
                        Text(isSubmitting ? "Submitting..." : "Submit")
                            .font(.headline)
                        Spacer()
                    }
                }
                .disabled(feedbackText.isEmpty || isSubmitting || apiKey.isEmpty)
            }

            if !resultMessage.isEmpty {
                Section("Result") {
                    Label(resultMessage, systemImage: resultIsError ? "xmark.circle" : "checkmark.circle")
                        .foregroundStyle(resultIsError ? .red : .green)
                }
            }

            Section("Error Tests") {
                Button("Bad API Key") {
                    testUnauthorized()
                }
                .foregroundStyle(.orange)

                Button("Rapid-Fire (10x)") {
                    testRateLimit()
                }
                .foregroundStyle(.orange)
            }

            if apiKey.isEmpty {
                Section {
                    Label("Configure an API key in Setup first", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("Headless")
        .onChange(of: selectedPhoto) { _ in
            loadImage()
        }
    }

    // MARK: - Submit

    private func submit() {
        isSubmitting = true
        resultMessage = ""
        Task {
            do {
                let result = try await PingKit.submit(
                    text: feedbackText,
                    image: imageData,
                    email: email.isEmpty ? nil : email,
                    type: feedbackType,
                    metadata: ["screen": metadataScreen],
                    includeDeviceInfo: includeDeviceInfo
                )
                resultMessage = "Submitted! ID: \(result.id)"
                resultIsError = false
                feedbackText = ""
            } catch PingKitError.rateLimited(retryAfter: let retryAfter) {
                resultMessage = "Rate limited. Retry after \(retryAfter ?? 0)s"
                resultIsError = true
            } catch PingKitError.unauthorized {
                resultMessage = "Unauthorized — check API key"
                resultIsError = true
            } catch PingKitError.planLimitReached {
                resultMessage = "Plan limit reached — upgrade plan"
                resultIsError = true
            } catch {
                resultMessage = "Error: \(error.localizedDescription)"
                resultIsError = true
            }
            isSubmitting = false
        }
    }

    // MARK: - Image Loading

    private func loadImage() {
        guard let selectedPhoto else { return }
        Task {
            if let data = try? await selectedPhoto.loadTransferable(type: Data.self) {
                imageData = data
                if let uiImage = UIImage(data: data) {
                    imageThumbnail = Image(uiImage: uiImage)
                }
            }
        }
    }

    // MARK: - Error Tests

    private func testUnauthorized() {
        isSubmitting = true
        resultMessage = ""
        let savedKey = apiKey
        PingKit.configure(apiKey: "pk_proj_INVALID_KEY_12345")
        Task {
            do {
                _ = try await PingKit.submit(text: "Testing unauthorized error")
                resultMessage = "Unexpectedly succeeded"
                resultIsError = false
            } catch PingKitError.unauthorized {
                resultMessage = "Caught PingKitError.unauthorized"
                resultIsError = true
            } catch {
                resultMessage = "Caught: \(error)"
                resultIsError = true
            }
            if !savedKey.isEmpty {
                PingKit.configure(apiKey: savedKey)
            }
            isSubmitting = false
        }
    }

    private func testRateLimit() {
        isSubmitting = true
        resultMessage = ""
        Task {
            var hitRateLimit = false
            for i in 1...10 {
                do {
                    _ = try await PingKit.submit(text: "Rate limit test \(i)")
                } catch PingKitError.rateLimited(retryAfter: let retryAfter) {
                    resultMessage = "Rate limited on request #\(i) — retry after \(retryAfter ?? 0)s"
                    resultIsError = true
                    hitRateLimit = true
                    break
                } catch {
                    resultMessage = "Error on request #\(i): \(error)"
                    resultIsError = true
                    break
                }
            }
            if !hitRateLimit && resultMessage.isEmpty {
                resultMessage = "All 10 requests succeeded (no rate limit hit)"
                resultIsError = false
            }
            isSubmitting = false
        }
    }
}

#Preview {
    NavigationStack {
        HeadlessTestView()
    }
}
