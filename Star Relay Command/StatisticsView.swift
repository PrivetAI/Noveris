import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Network", accent: Brand.cyan)
                grid([
                    ("Cycle", "\(store.state.cycle)"),
                    ("Command Tier", "\(store.state.commandTier + 1)"),
                    ("Claimed Systems", "\(store.state.claimedCount)"),
                    ("Surveyed Systems", "\(store.state.surveyedCount)"),
                    ("Modules Built", Fmt.compact(store.state.metric(.modulesBuilt))),
                    ("Convoys", "\(store.state.convoys.count)"),
                    ("Routes", "\(store.state.routes.count)"),
                    ("Research Done", "\(store.state.researchCompletedCount) / \(ResearchTree.nodes.count)"),
                ])
                SectionHeader(title: "Lifetime Production", accent: Brand.teal)
                grid([
                    ("Alloys Refined", Fmt.compact(store.state.metric(.alloyRefined))),
                    ("Fuel Refined", Fmt.compact(store.state.metric(.fuelRefined))),
                    ("Components Made", Fmt.compact(store.state.metric(.componentsMade))),
                    ("Isotopes Mined", Fmt.compact(store.state.metric(.isotopeMined))),
                    ("Trade Credits", Fmt.compact(store.state.metric(.creditsEarned))),
                    ("Deliveries", Fmt.compact(store.state.metric(.deliveries))),
                    ("Convoys Built", Fmt.compact(store.state.metric(.convoysBuilt))),
                    ("Raids Repelled", Fmt.compact(store.state.metric(.raidsRepelled))),
                ])
                SectionHeader(title: "Progress", accent: Brand.amber)
                grid([
                    ("Objectives", "\(store.state.completedObjectives.count) / \(Objectives.all.count)"),
                    ("Achievements", "\(store.state.unlockedAchievements.count) / \(Achievements.all.count)"),
                    ("Defense Rating", Fmt.compact(store.clusterDefenseRating())),
                    ("Cluster Credits", Fmt.compact(store.state.totalStock(.credits))),
                ])
            }
            .padding(16)
            .clampedContent()
        }
        .background(Brand.background())
        .navigationBarTitle("Statistics", displayMode: .inline)
    }

    private func grid(_ items: [(String, String)]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.0) { item in
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.1).font(.console(17, weight: .bold)).foregroundColor(Brand.text)
                    Text(item.0.uppercased()).font(.console(9)).tracking(0.5).foregroundColor(Brand.textFaint)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 9).fill(Brand.panel))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(Brand.stroke, lineWidth: 1))
            }
        }
    }
}
