import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                let unlocked = store.state.unlockedAchievements.count
                ConsoleCard(accent: Brand.amber) {
                    HStack {
                        TrophyIcon(size: 28, color: Brand.amber)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(unlocked) / \(Achievements.all.count)").font(.console(20, weight: .bold)).foregroundColor(Brand.text)
                            Text("Achievements unlocked").font(.console(10)).foregroundColor(Brand.textDim)
                        }
                        Spacer()
                    }
                }
                ForEach(Achievements.all) { a in
                    achievementRow(a)
                }
            }
            .padding(16)
            .clampedContent()
        }
        .background(Brand.background())
        .navigationBarTitle("Achievements", displayMode: .inline)
    }

    private func achievementRow(_ a: Achievement) -> some View {
        let progress = store.state.metric(a.metric)
        let unlocked = store.state.unlockedAchievements.contains(a.id)
        return ConsoleCard(accent: unlocked ? Brand.amber : Brand.textFaint) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill((unlocked ? Brand.amber : Brand.panelHi).opacity(unlocked ? 0.18 : 1))
                        .frame(width: 40, height: 40)
                    if unlocked { TrophyIcon(size: 22, color: Brand.amber) }
                    else { LockIcon(size: 18, color: Brand.textFaint) }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(a.title).font(.console(13, weight: .bold)).foregroundColor(unlocked ? Brand.text : Brand.textDim)
                    Text(a.desc).font(.console(10)).foregroundColor(Brand.textFaint)
                    if !unlocked {
                        ProgressBar(value: progress, total: a.target, color: Brand.amber)
                            .frame(height: 5)
                        Text("\(Fmt.compact(min(progress, a.target))) / \(Fmt.compact(a.target))")
                            .font(.console(8)).foregroundColor(Brand.textFaint)
                    } else {
                        Text("UNLOCKED").font(.console(9, weight: .bold)).foregroundColor(Brand.amber)
                    }
                }
                Spacer()
            }
        }
    }
}
