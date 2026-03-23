import SwiftUI

enum PixelFont {
    static func regular(size: CGFloat) -> Font {
        .custom("PixelifySans-Regular", size: size)
    }

    static func bold(size: CGFloat) -> Font {
        .custom("PixelifySans-Bold", size: size)
    }
}

struct PixelFontModifier: ViewModifier {
    let size: CGFloat
    let bold: Bool

    func body(content: Content) -> some View {
        content.font(bold ? PixelFont.bold(size: size) : PixelFont.regular(size: size))
    }
}

extension View {
    func pixelFont(size: CGFloat = 16, bold: Bool = false) -> some View {
        modifier(PixelFontModifier(size: size, bold: bold))
    }
}
