import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: GameStore
    @EnvironmentObject var settings: AppSettings
    @State private var selectedTab = 0
    @State private var showMenu = true
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            Brand.background()
            if showMenu {
                MainMenuView(start: {
                    showMenu = false
                    if !store.state.onboardingDone { showOnboarding = true }
                })
                .transition(.opacity)
            } else {
                mainInterface
            }
        }
        .sheet(isPresented: $showOnboarding, onDismiss: {
            store.state.onboardingDone = true
            store.save()
        }) {
            OnboardingView(done: { showOnboarding = false })
        }
    }

    private var mainInterface: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                TopStatusBar(toMenu: { withAnimation { showMenu = true } })
                Group {
                    switch selectedTab {
                    case 0:
                        NavigationView { GalaxyMapView() }.navigationViewStyle(StackNavigationViewStyle())
                    case 1:
                        NavigationView { EconomyDashboardView() }.navigationViewStyle(StackNavigationViewStyle())
                    case 2:
                        NavigationView { ConvoyPlannerView() }.navigationViewStyle(StackNavigationViewStyle())
                    case 3:
                        NavigationView { ResearchView() }.navigationViewStyle(StackNavigationViewStyle())
                    default:
                        NavigationView { MoreHubView() }.navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                tabBar
            }
        }
        // single sheet on this view: cycle summary (item:)
        .sheet(item: $store.lastResult) { result in
            CycleSummaryView(result: result)
                .environmentObject(store)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(0, "Galaxy", AnyView(MapIcon(size: 22, color: tint(0))))
            tabButton(1, "Economy", AnyView(ChartIcon(size: 22, color: tint(1))))
            tabButton(2, "Convoys", AnyView(ConvoyShipIcon(size: 22, color: tint(2))))
            tabButton(3, "Research", AnyView(FlaskIcon(size: 22, color: tint(3))))
            tabButton(4, "More", AnyView(GridIcon(size: 22, color: tint(4))))
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Brand.panel
                .overlay(Rectangle().fill(Brand.stroke).frame(height: 1), alignment: .top)
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tint(_ i: Int) -> Color { selectedTab == i ? Brand.cyan : Brand.textFaint }

    private func tabButton(_ index: Int, _ label: String, _ icon: AnyView) -> some View {
        Button(action: { selectedTab = index }) {
            VStack(spacing: 4) {
                icon.frame(height: 24)
                Text(label)
                    .font(.console(10, weight: selectedTab == index ? .bold : .regular))
                    .foregroundColor(tint(index))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Top status bar with key resources + advance cycle
struct TopStatusBar: View {
    @EnvironmentObject var store: GameStore
    var toMenu: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button(action: toMenu) {
                    HStack(spacing: 6) {
                        StarNodeIcon(size: 18, color: Brand.amber)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("CYCLE \(store.state.cycle)")
                                .font(.console(13, weight: .bold)).foregroundColor(Brand.text)
                            Text(Tiers.tier(store.state.commandTier).name)
                                .font(.console(9)).foregroundColor(Brand.textDim)
                        }
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                Button(action: {
                    if store.state.pendingEventId == nil {
                        store.advanceCycle()
                    } else {
                        // re-open the cycle report so the pending decision can be resolved
                        store.lastResult = CycleResult(cycle: store.state.cycle)
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(store.state.pendingEventId == nil ? "ADVANCE" : "DECIDE")
                            .font(.console(13, weight: .bold))
                        ChevronIcon(size: 14, color: Brand.space)
                    }
                    .foregroundColor(Brand.space)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 9).fill(store.state.pendingEventId == nil ? Brand.cyan : Brand.amber))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach([ResourceID.credits, .alloy, .fuel, .components, .isotope, .food], id: \.self) { r in
                        ResChip(res: r, amount: store.state.totalStock(r))
                    }
                }
                .padding(.horizontal, 14)
            }
            .padding(.bottom, 6)
        }
        .background(Brand.panel.overlay(Rectangle().fill(Brand.stroke).frame(height: 1), alignment: .bottom))
    }
}

struct ResChip: View {
    let res: ResourceID
    let amount: Double
    var body: some View {
        HStack(spacing: 5) {
            ResourceGlyph(kind: res.icon, size: 15, color: res.color)
            Text(Fmt.compact(amount))
                .font(.console(12, weight: .semibold))
                .foregroundColor(Brand.text)
                .lineLimit(1)
        }
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 8).fill(Brand.panelHi))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(res.color.opacity(0.3), lineWidth: 1))
    }
}
