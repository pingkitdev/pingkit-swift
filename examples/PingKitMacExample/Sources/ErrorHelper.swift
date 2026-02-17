import PingKit

func describeError(_ error: PingKitError) -> String {
    switch error {
    case .notConfigured:
        return "PingKit not configured. Call configure() first."
    case .invalidInput(let msg):
        return msg
    case .unauthorized:
        return "Unauthorized — check your API key."
    case .attestRequired:
        return "Device verification required (iOS only)."
    case .imageTooLarge:
        return "Image is too large."
    case .rateLimited(let retryAfter):
        if let retryAfter {
            return "Rate limited. Retry after \(retryAfter)s."
        }
        return "Rate limited. Try again later."
    case .planLimitReached:
        return "Monthly feedback limit reached."
    case .networkError(let err):
        return "Network error: \(err.localizedDescription)"
    case .serverError(let code, let message):
        return "Server error [\(code)]: \(message)"
    }
}
