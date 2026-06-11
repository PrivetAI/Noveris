import SwiftUI

// MARK: - Visual identity: sci-fi command console
enum Brand {
    // Deep space backgrounds
    static let space = Color(red: 0.03, green: 0.04, blue: 0.09)        // near-black indigo
    static let panel = Color(red: 0.07, green: 0.09, blue: 0.16)        // console panel
    static let panelHi = Color(red: 0.11, green: 0.14, blue: 0.23)      // raised panel
    static let stroke = Color(red: 0.20, green: 0.28, blue: 0.42)       // hairline

    // Signal palette
    static let cyan = Color(red: 0.30, green: 0.80, blue: 0.95)         // console cyan
    static let teal = Color(red: 0.25, green: 0.92, blue: 0.78)         // holographic teal
    static let amber = Color(red: 0.98, green: 0.72, blue: 0.25)        // signal amber
    static let green = Color(red: 0.40, green: 0.92, blue: 0.50)        // signal green
    static let red = Color(red: 0.98, green: 0.38, blue: 0.40)          // signal red
    static let violet = Color(red: 0.62, green: 0.52, blue: 0.98)       // research violet

    // Text
    static let text = Color(red: 0.86, green: 0.91, blue: 0.98)
    static let textDim = Color(red: 0.58, green: 0.66, blue: 0.80)
    static let textFaint = Color(red: 0.38, green: 0.45, blue: 0.60)

    static func background() -> some View {
        ZStack {
            Brand.space.ignoresSafeArea()
            // subtle scanline accent
            GeometryReader { geo in
                Path { p in
                    let step: CGFloat = 4
                    var y: CGFloat = 0
                    while y < geo.size.height {
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: geo.size.width, y: y))
                        y += step
                    }
                }
                .stroke(Color.white.opacity(0.012), lineWidth: 0.5)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Fonts (tabular digits)
extension Font {
    static func console(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Number formatting K/M/B/T
enum Fmt {
    static func compact(_ value: Double) -> String {
        let v = value
        let neg = v < 0
        let a = abs(v)
        func trim(_ x: Double) -> String {
            if x >= 100 { return String(format: "%.0f", x) }
            if x >= 10 { return String(format: "%.1f", x) }
            return String(format: "%.2f", x)
        }
        var s: String
        if a < 1000 {
            if a == a.rounded() { s = String(format: "%.0f", a) }
            else if a >= 100 { s = String(format: "%.0f", a) }
            else if a >= 10 { s = String(format: "%.1f", a) }
            else { s = String(format: "%.2f", a) }
        } else if a < 1_000_000 {
            s = trim(a / 1_000) + "K"
        } else if a < 1_000_000_000 {
            s = trim(a / 1_000_000) + "M"
        } else if a < 1_000_000_000_000 {
            s = trim(a / 1_000_000_000) + "B"
        } else {
            s = trim(a / 1_000_000_000_000) + "T"
        }
        return neg ? "-" + s : s
    }

    static func int(_ value: Int) -> String { compact(Double(value)) }

    static func signed(_ value: Double) -> String {
        (value >= 0 ? "+" : "") + compact(value)
    }
}

// MARK: - Reusable console card
struct ConsoleCard<Content: View>: View {
    var accent: Color = Brand.cyan
    let content: Content
    init(accent: Color = Brand.cyan, @ViewBuilder content: () -> Content) {
        self.accent = accent
        self.content = content()
    }
    var body: some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Brand.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Brand.stroke, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(accent.opacity(0.25), lineWidth: 1)
                    .blur(radius: 0.5)
            )
    }
}

// MARK: - Section header
struct SectionHeader: View {
    let title: String
    var accent: Color = Brand.cyan
    var body: some View {
        HStack(spacing: 8) {
            Rectangle().fill(accent).frame(width: 3, height: 14)
            Text(title.uppercased())
                .font(.console(13, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Brand.text)
            Spacer()
        }
    }
}

// MARK: - Primary button style
struct ConsoleButton: ButtonStyle {
    var accent: Color = Brand.cyan
    var filled: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.console(15, weight: .bold))
            .foregroundColor(filled ? Brand.space : accent)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(filled ? accent : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(accent, lineWidth: filled ? 0 : 1.4)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Adaptive width clamp (iPad Guideline 4.0 crop fix)
struct ClampedWidth: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { geo in
            let w = min(geo.size.width, UIScreen.main.bounds.width)
            HStack {
                Spacer(minLength: 0)
                content.frame(width: min(w, 640))
                Spacer(minLength: 0)
            }
            .frame(width: geo.size.width)
        }
    }
}
extension View {
    func clampedWidth() -> some View { modifier(ClampedWidth()) }
}
