import SwiftUI

// MARK: - Per-system persisted state
struct SystemState: Codable, Hashable {
    var id: Int
    var surveyed: Bool = false
    var claimed: Bool = false
    var modules: [BuiltModule] = []
    // local stockpiles for stockpiled resources
    var stock: [String: Double] = [:]   // ResourceID.rawValue -> amount

    func stockOf(_ r: ResourceID) -> Double { stock[r.rawValue] ?? 0 }
}

// MARK: - Convoy & routes
struct CargoRoute: Codable, Hashable, Identifiable {
    var id = UUID()
    var origin: Int
    var destination: Int
    var resource: String        // ResourceID.rawValue (stockpiled only)
    var amountPerRun: Double
    var loop: Bool              // true: bounce back and forth; false: one-shot then idle at dest
}

struct Convoy: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var routeId: UUID?
    var currentSystem: Int          // node currently at (when not mid-lane)
    var pathNodes: [Int] = []       // current planned node path
    var legIndex: Int = 0           // which lane segment of path we're traversing (0-based)
    var hopProgress: Int = 0        // hops completed on current lane
    var carrying: Double = 0        // amount loaded
    var carryingResource: String = ""
    var headingToDest: Bool = true  // direction along route
    var idle: Bool = true
}

// MARK: - Active research project
struct ActiveResearch: Codable, Hashable {
    var nodeId: String
    var progress: Double    // research points accumulated
}

// MARK: - Top-level persisted game state (single Codable blob)
struct GameState: Codable {
    var version: Int = 1
    var cycle: Int = 0
    var commandTier: Int = 0

    var systems: [SystemState] = []
    var convoys: [Convoy] = []
    var routes: [CargoRoute] = []

    var unlockedTech: Set<String> = []
    var activeResearch: ActiveResearch? = nil
    var researchCompletedCount: Int = 0

    var log: [LogEntry] = []
    var pendingEventId: String? = nil    // event awaiting player choice from last cycle

    // power penalty cycles remaining (from flare events)
    var powerPenaltyCycles: Int = 0

    // lifetime stats / metrics
    var stats: [String: Double] = [:]   // ObjectiveMetric.rawValue -> value
    var completedObjectives: Set<String> = []
    var unlockedAchievements: Set<String> = []
    var convoyCounter: Int = 0

    var onboardingDone: Bool = false

    // stockpile history for dashboard charts (ring buffer, per resource -> last N totals)
    var history: [String: [Double]] = [:]   // ResourceID.rawValue -> series
    var creditHistory: [Double] = []

    func metric(_ m: ObjectiveMetric) -> Double { stats[m.rawValue] ?? 0 }

    // MARK: New-game factory
    static func newGame() -> GameState {
        var g = GameState()
        g.systems = Galaxy.systems.map { SystemState(id: $0.id) }
        // Home system pre-claimed with starter modules + starting stock
        if let homeIdx = g.systems.firstIndex(where: { $0.id == 0 }) {
            g.systems[homeIdx].surveyed = true
            g.systems[homeIdx].claimed = true
            g.systems[homeIdx].modules = [
                BuiltModule(type: .habitat, tier: 0, level: 1),
                BuiltModule(type: .power, tier: 0, level: 1),
                BuiltModule(type: .mining, tier: 0, level: 1),
            ]
            g.systems[homeIdx].stock = [
                ResourceID.credits.rawValue: 500,
                ResourceID.ferrite.rawValue: 60,
                ResourceID.cuprite.rawValue: 30,
                ResourceID.silicate.rawValue: 30,
                ResourceID.alloy.rawValue: 80,
                ResourceID.fuel.rawValue: 40,
                ResourceID.components.rawValue: 30,
                ResourceID.food.rawValue: 60,
                ResourceID.isotope.rawValue: 0,
            ]
        }
        return g
    }

    // MARK: Aggregate helpers (treat credits/components etc. as cluster-wide pooled for spending UX)
    func totalStock(_ r: ResourceID) -> Double {
        systems.reduce(0) { $0 + $1.stockOf(r) }
    }

    var claimedCount: Int { systems.filter { $0.claimed }.count }
    var surveyedCount: Int { systems.filter { $0.surveyed }.count }

    func sys(_ id: Int) -> SystemState? { systems.first { $0.id == id } }
    mutating func updateSys(_ id: Int, _ f: (inout SystemState) -> Void) {
        if let i = systems.firstIndex(where: { $0.id == id }) { f(&systems[i]) }
    }
}
