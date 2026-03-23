import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
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

    // App color palette — matched to grass tile (dark tone)
    static let grassGreen = Color(hex: "6B8F3C")
    static let darkGreen = Color(hex: "4A6B28")
    static let lightGreen = Color(hex: "8BAF5A")
    static let warmYellow = Color(hex: "F4D35E")
    static let cream = Color(hex: "FFFDF5")
    static let brown = Color(hex: "8B6914")
    static let cardBg = Color.white.opacity(0.15)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
}
