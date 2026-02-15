import SwiftUI

/// Visual theme for the feedback modal.
public struct PingKitTheme: Sendable {
    /// Accent color for buttons and interactive elements.
    public let accentColor: Color

    /// Background color of the feedback modal.
    public let backgroundColor: Color

    /// Background color for form section cards. When nil, uses iOS default.
    public let cardColor: Color?

    /// Corner radius of the modal sheet.
    public let cornerRadius: CGFloat

    /// Font used throughout the modal.
    public let font: Font

    public init(
        accentColor: Color = .accentColor,
        backgroundColor: Color = Color(uiColor: .systemBackground),
        cardColor: Color? = nil,
        cornerRadius: CGFloat = 20,
        font: Font = .body
    ) {
        self.accentColor = accentColor
        self.backgroundColor = backgroundColor
        self.cardColor = cardColor
        self.cornerRadius = cornerRadius
        self.font = font
    }
}
