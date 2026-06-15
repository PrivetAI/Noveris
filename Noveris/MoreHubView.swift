import SwiftUI

struct MoreHubView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                hubLink("Objectives & Tier", "Campaign goals and command rank", Brand.green, AnyView(TrophyIcon(size: 24, color: Brand.green)), AnyView(ObjectivesView()))
                hubLink("Events & Log", "Anomalies and network history", Brand.cyan, AnyView(AnomalyIcon(size: 24, color: Brand.cyan)), AnyView(EventsLogView()))
                hubLink("Research Tree", "Unlock new technology", Brand.violet, AnyView(FlaskIcon(size: 24, color: Brand.violet)), AnyView(ResearchView()))
                hubLink("Codex", "Lore on modules, resources & systems", Brand.cyan, AnyView(BookIcon(size: 24, color: Brand.cyan)), AnyView(CodexView()))
                hubLink("Achievements", "Milestones earned", Brand.amber, AnyView(TrophyIcon(size: 24, color: Brand.amber)), AnyView(AchievementsView()))
                hubLink("Statistics", "Your empire by the numbers", Brand.teal, AnyView(ChartIcon(size: 24, color: Brand.teal)), AnyView(StatisticsView()))
                hubLink("How to Play", "In-game command guide", Brand.cyan, AnyView(BookIcon(size: 24, color: Brand.cyan)), AnyView(GuideView()))
                hubLink("Settings", "Sound, haptics, privacy & reset", Brand.textDim, AnyView(GearIcon(size: 24, color: Brand.textDim)), AnyView(SettingsView()))
            }
            .padding(16)
            .clampedContent()
        }
        .background(Brand.background())
        .navigationBarTitle("More", displayMode: .inline)
    }

    private func hubLink(_ title: String, _ subtitle: String, _ color: Color, _ icon: AnyView, _ dest: AnyView) -> some View {
        NavigationLink(destination: dest) {
            ConsoleCard(accent: color) {
                HStack(spacing: 12) {
                    icon.frame(width: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.console(14, weight: .bold)).foregroundColor(Brand.text)
                        Text(subtitle).font(.console(10)).foregroundColor(Brand.textDim)
                    }
                    Spacer()
                    ChevronIcon(size: 16, color: Brand.textDim)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct GuideView: View {
    private let sections: [(String, String)] = [
        ("Advance Cycle", "Tap ADVANCE in the top bar to run a cycle. Production, refining, trade, research and convoy movement all resolve at once, then a report appears."),
        ("Power & Labor", "Every module needs power and labor. Build Power Plants and Habitats first — if either runs short, all modules in that system throttle down."),
        ("The Supply Chain", "Mining Rigs pull the system's native ore. Refineries turn ferrite + cuprite into Alloys and silicate into Fuel. Fabricators turn Alloys + cuprite into Components — the key to advanced builds."),
        ("Food", "Habitats consume Food each cycle and farm a little themselves. A food shortage cuts labor, so keep a Refinery system fed or route food in by convoy."),
        ("Surveying & Claiming", "On the Galaxy map, tap a system next to your network. Survey it for credits, then Claim it once your Command Tier is high enough."),
        ("Convoys", "Research Shipwright Doctrine, build a Shipyard, then commission convoys. Create a cargo route between two systems and assign a convoy to haul resources along relay lanes."),
        ("Trade", "Build Trade Posts in populated systems and they will sell your surplus refined goods for Credits each cycle."),
        ("Research", "Research Labs generate points toward your active project. Each unlock opens new modules, faster convoys, longer lanes, or better ratios."),
        ("Anomalies", "Each cycle may surface an anomaly with a choice. Defense Arrays repel raiders; the right call can turn a crisis into a windfall."),
        ("Command Tier", "Claim more systems and refine more alloys to climb the six command ranks, unlocking deeper systems and advanced modules."),
    ]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(sections, id: \.0) { s in
                    ConsoleCard(accent: Brand.cyan) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(s.0).font(.console(14, weight: .bold)).foregroundColor(Brand.cyan)
                            Text(s.1).font(.console(11)).foregroundColor(Brand.textDim).lineSpacing(3)
                        }
                    }
                }
            }
            .padding(16)
            .clampedContent()
        }
        .background(Brand.background())
        .navigationBarTitle("How to Play", displayMode: .inline)
    }
}
