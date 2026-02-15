import Foundation

/// Configuration options for PingKit.
public struct PingKitOptions: Sendable {
    /// API endpoint URL. Defaults to PingKit's hosted service.
    public let endpoint: String

    /// Whether to use Apple App Attest for device verification.
    public let enableAppAttest: Bool

    /// Maximum image size in megabytes before JPEG compression is applied.
    public let maxImageSizeMB: Double

    /// Print debug info to the console.
    public let verbose: Bool

    public init(
        endpoint: String = "https://pingkit.dev",
        enableAppAttest: Bool = true,
        maxImageSizeMB: Double = 5,
        verbose: Bool = false
    ) {
        self.endpoint = endpoint
        self.enableAppAttest = enableAppAttest
        self.maxImageSizeMB = maxImageSizeMB
        self.verbose = verbose
    }
}
