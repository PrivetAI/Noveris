import SwiftUI

struct OnboardingView: View {
    var done: () -> Void
    @State private var page = 0

    private let pages: [(String, String, AnyView)] = [
        ("Your First Outpost",
         "You command Helion Prime, a lone outpost. Build modules, mine ore, and grow a relay network spanning the star cluster. Each Advance-Cycle runs production and moves your fleet one lane-hop.",
         AnyView(RelayDishIcon(size: 80, color: Brand.teal))),
        ("The Supply Chain",
         "Mining Rigs pull ore. Refineries turn ore into Alloys and Fuel. Fabricators build Components. Balance Power and Labor — short either and modules throttle down.",
         AnyView(StationHexIcon(size: 80, color: Brand.cyan))),
        ("Claim the Galaxy",
         "Survey systems next to your network, then claim them once your Command Tier is high enough. Each system has traits: resource-rich, hazardous, populated, or derelict.",
         AnyView(MapIcon(size: 80, color: Brand.amber))),
        ("Convoys & Trade",
         "Build a Shipyard, commission convoys, and assign cargo routes along relay lanes. Sell surplus at Trade Posts in populated systems for Credits to fund expansion.",
         AnyView(ConvoyShipIcon(size: 80, color: Brand.green))),
        ("Research & Anomalies",
         "Research unlocks new modules, faster convoys and longer lanes. Each cycle may surface an anomaly — a choice-based event. Decide wisely, Commander.",
         AnyView(AnomalyIcon(size: 80, color: Brand.violet))),
    ]

    var body: some View {
        ZStack {
            Brand.space.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: done) {
                        Text("Skip").font(.console(13, weight: .semibold)).foregroundColor(Brand.textDim)
                    }.buttonStyle(.plain)
                }
                .padding(16)

                Spacer()
                VStack(spacing: 26) {
                    pages[page].2
                        .frame(height: 100)
                    Text(pages[page].0)
                        .font(.console(24, weight: .bold)).foregroundColor(Brand.text)
                        .multilineTextAlignment(.center)
                    Text(pages[page].1)
                        .font(.console(14)).foregroundColor(Brand.textDim)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 30)
                }
                .frame(maxWidth: 480)
                Spacer()

                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Brand.cyan : Brand.stroke)
                            .frame(width: i == page ? 22 : 8, height: 8)
                    }
                }
                .padding(.bottom, 18)

                Button(action: {
                    if page < pages.count - 1 { page += 1 } else { done() }
                }) {
                    Text(page < pages.count - 1 ? "NEXT" : "BEGIN")
                }
                .buttonStyle(ConsoleButton(accent: Brand.cyan))
                .frame(maxWidth: 460)
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
    }
}
