import SwiftUI

struct SystemDetailView: View {
    @EnvironmentObject var store: GameStore
    let systemId: Int
    @State private var showBuild = false
    @State private var upgradeTarget: BuiltModule? = nil

    var body: some View {
        let def = Galaxy.system(systemId)
        let s = store.state.sys(systemId)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header(def: def)
                if let s = s, s.claimed {
                    budgetCard(s: s, def: def)
                    SectionHeader(title: "Local Stockpiles", accent: Brand.teal)
                    stockGrid(s: s)
                    HStack {
                        SectionHeader(title: "Modules (\(s.modules.count))", accent: def.trait.color)
                        Button(action: { showBuild = true }) {
                            HStack(spacing: 4) {
                                Text("+").font(.console(16, weight: .bold))
                                Text("BUILD").font(.console(12, weight: .bold))
                            }
                            .foregroundColor(Brand.space)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Brand.cyan))
                        }.buttonStyle(.plain)
                    }
                    if s.modules.isEmpty {
                        Text("No modules yet. Build one to start production.")
                            .font(.console(12)).foregroundColor(Brand.textDim)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(s.modules) { m in
                            moduleRow(m: m, def: def)
                        }
                    }
                } else {
                    Text("This system is not claimed.")
                        .font(.console(13)).foregroundColor(Brand.textDim).padding()
                }
            }
            .padding(16)
            .clampedContent()
        }
        .background(Brand.background())
        .navigationBarTitle(def.name, displayMode: .inline)
        .sheet(isPresented: $showBuild) {
            BuildModuleSheet(systemId: systemId, close: { showBuild = false })
                .environmentObject(store)
        }
    }

    private func header(def: StarSystemDef) -> some View {
        ConsoleCard(accent: def.trait.color) {
            HStack(spacing: 12) {
                StarNodeIcon(size: 36, color: def.trait.color)
                VStack(alignment: .leading, spacing: 3) {
                    Text(def.name).font(.console(18, weight: .bold)).foregroundColor(Brand.text)
                    Text(def.trait.label).font(.console(12)).foregroundColor(def.trait.color)
                    HStack(spacing: 4) {
                        Text("Native ore:").font(.console(10)).foregroundColor(Brand.textFaint)
                        ResourceGlyph(kind: def.nativeOre.icon, size: 13, color: def.nativeOre.color)
                        Text(def.nativeOre.name).font(.console(10)).foregroundColor(Brand.textDim)
                    }
                }
                Spacer()
            }
        }
    }

    private func budgetCard(s: SystemState, def: StarSystemDef) -> some View {
        var powerGen = 0.0, powerDem = 0.0, laborGen = 0.0, laborDem = 0.0, foodDem = 0.0
        for m in s.modules {
            let pf = m.powerFlow
            if pf > 0 { powerGen += pf } else { powerDem += -pf }
            let lf = m.laborFlow
            if lf > 0 { laborGen += lf } else { laborDem += -lf }
            foodDem += m.foodConsumption
        }
        return ConsoleCard(accent: Brand.amber) {
            VStack(spacing: 10) {
                budgetRow("POWER", gen: powerGen, dem: powerDem, color: Brand.amber, kind: .power)
                budgetRow("LABOR", gen: laborGen, dem: laborDem, color: Brand.teal, kind: .people)
                HStack {
                    ResourceGlyph(kind: .food, size: 15, color: Brand.green)
                    Text("Food demand / cycle").font(.console(11)).foregroundColor(Brand.textDim)
                    Spacer()
                    Text(Fmt.compact(foodDem)).font(.console(13, weight: .bold))
                        .foregroundColor(foodDem > 0 && s.stockOf(.food) < foodDem ? Brand.red : Brand.text)
                }
            }
        }
    }

    private func budgetRow(_ label: String, gen: Double, dem: Double, color: Color, kind: ResIconKind) -> some View {
        let net = gen - dem
        return HStack(spacing: 8) {
            ResourceGlyph(kind: kind, size: 15, color: color)
            Text(label).font(.console(11, weight: .semibold)).foregroundColor(Brand.textDim)
            Spacer()
            Text("\(Fmt.compact(gen)) / \(Fmt.compact(dem))")
                .font(.console(12)).foregroundColor(Brand.textDim)
            Text(Fmt.signed(net))
                .font(.console(13, weight: .bold))
                .foregroundColor(net >= 0 ? Brand.green : Brand.red)
                .frame(width: 56, alignment: .trailing)
        }
    }

    private func stockGrid(s: SystemState) -> some View {
        let resources: [ResourceID] = [.ferrite, .cuprite, .silicate, .isotope, .alloy, .fuel, .components, .food, .credits]
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
            ForEach(resources, id: \.self) { r in
                HStack(spacing: 5) {
                    ResourceGlyph(kind: r.icon, size: 14, color: r.color)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(Fmt.compact(s.stockOf(r))).font(.console(12, weight: .semibold)).foregroundColor(Brand.text)
                        Text(r.short).font(.console(8)).foregroundColor(Brand.textFaint)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Brand.panel))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Brand.stroke, lineWidth: 1))
            }
        }
    }

    private func moduleRow(m: BuiltModule, def: StarSystemDef) -> some View {
        ConsoleCard(accent: m.type.accent) {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    ModuleGlyph(type: m.type, size: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(m.displayName).font(.console(14, weight: .bold)).foregroundColor(Brand.text)
                        Text("Level \(m.level)").font(.console(10)).foregroundColor(Brand.textDim)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        let p = m.powerFlow
                        HStack(spacing: 3) {
                            BoltIcon(size: 11, color: p >= 0 ? Brand.green : Brand.amber)
                            Text(Fmt.signed(p)).font(.console(11, weight: .semibold))
                                .foregroundColor(p >= 0 ? Brand.green : Brand.amber)
                        }
                        let l = m.laborFlow
                        if l != 0 {
                            HStack(spacing: 3) {
                                PeopleIcon(size: 11, color: l >= 0 ? Brand.green : Brand.teal)
                                Text(Fmt.signed(l)).font(.console(11)).foregroundColor(Brand.textDim)
                            }
                        }
                    }
                }
                if ModuleCost.canUpgrade(m) {
                    let cost = ModuleCost.upgradeCost(m)
                    Button(action: { store.upgrade(m.id, in: systemId) }) {
                        HStack {
                            Text(m.level >= 4 ? "TIER UP" : "UPGRADE")
                                .font(.console(12, weight: .bold))
                            Spacer()
                            CostLabel(cost: cost)
                        }
                        .foregroundColor(store.canUpgrade(m) ? Brand.space : Brand.textFaint)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(store.canUpgrade(m) ? m.type.accent : Brand.panelHi))
                    }
                    .buttonStyle(.plain)
                    .disabled(!store.canUpgrade(m))
                } else {
                    Text("MAX TIER").font(.console(11, weight: .bold)).foregroundColor(Brand.amber)
                        .frame(maxWidth: .infinity).padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Brand.amber.opacity(0.4), lineWidth: 1))
                }
            }
        }
    }
}

// MARK: - Module glyph router
struct ModuleGlyph: View {
    let type: ModuleType
    var size: CGFloat = 24
    var body: some View {
        switch type {
        case .habitat: PeopleIcon(size: size, color: type.accent)
        case .power: BoltIcon(size: size, color: type.accent)
        case .mining: OreCrystalIcon(size: size, color: type.accent)
        case .refinery: StationHexIcon(size: size, color: type.accent)
        case .fabricator: GridIcon(size: size, color: type.accent)
        case .cargoHub: GridIcon(size: size, color: type.accent)
        case .shipyard: ConvoyShipIcon(size: size, color: type.accent)
        case .research: FlaskIcon(size: size, color: type.accent)
        case .market: CreditIcon(size: size, color: type.accent)
        case .defense: ShieldIcon(size: size, color: type.accent)
        }
    }
}

struct CostLabel: View {
    let cost: [ResourceID: Double]
    var body: some View {
        HStack(spacing: 8) {
            ForEach(ResourceID.allCases.filter { cost[$0] != nil }, id: \.self) { r in
                HStack(spacing: 2) {
                    ResourceGlyph(kind: r.icon, size: 11, color: r.color)
                    Text(Fmt.compact(cost[r] ?? 0)).font(.console(11, weight: .semibold))
                }
            }
        }
    }
}

// MARK: - Build module sheet
struct BuildModuleSheet: View {
    @EnvironmentObject var store: GameStore
    let systemId: Int
    var close: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(ModuleType.buildOrder, id: \.self) { type in
                        buildRow(type)
                    }
                }
                .padding(16)
                .clampedContent()
            }
            .background(Brand.background())
            .navigationBarTitle("Build Module", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close", action: close).foregroundColor(Brand.cyan))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func buildRow(_ type: ModuleType) -> some View {
        let reason = store.buildReason(type, in: systemId)
        let canBuild = reason == nil
        return ConsoleCard(accent: type.accent) {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    ModuleGlyph(type: type, size: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(type.name).font(.console(15, weight: .bold)).foregroundColor(Brand.text)
                        Text(type.blurb).font(.console(10)).foregroundColor(Brand.textDim).lineLimit(2)
                    }
                    Spacer()
                }
                HStack {
                    CostLabel(cost: ModuleCost.buildCost(type))
                    Spacer()
                    Button(action: { store.build(type, in: systemId) }) {
                        Text("BUILD").font(.console(12, weight: .bold))
                            .foregroundColor(canBuild ? Brand.space : Brand.textFaint)
                            .padding(.horizontal, 16).padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 8)
                                .fill(canBuild ? type.accent : Brand.panelHi))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canBuild)
                }
                if let reason = reason {
                    Text(reason).font(.console(10)).foregroundColor(Brand.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

// MARK: - Content width clamp for scroll content (iPad)
struct ClampedContent: ViewModifier {
    func body(content: Content) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            content.frame(maxWidth: 640)
            Spacer(minLength: 0)
        }
    }
}
extension View {
    func clampedContent() -> some View { modifier(ClampedContent()) }
}
