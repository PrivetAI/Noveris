import SwiftUI

struct ResearchView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                activeCard()
                SectionHeader(title: "Research Tree", accent: Brand.violet)
                ForEach(0...5, id: \.self) { col in
                    let nodes = ResearchTree.nodes.filter { $0.column == col }
                    if !nodes.isEmpty {
                        Text("TIER \(col + 1)").font(.console(10, weight: .bold)).tracking(1.5)
                            .foregroundColor(Brand.textFaint)
                        ForEach(nodes) { node in
                            nodeCard(node)
                        }
                    }
                }
            }
            .padding(16)
            .clampedContent()
        }
        .background(Brand.background())
        .navigationBarTitle("Research", displayMode: .inline)
    }

    private func activeCard() -> some View {
        Group {
            if let ar = store.state.activeResearch, let node = ResearchTree.node(ar.nodeId) {
                ConsoleCard(accent: Brand.violet) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            FlaskIcon(size: 18, color: Brand.violet)
                            Text("Researching: \(node.name)").font(.console(13, weight: .bold)).foregroundColor(Brand.text)
                            Spacer()
                        }
                        ProgressBar(value: ar.progress, total: node.cost, color: Brand.violet)
                        Text("\(Fmt.compact(ar.progress)) / \(Fmt.compact(node.cost)) RSC")
                            .font(.console(10)).foregroundColor(Brand.textDim)
                        let labs = store.state.systems.filter { $0.claimed }.flatMap { $0.modules }.filter { $0.type == .research }.count
                        Text(labs > 0
                             ? "\(labs) lab(s) + command staff contributing each cycle"
                             : "Command staff add \(Fmt.compact(ResearchTree.baseOutput)) RSC per cycle. Build Research Labs to go faster.")
                            .font(.console(9)).foregroundColor(labs > 0 ? Brand.teal : Brand.amber)
                    }
                }
            } else {
                ConsoleCard(accent: Brand.violet) {
                    HStack {
                        FlaskIcon(size: 18, color: Brand.violet)
                        Text("No active research. Select a project below.")
                            .font(.console(12)).foregroundColor(Brand.textDim)
                        Spacer()
                    }
                }
            }
        }
    }

    private func nodeCard(_ node: ResearchNode) -> some View {
        let done = store.state.unlockedTech.contains(node.id)
        let prereqMet = store.researchPrereqsMet(node.id)
        let active = store.state.activeResearch?.nodeId == node.id
        let canStart = store.canStartResearch(node.id)
        let accent: Color = done ? Brand.green : (prereqMet ? Brand.violet : Brand.textFaint)

        return ConsoleCard(accent: accent) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if done { CheckIcon(size: 16, color: Brand.green) }
                    else if !prereqMet { LockIcon(size: 16, color: Brand.textFaint) }
                    else { FlaskIcon(size: 16, color: Brand.violet) }
                    Text(node.name).font(.console(14, weight: .bold)).foregroundColor(Brand.text)
                    Spacer()
                    if done { Text("DONE").font(.console(10, weight: .bold)).foregroundColor(Brand.green) }
                }
                Text(node.blurb).font(.console(10)).foregroundColor(Brand.textDim)
                if !node.prereqs.isEmpty {
                    HStack(spacing: 4) {
                        Text("Requires:").font(.console(9)).foregroundColor(Brand.textFaint)
                        ForEach(node.prereqs, id: \.self) { pid in
                            Text(ResearchTree.node(pid)?.name ?? pid)
                                .font(.console(9, weight: .semibold))
                                .foregroundColor(store.state.unlockedTech.contains(pid) ? Brand.green : Brand.red)
                        }
                    }
                }
                if !done {
                    HStack {
                        Text("\(Fmt.compact(node.cost)) RSC").font(.console(10, weight: .semibold)).foregroundColor(Brand.violet)
                        Text("· \(Fmt.compact(node.creditCost)) CR to begin").font(.console(10)).foregroundColor(Brand.amber)
                        Spacer()
                        if active {
                            Text("IN PROGRESS").font(.console(11, weight: .bold)).foregroundColor(Brand.violet)
                        } else {
                            Button(action: { store.startResearch(node.id) }) {
                                Text("RESEARCH").font(.console(11, weight: .bold))
                                    .foregroundColor(canStart ? Brand.space : Brand.textFaint)
                                    .padding(.horizontal, 14).padding(.vertical, 6)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(canStart ? Brand.violet : Brand.panelHi))
                            }.buttonStyle(.plain).disabled(!canStart)
                        }
                    }
                    if !prereqMet {
                        Text("Complete prerequisites first").font(.console(9)).foregroundColor(Brand.red)
                    } else if store.state.activeResearch != nil && !active {
                        Text("Finish current research first").font(.console(9)).foregroundColor(Brand.amber)
                    }
                }
            }
        }
    }
}

struct ProgressBar: View {
    let value: Double
    let total: Double
    var color: Color = Brand.cyan
    var body: some View {
        GeometryReader { geo in
            let frac = total > 0 ? min(1, max(0, value / total)) : 0
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(Brand.panelHi)
                RoundedRectangle(cornerRadius: 4).fill(color)
                    .frame(width: geo.size.width * CGFloat(frac))
            }
        }
        .frame(height: 8)
    }
}
