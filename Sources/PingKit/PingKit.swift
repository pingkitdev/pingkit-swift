import SwiftUI

/// PingKit — Lightweight in-app feedback SDK for iOS.
///
/// Usage:
/// ```swift
/// // 1. Configure (once, at app launch)
/// PingKit.configure(apiKey: "pk_proj_xxxxxxxxxxxx")
///
/// // 2. Show feedback modal
/// PingKit.show()
/// ```
public enum PingKit {
    public internal(set) static var apiKey: String?
    public internal(set) static var options = PingKitOptions()
    public internal(set) static var theme = PingKitTheme()
    private static let attestManager = AppAttestManager()

    // MARK: - Configure

    /// Configure PingKit with your API key. Call once at app launch.
    public static func configure(
        apiKey: String,
        options: PingKitOptions = PingKitOptions(),
        theme: PingKitTheme = PingKitTheme()
    ) {
        self.apiKey = apiKey
        self.options = options
        self.theme = theme

        // Prepare App Attest in background
        if options.enableAppAttest {
            Task {
                try? await attestManager.prepare()
            }
        }
    }

    // MARK: - Show (Tier 1 & 2)

    /// Present the feedback modal from the topmost view controller.
    ///
    /// - Parameters:
    ///   - email: Email field configuration. Default: hidden.
    ///   - type: Type picker configuration. Default: hidden.
    ///   - metadata: Custom key-value pairs attached to the submission.
    @MainActor
    public static func show(
        email: EmailMode? = nil,
        type: TypeMode? = nil,
        metadata: [String: String]? = nil
    ) {
        guard apiKey != nil else {
            print("[PingKit] Warning: PingKit.show() called before configure(). Ignoring.")
            return
        }

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController?.topMostViewController()
        else {
            print("[PingKit] Warning: Could not find a view controller to present from.")
            return
        }

        let feedbackView = FeedbackView(
            emailMode: email,
            typeMode: type,
            customMetadata: metadata
        )

        let hostingController = UIHostingController(rootView: feedbackView)
        hostingController.modalPresentationStyle = .pageSheet

        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersEdgeAttachedInCompactHeight = true
        }

        rootVC.present(hostingController, animated: true)
    }

    // MARK: - Submit (Tier 3 — Headless)

    /// Submit feedback programmatically without showing the modal.
    ///
    /// - Parameters:
    ///   - text: Feedback text (required, max 5000 characters).
    ///   - image: Optional screenshot data (JPEG/PNG, max 5MB).
    ///   - email: Optional user email.
    ///   - type: Optional feedback type/category.
    ///   - metadata: Custom key-value pairs.
    /// - Returns: The created feedback result with server-assigned ID.
    @MainActor
    @discardableResult
    public static func submit(
        text: String,
        image: Data? = nil,
        email: String? = nil,
        type: String? = nil,
        metadata: [String: String]? = nil,
        includeDeviceInfo: Bool = true
    ) async throws -> FeedbackResult {
        guard let apiKey else {
            throw PingKitError.notConfigured
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw PingKitError.invalidInput("Feedback text cannot be empty")
        }
        guard trimmedText.count <= 5000 else {
            throw PingKitError.invalidInput("Feedback text exceeds 5000 character limit")
        }

        // Collect device metadata
        let deviceMetadata: DeviceMetadata? = includeDeviceInfo ? MetadataCollector.collect() : nil

        // Build custom metadata with reserved keys
        var custom = metadata ?? [:]
        if let email { custom["_email"] = email }
        if let type { custom["_type"] = type }

        // Compress image if needed
        var imageData = image
        if let data = imageData, Double(data.count) > options.maxImageSizeMB * 1_048_576 {
            imageData = compressImage(data, targetSizeMB: options.maxImageSizeMB)
        }

        // Generate App Attest assertion
        var attestAssertion: String?
        var attestKeyId: String?
        if options.enableAppAttest {
            do {
                if let result = try await attestManager.generateAssertion(for: Data(trimmedText.utf8)) {
                    attestAssertion = result.assertion
                    attestKeyId = result.keyId
                }
            } catch {
                print("[PingKit] App Attest assertion failed: \(error.localizedDescription)")
            }
        }

        return try await APIClient.submitFeedback(
            text: trimmedText,
            imageData: imageData,
            metadata: deviceMetadata,
            customMetadata: custom.isEmpty ? nil : custom,
            endpoint: options.endpoint,
            apiKey: apiKey,
            attestAssertion: attestAssertion,
            attestKeyId: attestKeyId
        )
    }

    // MARK: - Image Compression

    private static func compressImage(_ data: Data, targetSizeMB: Double) -> Data? {
        guard let image = UIImage(data: data) else { return data }
        let targetBytes = Int(targetSizeMB * 1_048_576)
        var quality: CGFloat = 0.7
        var compressed = image.jpegData(compressionQuality: quality)
        while let c = compressed, c.count > targetBytes, quality > 0.1 {
            quality -= 0.1
            compressed = image.jpegData(compressionQuality: quality)
        }
        return compressed
    }
}

// MARK: - UIViewController extension

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }
        if let nav = self as? UINavigationController, let visible = nav.visibleViewController {
            return visible.topMostViewController()
        }
        if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
            return selected.topMostViewController()
        }
        return self
    }
}
