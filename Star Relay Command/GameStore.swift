import SwiftUI

// MARK: - Cycle result (for summary sheet)
struct CycleResult: Identifiable {
    let id = UUID()
    var cycle: Int
    var produced: [ResourceID: Double] = [:]
    var consumed: [ResourceID: Double] = [:]
    var creditsFromTrade: Double = 0
    var deliveries: Int = 0
    var powerBalance: Double = 0
    var laborBalance: Double = 0
    var researchGained: Double = 0
    var researchCompleted: String? = nil
    var newTier: Int? = nil
    var notes: [String] = []
    var triggeredEventId: String? = nil
}

// MARK: - Settings (persisted separately, simple)
final class AppSettings: ObservableObject {
    @Published var sound: Bool { didSet { UserDefaults.standard.set(sound, forKey: "src.set.sound") } }
    @Published var haptics: Bool { didSet { UserDefaults.standard.set(haptics, forKey: "src.set.haptics") } }
    init() {
        let d = UserDefaults.standard
        sound = d.object(forKey: "src.set.sound") as? Bool ?? true
        haptics = d.object(forKey: "src.set.haptics") as? Bool ?? true
    }
}

// MARK: - Game store
final class GameStore: ObservableObject {
    @Published var state: GameState
    @Published var lastResult: CycleResult? = nil   // drives cycle-summary sheet (item:)

    private let saveKey = "src.gamestate.v1"

    init() {
        if let loaded = GameStore.load() {
            state = loaded
        } else {
            state = GameState.newGame()
        }
    }

    // MARK: Persistence
    static func load() -> GameState? {
        guard let data = UserDefaults.standard.data(forKey: "src.gamestate.v1") else { return nil }
        do {
            return try JSONDecoder().decode(GameState.self, from: data)
        } catch {
            // decode-failure → safe defaults
            return nil
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(state)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            // ignore encode failures silently
        }
    }

    func resetProgress() {
        // wipe all src.* keys
        let d = UserDefaults.standard
        for key in d.dictionaryRepresentation().keys where key.hasPrefix("src.") {
            d.removeObject(forKey: key)
        }
        state = GameState.newGame()
        lastResult = nil
        save()
    }

    // MARK: Logging
    func log(_ text: String, kind: String = "system") {
        state.log.insert(LogEntry(cycle: state.cycle, text: text, kindRaw: kind), at: 0)
        if state.log.count > 200 { state.log.removeLast(state.log.count - 200) }
    }

    // MARK: Metric bump
    func bump(_ m: ObjectiveMetric, _ amount: Double) {
        state.stats[m.rawValue, default: 0] += amount
    }

    // MARK: Cluster-wide spend helper (deduct across systems, home first)
    /// returns true if affordable & spent
    func canAfford(_ cost: [ResourceID: Double]) -> Bool {
        for (r, amt) in cost where amt > 0 {
            if state.totalStock(r) < amt - 0.0001 { return false }
        }
        return true
    }

    @discardableResult
    func spend(_ cost: [ResourceID: Double]) -> Bool {
        guard canAfford(cost) else { return false }
        for (r, amt) in cost where amt > 0 {
            var remaining = amt
            // deduct home (0) first, then others
            let order = [0] + state.systems.map { $0.id }.filter { $0 != 0 }
            for sid in order {
                if remaining <= 0.0001 { break }
                state.updateSys(sid) { s in
                    let have = s.stockOf(r)
                    let take = min(have, remaining)
                    if take > 0 {
                        s.stock[r.rawValue] = have - take
                        remaining -= take
                    }
                }
            }
        }
        return true
    }

    /// add to home stockpile
    func credit(_ r: ResourceID, _ amount: Double, to system: Int = 0) {
        guard amount > 0 else { return }
        state.updateSys(system) { s in
            s.stock[r.rawValue, default: 0] += amount
        }
    }

    // MARK: Survey & claim
    func surveyCost(_ id: Int) -> Double { Galaxy.system(id).surveyCost }

    func canSurvey(_ id: Int) -> Bool {
        guard let s = state.sys(id), !s.surveyed else { return false }
        // must be adjacent to a claimed system
        let neighborsClaimed = Galaxy.neighbors(id).contains { nb in state.sys(nb)?.claimed == true }
        return neighborsClaimed && canAfford([.credits: surveyCost(id)])
    }
    func isReachable(_ id: Int) -> Bool {
        Galaxy.neighbors(id).contains { nb in state.sys(nb)?.claimed == true }
    }

    func survey(_ id: Int) {
        guard canSurvey(id) else { return }
        spend([.credits: surveyCost(id)])
        state.updateSys(id) { $0.surveyed = true }
        log("Surveyed \(Galaxy.system(id).name).", kind: "system")
        save()
    }

    func claimCost(_ id: Int) -> [ResourceID: Double] {
        let def = Galaxy.system(id)
        let disc = def.trait == .derelict ? 0.7 : 1.0
        return [.credits: 100 * disc, .alloy: 30 * disc]
    }
    func canClaim(_ id: Int) -> Bool {
        guard let s = state.sys(id), s.surveyed, !s.claimed else { return false }
        let def = Galaxy.system(id)
        return state.commandTier >= def.claimTier && canAfford(claimCost(id))
    }

    func claim(_ id: Int) {
        guard canClaim(id) else { return }
        spend(claimCost(id))
        state.updateSys(id) { s in
            s.claimed = true
            if s.stock.isEmpty { s.stock[ResourceID.credits.rawValue] = 0 }
        }
        log("Claimed \(Galaxy.system(id).name). The network grows.", kind: "system")
        recomputeTier()
        checkObjectives()
        checkAchievements()
        save()
    }

    // MARK: Build / upgrade
    func canBuild(_ type: ModuleType, in system: Int) -> Bool {
        guard let s = state.sys(system), s.claimed else { return false }
        if let req = type.requiresTech, !state.unlockedTech.contains(req) { return false }
        if state.commandTier < type.minTier { return false }
        return canAfford(ModuleCost.buildCost(type))
    }
    func buildReason(_ type: ModuleType, in system: Int) -> String? {
        guard let s = state.sys(system), s.claimed else { return "Claim this system first" }
        if let req = type.requiresTech, !state.unlockedTech.contains(req) {
            return "Needs research: \(ResearchTree.node(req)?.name ?? req)"
        }
        if state.commandTier < type.minTier {
            return "Needs Command Tier \(type.minTier + 1)"
        }
        if !canAfford(ModuleCost.buildCost(type)) { return "Not enough resources" }
        return nil
    }

    func build(_ type: ModuleType, in system: Int) {
        guard canBuild(type, in: system) else { return }
        spend(ModuleCost.buildCost(type))
        state.updateSys(system) { $0.modules.append(BuiltModule(type: type)) }
        bump(.modulesBuilt, 1)
        log("Built \(type.name) at \(Galaxy.system(system).name).", kind: "system")
        checkAchievements(); checkObjectives()
        save()
    }

    func canUpgrade(_ m: BuiltModule) -> Bool {
        guard ModuleCost.canUpgrade(m) else { return false }
        return canAfford(ModuleCost.upgradeCost(m))
    }

    func upgrade(_ moduleId: UUID, in system: Int) {
        guard let s = state.sys(system), let m = s.modules.first(where: { $0.id == moduleId }) else { return }
        guard canUpgrade(m) else { return }
        spend(ModuleCost.upgradeCost(m))
        state.updateSys(system) { st in
            if let i = st.modules.firstIndex(where: { $0.id == moduleId }) {
                st.modules[i] = ModuleCost.applyUpgrade(st.modules[i])
            }
        }
        log("Upgraded \(m.type.name) at \(Galaxy.system(system).name).", kind: "system")
        checkAchievements()
        save()
    }

    // MARK: Research
    func canStartResearch(_ nodeId: String) -> Bool {
        guard state.activeResearch == nil else { return false }
        guard !state.unlockedTech.contains(nodeId) else { return false }
        guard let node = ResearchTree.node(nodeId) else { return false }
        for p in node.prereqs where !state.unlockedTech.contains(p) { return false }
        return canAfford([.credits: node.creditCost])
    }
    func researchPrereqsMet(_ nodeId: String) -> Bool {
        guard let node = ResearchTree.node(nodeId) else { return false }
        return node.prereqs.allSatisfy { state.unlockedTech.contains($0) }
    }

    func startResearch(_ nodeId: String) {
        guard canStartResearch(nodeId), let node = ResearchTree.node(nodeId) else { return }
        spend([.credits: node.creditCost])
        state.activeResearch = ActiveResearch(nodeId: nodeId, progress: 0)
        log("Research begun: \(node.name).", kind: "system")
        save()
    }

    // MARK: Convoys
    func buildConvoy(at system: Int) {
        let cost: [ResourceID: Double] = [.alloy: 50, .components: 20, .fuel: 20, .credits: 120]
        guard let s = state.sys(system), s.claimed,
              s.modules.contains(where: { $0.type == .shipyard }),
              canAfford(cost) else { return }
        spend(cost)
        state.convoyCounter += 1
        let conv = Convoy(name: "Convoy \(state.convoyCounter)", routeId: nil, currentSystem: system)
        state.convoys.append(conv)
        bump(.convoysBuilt, 1)
        log("Commissioned \(conv.name) at \(Galaxy.system(system).name).", kind: "system")
        checkAchievements(); checkObjectives()
        save()
    }

    func canBuildConvoyAnywhere() -> Bool {
        state.systems.contains { $0.claimed && $0.modules.contains { $0.type == .shipyard } }
    }
    func shipyardSystems() -> [Int] {
        state.systems.filter { $0.claimed && $0.modules.contains { $0.type == .shipyard } }.map { $0.id }
    }

    func addRoute(origin: Int, destination: Int, resource: ResourceID, amount: Double, loop: Bool) {
        let route = CargoRoute(origin: origin, destination: destination,
                               resource: resource.rawValue, amountPerRun: amount, loop: loop)
        state.routes.append(route)
        log("Route set: \(resource.short) \(Galaxy.system(origin).name) → \(Galaxy.system(destination).name).", kind: "system")
        save()
    }

    func assignConvoy(_ convoyId: UUID, to routeId: UUID) {
        guard let route = state.routes.first(where: { $0.id == routeId }) else { return }
        if let i = state.convoys.firstIndex(where: { $0.id == convoyId }) {
            state.convoys[i].routeId = routeId
            state.convoys[i].idle = false
            state.convoys[i].headingToDest = true
            state.convoys[i].currentSystem = route.origin
            state.convoys[i].pathNodes = []
            state.convoys[i].legIndex = 0
            state.convoys[i].hopProgress = 0
            state.convoys[i].carrying = 0
        }
        save()
    }
    func unassignConvoy(_ convoyId: UUID) {
        if let i = state.convoys.firstIndex(where: { $0.id == convoyId }) {
            state.convoys[i].routeId = nil
            state.convoys[i].idle = true
            state.convoys[i].carrying = 0
        }
        save()
    }
    func deleteRoute(_ routeId: UUID) {
        state.routes.removeAll { $0.id == routeId }
        for i in state.convoys.indices where state.convoys[i].routeId == routeId {
            state.convoys[i].routeId = nil
            state.convoys[i].idle = true
            state.convoys[i].carrying = 0
        }
        save()
    }

    // MARK: Tier recompute
    func recomputeTier() {
        var newTier = state.commandTier
        for tier in Tiers.ladder {
            if state.claimedCount >= tier.claimedRequired &&
                state.metric(.alloyRefined) >= tier.alloyRequired {
                newTier = max(newTier, tier.id)
            }
        }
        if newTier != state.commandTier {
            state.commandTier = newTier
            log("Promoted to \(Tiers.tier(newTier).name)!", kind: "system")
        }
    }

    // MARK: Objectives & achievements
    /// keep derived metrics (claimed-system count) in sync with live state
    private func syncDerivedMetrics() {
        state.stats[ObjectiveMetric.claimedSystems.rawValue] = Double(state.claimedCount)
    }

    func checkObjectives() {
        syncDerivedMetrics()
        for o in Objectives.all where !state.completedObjectives.contains(o.id) {
            if state.metric(o.metric) >= o.target {
                state.completedObjectives.insert(o.id)
                credit(.credits, o.reward)
                log("Objective complete: \(o.title) (+\(Fmt.compact(o.reward)) CR).", kind: "system")
            }
        }
    }
    func checkAchievements() {
        syncDerivedMetrics()
        for a in Achievements.all where !state.unlockedAchievements.contains(a.id) {
            if state.metric(a.metric) >= a.target {
                state.unlockedAchievements.insert(a.id)
                log("Achievement unlocked: \(a.title).", kind: "system")
            }
        }
    }

    // MARK: Event choice resolution
    func resolveEvent(_ choiceIndex: Int) {
        guard let eid = state.pendingEventId, let ev = EventCatalog.event(eid),
              choiceIndex < ev.choices.count else {
            state.pendingEventId = nil; return
        }
        let c = ev.choices[choiceIndex]
        applyEventChoice(c)
        log("\(ev.title): \(c.resultText)", kind: ev.kind.rawValue)
        state.pendingEventId = nil
        checkAchievements(); checkObjectives(); recomputeTier()
        save()
    }

    private func applyEventChoice(_ c: EventChoiceDef) {
        func adjust(_ r: ResourceID, _ amt: Double) {
            if amt > 0 { credit(r, amt) }
            else if amt < 0 { spend([r: -amt]) }
        }
        adjust(.credits, c.credits)
        adjust(.alloy, c.alloy)
        adjust(.fuel, c.fuel)
        adjust(.components, c.components)
        adjust(.isotope, c.isotope)
        adjust(.food, c.food)
        if c.research > 0, var ar = state.activeResearch {
            ar.progress += c.research
            state.activeResearch = ar
        } else if c.research > 0 {
            // no active project: bank a small credit equivalent
            credit(.credits, c.research)
        }
        if c.powerPenaltyCycles > 0 { state.powerPenaltyCycles = max(state.powerPenaltyCycles, c.powerPenaltyCycles) }
        if c.raidsRepelled > 0 { bump(.raidsRepelled, Double(c.raidsRepelled)) }
        if c.credits > 0 { bump(.creditsEarned, c.credits) }
    }
}
