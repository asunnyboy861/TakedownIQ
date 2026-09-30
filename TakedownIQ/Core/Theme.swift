import SwiftUI

extension Color {
    static let matBG = Color(red: 0.043, green: 0.051, blue: 0.047)
    static let matSurface = Color(red: 0.082, green: 0.098, blue: 0.094)
    static let volt = Color(red: 0.784, green: 1.0, blue: 0.18)
    static let matDanger = Color(red: 1.0, green: 0.302, blue: 0.239)
    static let matChance = Color(red: 1.0, green: 0.773, blue: 0.239)
    static let matSuccess = Color(red: 0.239, green: 0.863, blue: 0.518)
}

struct MatCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.matSurface, in: RoundedRectangle(cornerRadius: 20))
    }
}

extension View {
    func matCard() -> some View { modifier(MatCard()) }
}

struct VoltButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.title2, design: .default, weight: .heavy).uppercaseSmallCaps())
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Color.volt, in: RoundedRectangle(cornerRadius: 20))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct KindBadge: View {
    let kind: EventKind

    var body: some View {
        Text(label)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.2), in: Capsule())
            .foregroundStyle(color)
            .accessibilityLabel(label)
    }

    private var color: Color {
        switch kind {
        case .good: .matSuccess
        case .mistake: .matDanger
        case .chance: .matChance
        }
    }

    private var label: String {
        switch kind {
        case .good: "GOOD"
        case .mistake: "MISTAKE"
        case .chance: "CHANCE"
        }
    }
}
