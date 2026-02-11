import Foundation

/// Result returned after successful feedback submission.
public struct FeedbackResult: Sendable {
    /// Server-assigned feedback ID (e.g. "fb_abc123def456").
    public let id: String

    /// Initial status, always "new".
    public let status: String
}

/// Errors that can occur during feedback submission.
public enum PingKitError: Error, Sendable {
    /// SDK has not been configured. Call PingKit.configure() first.
    case notConfigured

    /// The feedback text is empty or exceeds the maximum length.
    case invalidInput(String)

    /// The API key is invalid or missing.
    case unauthorized

    /// App Attest is required but unavailable.
    case attestRequired

    /// The image exceeds the maximum allowed size.
    case imageTooLarge

    /// Rate limit exceeded. Try again later.
    case rateLimited(retryAfter: Int?)

    /// Monthly feedback quota exceeded.
    case planLimitReached

    /// A network error occurred.
    case networkError(Error)

    /// The server returned an unexpected error.
    case serverError(code: String, message: String)
}
