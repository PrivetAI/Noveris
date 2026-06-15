import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var store: GameStore
    var start: () -> Void
    @State private var glow = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Brand.background()
                starfield(in: geo.size)
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 18) {
                        ZStack {
                            Circle().stroke(Brand.cyan.opacity(0.3), lineWidth: 1.5)
                                .frame(width: 150, height: 150)
                                .scaleEffect(glow ? 1.05 : 0.95)
                            RelayDishIcon(size: 92, color: Brand.teal)
                        }
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: glow)

                        Text("NOVERIS")
                            .font(.console(36, weight: .bold)).tracking(6)
                            .foregroundColor(Brand.text)
                        Text("N E T W O R K")
                            .font(.console(16, weight: .semibold)).tracking(10)
                            .foregroundColor(Brand.cyan)
                        Text("Command a cluster-spanning relay network")
                            .font(.console(12)).foregroundColor(Brand.textDim)
                    }
                    Spacer()
                    VStack(spacing: 12) {
                        Button(action: start) {
                            Text(store.state.cycle > 0 ? "RESUME COMMAND" : "BEGIN COMMAND")
                        }
                        .buttonStyle(ConsoleButton(accent: Brand.cyan))

                        HStack(spacing: 12) {
                            stat("CYCLE", "\(store.state.cycle)")
                            stat("SYSTEMS", "\(store.state.claimedCount)")
                            stat("TIER", "\(store.state.commandTier + 1)")
                        }
                    }
                    .frame(maxWidth: 460)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { glow = true }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.console(18, weight: .bold)).foregroundColor(Brand.teal)
            Text(label).font(.console(9)).tracking(1).foregroundColor(Brand.textFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Brand.panel))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Brand.stroke, lineWidth: 1))
    }

    private func starfield(in size: CGSize) -> some View {
        Canvas { ctx, sz in
            var seed: UInt64 = 88
            func rnd() -> Double {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return Double((seed >> 33) & 0xFFFFFF) / Double(0xFFFFFF)
            }
            for _ in 0..<80 {
                let x = rnd() * sz.width
                let y = rnd() * sz.height
                let r = rnd() * 1.6 + 0.4
                let op = rnd() * 0.6 + 0.15
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                         with: .color(Color.white.opacity(op)))
            }
        }
        .allowsHitTesting(false)
    }
}
