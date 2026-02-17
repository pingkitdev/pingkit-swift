import Foundation

func userMessage(for error: PingKitError) -> String {
    switch error {
    case .rateLimited:
        return "Too many submissions. Please try again later."
    case .planLimitReached:
        return "Feedback limit reached. Please try again later."
    case .unauthorized:
        return "Unable to send feedback. Please try again."
    case .invalidInput(let msg):
        return msg
    case .imageTooLarge:
        return "Image is too large. Please choose a smaller image."
    case .networkError:
        return "Network error. Please check your connection and try again."
    case .serverError(_, let message):
        return message
    case .notConfigured:
        return "Feedback is temporarily unavailable."
    case .attestRequired:
        return "Device verification required."
    }
}
