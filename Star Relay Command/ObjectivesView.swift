import SwiftUI

struct ObjectivesView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                tierLadder()
                SectionHeader(title: "Campaign Objectives", accent: Brand.green)
                ForEach(Objectives.all) { o in
                    objectiveRow(o)
                }
            }
            .padding(16)
            .clampedContent()
        }
        .background(Brand.background())
        .navigationBarTitle("Objectives & Tier", displayMode: .inline)
    }

    private func tierLadder() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Command Tier Ladder", accent: Brand.amber)
            ForEach(Tiers.ladder) { tier in
                let reached = store.state.commandTier >= tier.id
                let current = store.state.commandTier == tier.id
                ConsoleCard(accent: current ? Brand.cyan : (reached ? Brand.green : Brand.textFaint)) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().fill((reached ? Brand.green : Brand.panelHi).opacity(reached ? 0.2 : 1))
                                .frame(width: 36, height: 36)
                            if reached { CheckIcon(size: 18, color: Brand.green) }
                            else { Text("\(tier.id + 1)").font(.console(15, weight: .bold)).foregroundColor(Brand.textDim) }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tier.name).font(.console(14, weight: .bold)).foregroundColor(Brand.text)
                            Text(tier.blurb).font(.console(10)).foregroundColor(Brand.textDim).lineLimit(2)
                            Text("Claim \(tier.claimedRequired) · \(Fmt.compact(tier.alloyRequired)) alloys refined")
                                .font(.console(9)).foregroundColor(Brand.textFaint)
                        }
                        Spacer()
                        if current { Text("CURRENT").font(.console(9, weight: .bold)).foregroundColor(Brand.cyan) }
                    }
                }
            }
        }
    }

    private func objectiveRow(_ o: Objective) -> some View {
        let progress = store.state.metric(o.metric)
        let done = store.state.completedObjectives.contains(o.id)
        return ConsoleCard(accent: done ? Brand.green : Brand.cyan) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if done { CheckIcon(size: 16, color: Brand.green) }
                    Text(o.title).font(.console(13, weight: .bold)).foregroundColor(Brand.text)
                    Spacer()
                    Text("+\(Fmt.compact(o.reward)) CR").font(.console(10, weight: .bold)).foregroundColor(Brand.amber)
                }
                ProgressBar(value: progress, total: o.target, color: done ? Brand.green : Brand.cyan)
                Text("\(Fmt.compact(min(progress, o.target))) / \(Fmt.compact(o.target))")
                    .font(.console(9)).foregroundColor(Brand.textDim)
            }
        }
    }
}
