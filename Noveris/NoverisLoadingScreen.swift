import SwiftUI

struct NoverisLoadingScreen: View {
    @State private var pulse = false
    @State private var sweep = false

    var body: some View {
        ZStack {
            Brand.space.ignoresSafeArea()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .stroke(Brand.cyan.opacity(0.25), lineWidth: 2)
                        .frame(width: 120, height: 120)
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(Brand.cyan, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(sweep ? 360 : 0))
                        .animation(.linear(duration: 2.2).repeatForever(autoreverses: false), value: sweep)
                    RelayDishIcon(size: 64, color: Brand.teal)
                        .scaleEffect(pulse ? 1.08 : 0.94)
                        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)
                }

                Text("NOVERIS")
                    .font(.console(20, weight: .bold))
                    .tracking(3)
                    .foregroundColor(Brand.text)
                Text("Initializing relay grid…")
                    .font(.console(13))
                    .foregroundColor(Brand.textDim)
            }
        }
        .onAppear { pulse = true; sweep = true }
    }
}
