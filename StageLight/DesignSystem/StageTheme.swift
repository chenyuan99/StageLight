import SwiftUI
import UIKit

enum StageTheme {
    static let background = Color(
        light: UIColor(red: 247 / 255, green: 247 / 255, blue: 245 / 255, alpha: 1),
        dark: UIColor(red: 9 / 255, green: 9 / 255, blue: 9 / 255, alpha: 1)
    )
    static let surface = Color(
        light: .white,
        dark: UIColor(red: 21 / 255, green: 21 / 255, blue: 21 / 255, alpha: 1)
    )
    static let secondary = Color(
        light: UIColor(red: 119 / 255, green: 119 / 255, blue: 119 / 255, alpha: 1),
        dark: UIColor(red: 146 / 255, green: 146 / 255, blue: 146 / 255, alpha: 1)
    )
    static let spotlight = Color(
        light: UIColor(red: 0.96, green: 0.91, blue: 0.77, alpha: 1),
        dark: UIColor(red: 0.95, green: 0.90, blue: 0.75, alpha: 1)
    )
}

private extension Color {
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

struct StagePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .foregroundStyle(.background)
            .background(.primary.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
