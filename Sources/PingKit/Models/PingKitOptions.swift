import Foundation

/// Configuration options for PingKit.
public struct PingKitOptions: Sendable {
    /// API endpoint URL. Defaults to PingKit's hosted service.
    public let endpoint: String

    /// Whether to use Apple App Attest for device verification.
    public let enableAppAttest: Bool

    /// Maximum image size in megabytes before JPEG compression is applied.
    public let maxImageSizeMB: Double

    public init(
        endpoint: String = "https://app.pingkit.dev",
        enableAppAttest: Bool = true,
        maxImageSizeMB: Double = 5
    ) {
        self.endpoint = endpoint
        self.enableAppAttest = enableAppAttest
        self.maxImageSizeMB = maxImageSizeMB
    }
}
