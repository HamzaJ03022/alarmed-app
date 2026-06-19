import SwiftUI

enum AppColors {
    static let background = Color(hex: "121212")
    static let card = Color(hex: "1E1E24")
    static let text = Color(hex: "FFFFFF")
    static let textSecondary = Color(hex: "B5B5B5")

    static let primary = Color(hex: "4C7DFE")
    static let secondary = Color(hex: "6F5BFF")
    static let success = Color(hex: "4BB543")
    static let warning = Color(hex: "FFCC00")
    static let warningBackground = Color(hex: "FFCC00").opacity(0.1)
    static let error = Color(hex: "FF3B30")

    static let border = Color.white.opacity(0.12)
    static let inactive = Color(hex: "666666")
    static let divider = Color.white.opacity(0.08)
    static let overlay = Color.black.opacity(0.8)

    static let switchTrack = Color.white.opacity(0.1)
    static let cardShadow = Color.black.opacity(0.25)

    static let buttonInactive = Color.white.opacity(0.05)
    static let buttonBorder = Color.white.opacity(0.1)

    static let inputBackground = Color.white.opacity(0.05)
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
