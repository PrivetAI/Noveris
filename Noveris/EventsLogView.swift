import SwiftUI

struct EventsLogView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let eid = store.state.pendingEventId, let ev = EventCatalog.event(eid) {
                    SectionHeader(title: "Pending Decision", accent: Brand.amber)
                    EventDecisionCard(ev: ev) { idx in store.resolveEvent(idx) }
                }

                SectionHeader(title: "Event Log", accent: Brand.cyan)
                if store.state.log.isEmpty {
                    Text("No events logged yet. Advance a cycle to begin.")
                        .font(.console(12)).foregroundColor(Brand.textDim).padding(.vertical, 8)
                } else {
                    ForEach(store.state.log) { entry in
                        logRow(entry)
                    }
                }
            }
            .padding(16)
            .clampedContent()
        }
        .background(Brand.background())
        .navigationBarTitle("Events & Log", displayMode: .inline)
    }

    private func logRow(_ entry: LogEntry) -> some View {
        let color = colorFor(entry.kindRaw)
        return HStack(alignment: .top, spacing: 10) {
            Rectangle().fill(color).frame(width: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.text).font(.console(11)).foregroundColor(Brand.text)
                Text("Cycle \(entry.cycle)").font(.console(9)).foregroundColor(Brand.textFaint)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Brand.panel))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Brand.stroke, lineWidth: 1))
    }

    private func colorFor(_ raw: String) -> Color {
        if raw == "system" { return Brand.cyan }
        if let kind = EventKind(rawValue: raw) { return Codex.anomalyColor(kind) }
        return Brand.textDim
    }
}
