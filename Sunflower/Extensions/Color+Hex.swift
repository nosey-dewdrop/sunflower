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

    // App color palette
    static let bgDark = Color(hex: "1A2E1A")       // dark background
    static let grassGreen = Color(hex: "4A7C59")    // timer background, highlights
    static let darkGreen = Color(hex: "2D5A3D")     // button bg, subtle
    static let lightGreen = Color(hex: "6B9B7A")    // secondary text/accent
    static let warmYellow = Color(hex: "F4D35E")    // primary accent (sunflower)
    static let cream = Color(hex: "FAF0CA")          // light text alternative
    static let amber = Color(hex: "E8A838")          // warm accent (banner, current time)
    static let brown = Color(hex: "8B6914")
    static let cardBg = Color.white.opacity(0.08)   // card backgrounds
}
