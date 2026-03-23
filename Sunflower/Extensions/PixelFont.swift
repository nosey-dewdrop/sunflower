import SwiftUI

extension View {
    func pixelFont(size: CGFloat = 16, bold: Bool = false) -> some View {
        self.font(.system(size: size, weight: bold ? .bold : .regular, design: .rounded))
    }
}
