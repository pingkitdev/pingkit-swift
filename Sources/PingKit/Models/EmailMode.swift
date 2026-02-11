import Foundation

/// Controls the email field behavior in the feedback modal.
public enum EmailMode: Sendable {
    /// Show email field but don't require it.
    case optional

    /// Show email field and require it to submit.
    case required

    /// Pre-fill the email field with a value. User can edit it.
    case prefilled(String)
}
