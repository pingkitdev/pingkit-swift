import Foundation

/// Controls the feedback type picker in the modal.
public enum TypeMode: Sendable {
    /// Show a picker with the given labels (e.g. ["Bug", "Feature", "Other"]).
    case picker([String])
}
