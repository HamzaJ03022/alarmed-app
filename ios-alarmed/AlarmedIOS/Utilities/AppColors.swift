import SwiftUI

/// Colour tokens for the Alarmed design system. Every screen reads colour
/// from here — near-black canvas, charcoal surfaces, one restrained blue
/// accent, and three readable text steps.
enum AppColors {
    // MARK: Surfaces
    /// Near-black canvas behind every screen.
    static let background = Color(hex: "0A0A0C")
    /// Deep charcoal for cards and grouped sections.
    static let card = Color(hex: "161619")
    /// Slightly lighter charcoal for inputs, tiles and selected rows.
    static let surfaceElevated = Color(hex: "202024")
    /// Row highlight while a finger is down.
    static let surfacePressed = Color(hex: "29292E")

    // MARK: Text
    static let text = Color(hex: "FFFFFF")
    /// Secondary text — 7:1 on the card surface.
    static let textSecondary = Color(hex: "A3A3AB")
    /// Disabled alarms and placeholder copy — still ≥4.5:1 on the card surface.
    static let inactive = Color(hex: "7E7E87")

    // MARK: Accent & status
    /// The single accent: primary actions, selected states, enabled toggles.
    static let primary = Color(hex: "4F83FF")
    static let primarySoft = Color(hex: "4F83FF").opacity(0.16)
    static let secondary = Color(hex: "6F5BFF")
    static let success = Color(hex: "34C77B")
    static let warning = Color(hex: "FFB020")
    static let warningBackground = Color(hex: "FFB020").opacity(0.12)
    static let error = Color(hex: "FF453A")

    // MARK: Lines & overlays
    static let border = Color.white.opacity(0.10)
    static let divider = Color.white.opacity(0.07)
    static let overlay = Color.black.opacity(0.8)

    static let switchTrack = Color.white.opacity(0.1)
    /// Shadows are retired in the redesign; kept transparent for any legacy use.
    static let cardShadow = Color.clear

    static let buttonInactive = Color(hex: "202024")
    static let buttonBorder = Color.white.opacity(0.1)

    static let inputBackground = Color(hex: "202024")
    static let inputBorder = Color.white.opacity(0.1)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
