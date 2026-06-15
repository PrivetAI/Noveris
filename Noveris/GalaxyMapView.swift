import SwiftUI

struct GalaxyMapView: View {
    @EnvironmentObject var store: GameStore
    @State private var selected: Int? = nil
    @State private var scale: CGFloat = 1.0
    @State private var detailSystem: Int? = nil

    var body: some View {
        GeometryReader { geo in
            // anchor ALL node/lane math to parent screenSize (NOT Canvas closure size)
            let screenSize = CGSize(width: min(geo.size.width, UIScreen.main.bounds.width),
                                    height: geo.size.height)
            let mapW = screenSize.width
            let mapH = screenSize.height

            ZStack {
                Brand.space.ignoresSafeArea()

                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    ZStack {
                        // canvas drawn at fixed content size derived from screenSize
                        LaneCanvas(unlockedTech: store.state.unlockedTech,
                                   systems: store.state.systems,
                                   contentSize: CGSize(width: mapW * 1.4, height: mapH * 1.4))
                            .frame(width: mapW * 1.4, height: mapH * 1.4)

                        // node markers positioned against the SAME content size
                        ForEach(Galaxy.systems) { def in
                            nodeMarker(def: def, content: CGSize(width: mapW * 1.4, height: mapH * 1.4))
                        }

                        // convoy markers
                        ForEach(store.state.convoys.filter { !$0.idle }) { conv in
                            convoyMarker(conv, content: CGSize(width: mapW * 1.4, height: mapH * 1.4))
                        }
                    }
                    .frame(width: mapW * 1.4, height: mapH * 1.4)
                }

                // selected system info card overlay
                if let sel = selected {
                    VStack {
                        Spacer()
                        SystemSummaryCard(systemId: sel,
                                          open: { detailSystem = sel },
                                          close: { selected = nil })
                            .padding(12)
                            .frame(maxWidth: 600)
                    }
                }
            }
            .frame(width: geo.size.width)
        }
        .navigationBarTitle("Galaxy Map", displayMode: .inline)
        .background(
            NavigationLink(
                destination: SystemDetailView(systemId: detailSystem ?? 0),
                isActive: Binding(get: { detailSystem != nil }, set: { if !$0 { detailSystem = nil } })
            ) { EmptyView() }.hidden()
        )
    }

    private func pos(_ def: StarSystemDef, _ content: CGSize) -> CGPoint {
        CGPoint(x: def.pos.x * content.width, y: def.pos.y * content.height)
    }

    private func nodeMarker(def: StarSystemDef, content: CGSize) -> some View {
        let s = store.state.sys(def.id)
        let claimed = s?.claimed ?? false
        let surveyed = s?.surveyed ?? false
        let reachable = store.isReachable(def.id)
        let p = pos(def, content)
        let color: Color = claimed ? def.trait.color : (surveyed ? Brand.textDim : (reachable ? Brand.amber : Brand.textFaint))

        return Button(action: { selected = def.id }) {
            VStack(spacing: 3) {
                ZStack {
                    if claimed {
                        Circle().fill(def.trait.color.opacity(0.2))
                            .frame(width: 34, height: 34)
                    }
                    StarNodeIcon(size: claimed ? 26 : 20, color: color)
                    if !surveyed && reachable {
                        Circle().stroke(Brand.amber, style: StrokeStyle(lineWidth: 1, dash: [3,2]))
                            .frame(width: 32, height: 32)
                    }
                }
                Text(def.name)
                    .font(.console(8, weight: claimed ? .bold : .regular))
                    .foregroundColor(claimed ? Brand.text : Brand.textDim)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .buttonStyle(.plain)
        .position(x: p.x, y: p.y)
        .opacity(reachable || surveyed || claimed ? 1 : 0.35)
    }

    private func convoyMarker(_ conv: Convoy, content: CGSize) -> some View {
        // interpolate position along current lane
        var point = CGPoint(x: 0.5, y: 0.5)
        if conv.legIndex < conv.pathNodes.count - 1 {
            let a = Galaxy.system(conv.pathNodes[conv.legIndex]).pos
            let b = Galaxy.system(conv.pathNodes[conv.legIndex + 1]).pos
            let lane = Galaxy.lane(conv.pathNodes[conv.legIndex], conv.pathNodes[conv.legIndex + 1])
            let total = CGFloat(max(1, lane?.hops ?? 1))
            let frac = min(1, CGFloat(conv.hopProgress) / total)
            point = CGPoint(x: a.x + (b.x - a.x) * frac, y: a.y + (b.y - a.y) * frac)
        } else {
            point = Galaxy.system(conv.currentSystem).pos
        }
        let p = CGPoint(x: point.x * content.width, y: point.y * content.height)
        return ConvoyShipIcon(size: 16, color: Brand.green)
            .position(x: p.x, y: p.y)
    }
}

// MARK: - Lane drawing canvas
struct LaneCanvas: View {
    let unlockedTech: Set<String>
    let systems: [SystemState]
    let contentSize: CGSize

    var body: some View {
        Canvas { ctx, _ in
            // draw lanes using contentSize (NOT the closure size param) for correct scaling
            for lane in Galaxy.lanes {
                let a = Galaxy.system(lane.a).pos
                let b = Galaxy.system(lane.b).pos
                let pa = CGPoint(x: a.x * contentSize.width, y: a.y * contentSize.height)
                let pb = CGPoint(x: b.x * contentSize.width, y: b.y * contentSize.height)
                let gated = lane.requiresTech != nil && !unlockedTech.contains(lane.requiresTech!)
                let aClaimed = systems.first { $0.id == lane.a }?.claimed ?? false
                let bClaimed = systems.first { $0.id == lane.b }?.claimed ?? false
                let active = aClaimed || bClaimed
                var path = Path()
                path.move(to: pa); path.addLine(to: pb)
                let color: Color = gated ? Brand.red.opacity(0.25)
                    : (active ? Brand.cyan.opacity(0.5) : Brand.stroke.opacity(0.5))
                let style = StrokeStyle(lineWidth: active ? 1.5 : 1,
                                        dash: gated ? [4, 4] : (lane.hazard > 0.15 ? [6, 3] : []))
                ctx.stroke(path, with: .color(color), style: style)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Selected system summary card
struct SystemSummaryCard: View {
    @EnvironmentObject var store: GameStore
    let systemId: Int
    var open: () -> Void
    var close: () -> Void

    var body: some View {
        let def = Galaxy.system(systemId)
        let s = store.state.sys(systemId)
        ConsoleCard(accent: def.trait.color) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    StarNodeIcon(size: 22, color: def.trait.color)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(def.name).font(.console(16, weight: .bold)).foregroundColor(Brand.text)
                        Text(def.trait.label).font(.console(11)).foregroundColor(def.trait.color)
                    }
                    Spacer()
                    Button(action: close) { XIcon(size: 18, color: Brand.textDim) }.buttonStyle(.plain)
                }
                Text(def.trait.blurb).font(.console(11)).foregroundColor(Brand.textDim)

                HStack(spacing: 8) {
                    tag("Native", def.nativeOre.short, def.nativeOre.color)
                    if let s = s, s.claimed {
                        tag("Modules", "\(s.modules.count)", Brand.teal)
                    }
                    if let s = s, !s.claimed {
                        tag("Survey", Fmt.compact(def.surveyCost) + " CR", Brand.amber)
                    }
                }

                if let s = s {
                    actionRow(def: def, s: s)
                }
            }
        }
    }

    @ViewBuilder
    private func actionRow(def: StarSystemDef, s: SystemState) -> some View {
        if s.claimed {
            Button(action: open) { Text("MANAGE SYSTEM") }
                .buttonStyle(ConsoleButton(accent: def.trait.color))
        } else if s.surveyed {
            if store.canClaim(systemId) {
                Button(action: { store.claim(systemId) }) { Text("CLAIM SYSTEM") }
                    .buttonStyle(ConsoleButton(accent: Brand.green))
            } else {
                let reason = store.state.commandTier < def.claimTier
                    ? "Requires Command Tier \(def.claimTier + 1)"
                    : "Needs 100 CR + 30 Alloy"
                Text(reason).font(.console(11)).foregroundColor(Brand.red)
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Brand.red.opacity(0.4), lineWidth: 1))
            }
        } else if store.isReachable(systemId) {
            if store.canSurvey(systemId) {
                Button(action: { store.survey(systemId) }) {
                    Text("SURVEY · \(Fmt.compact(def.surveyCost)) CR")
                }
                .buttonStyle(ConsoleButton(accent: Brand.amber))
            } else {
                Text("Need \(Fmt.compact(def.surveyCost)) CR to survey")
                    .font(.console(11)).foregroundColor(Brand.red)
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Brand.red.opacity(0.4), lineWidth: 1))
            }
        } else {
            Text("Not connected to your network")
                .font(.console(11)).foregroundColor(Brand.textFaint)
                .frame(maxWidth: .infinity).padding(.vertical, 8)
        }
    }

    private func tag(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.console(12, weight: .bold)).foregroundColor(color)
            Text(label.uppercased()).font(.console(8)).tracking(0.5).foregroundColor(Brand.textFaint)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 7).fill(Brand.panelHi))
    }
}
