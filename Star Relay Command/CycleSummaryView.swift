import SwiftUI

struct CycleSummaryView: View {
    @EnvironmentObject var store: GameStore
    let result: CycleResult
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Cycle banner
                    HStack {
                        StarNodeIcon(size: 26, color: Brand.amber)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("CYCLE \(result.cycle) COMPLETE").font(.console(16, weight: .bold)).foregroundColor(Brand.text)
                            Text(Tiers.tier(store.state.commandTier).name).font(.console(11)).foregroundColor(Brand.cyan)
                        }
                        Spacer()
                    }

                    if result.researchCompleted != nil {
                        banner("Research complete: \(result.researchCompleted!)", Brand.violet, FlaskIcon(size: 16, color: Brand.violet))
                    }

                    // Production
                    if !result.produced.isEmpty {
                        SectionHeader(title: "Produced", accent: Brand.green)
                        deltaGrid(result.produced, positive: true)
                    }
                    if !result.consumed.isEmpty {
                        SectionHeader(title: "Consumed", accent: Brand.amber)
                        deltaGrid(result.consumed, positive: false)
                    }

                    SectionHeader(title: "Summary", accent: Brand.cyan)
                    ConsoleCard(accent: Brand.cyan) {
                        VStack(spacing: 8) {
                            summaryRow("Trade revenue", "+\(Fmt.compact(result.creditsFromTrade)) CR", Brand.amber)
                            summaryRow("Deliveries", "\(result.deliveries)", Brand.green)
                            summaryRow("Research gained", "\(Fmt.compact(result.researchGained)) RSC", Brand.violet)
                            summaryRow("Power balance", Fmt.signed(result.powerBalance), result.powerBalance >= 0 ? Brand.green : Brand.red)
                            summaryRow("Labor balance", Fmt.signed(result.laborBalance), result.laborBalance >= 0 ? Brand.green : Brand.red)
                        }
                    }

                    if !result.notes.isEmpty {
                        ForEach(Array(Set(result.notes)), id: \.self) { note in
                            Text("• \(note)").font(.console(10)).foregroundColor(Brand.textDim)
                        }
                    }

                    // Pending event decision
                    if let eid = store.state.pendingEventId, let ev = EventCatalog.event(eid) {
                        SectionHeader(title: "Command Decision", accent: Brand.amber)
                        EventDecisionCard(ev: ev) { idx in
                            store.resolveEvent(idx)
                            presentationMode.wrappedValue.dismiss()
                            store.lastResult = nil
                        }
                    }
                }
                .padding(16)
                .clampedContent()
            }
            .background(Brand.background())
            .navigationBarTitle("Cycle Report", displayMode: .inline)
            .navigationBarItems(trailing:
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                    store.lastResult = nil
                }) {
                    Text(store.state.pendingEventId == nil ? "Continue" : "Later")
                        .font(.console(14, weight: .bold)).foregroundColor(Brand.cyan)
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func banner(_ text: String, _ color: Color, _ icon: some View) -> some View {
        HStack(spacing: 8) {
            icon
            Text(text).font(.console(12, weight: .bold)).foregroundColor(color)
            Spacer()
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 9).fill(color.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(color.opacity(0.4), lineWidth: 1))
    }

    private func deltaGrid(_ dict: [ResourceID: Double], positive: Bool) -> some View {
        let items = dict.filter { $0.value > 0.01 }.sorted { $0.key.rawValue < $1.key.rawValue }
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.key) { (r, v) in
                HStack(spacing: 5) {
                    ResourceGlyph(kind: r.icon, size: 13, color: r.color)
                    Text((positive ? "+" : "-") + Fmt.compact(v)).font(.console(12, weight: .semibold))
                        .foregroundColor(positive ? Brand.green : Brand.amber)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Brand.panel))
            }
        }
    }

    private func summaryRow(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label).font(.console(12)).foregroundColor(Brand.textDim)
            Spacer()
            Text(value).font(.console(13, weight: .bold)).foregroundColor(color)
        }
    }
}

struct EventDecisionCard: View {
    let ev: EventDef
    var choose: (Int) -> Void

    var body: some View {
        ConsoleCard(accent: Codex.anomalyColor(ev.kind)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    AnomalyIcon(size: 22, color: Codex.anomalyColor(ev.kind))
                    Text(ev.title).font(.console(15, weight: .bold)).foregroundColor(Brand.text)
                    Spacer()
                }
                Text(ev.body).font(.console(12)).foregroundColor(Brand.textDim).lineSpacing(3)
                ForEach(Array(ev.choices.enumerated()), id: \.offset) { (i, c) in
                    Button(action: { choose(i) }) {
                        Text(c.label).font(.console(13, weight: .bold))
                            .foregroundColor(Brand.space)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 9).fill(Codex.anomalyColor(ev.kind)))
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}
