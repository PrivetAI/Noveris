import SwiftUI

// MARK: - System traits
enum SystemTrait: String, Codable, CaseIterable {
    case resourceRich   // higher mining yield
    case hazardous      // isotopes available, raider/flare risk up
    case populated      // demand/market, food draw, credit potential
    case derelict       // salvage events, claim bonus
    case balanced

    var label: String {
        switch self {
        case .resourceRich: return "Resource-Rich"
        case .hazardous: return "Hazardous"
        case .populated: return "Populated"
        case .derelict: return "Derelict"
        case .balanced: return "Balanced"
        }
    }
    var color: Color {
        switch self {
        case .resourceRich: return Brand.violet
        case .hazardous: return Brand.red
        case .populated: return Brand.teal
        case .derelict: return Brand.amber
        case .balanced: return Brand.cyan
        }
    }
    var blurb: String {
        switch self {
        case .resourceRich: return "Dense asteroid fields boost mining yields here."
        case .hazardous: return "Radiation and raiders. Rare isotopes can be mined, but risk runs high."
        case .populated: return "Settled worlds demand food and pay well for traded goods."
        case .derelict: return "Abandoned ruins drift here, ripe for salvage."
        case .balanced: return "An unremarkable but dependable system."
        }
    }
}

// MARK: - Static system definition (graph node)
struct StarSystemDef: Identifiable {
    let id: Int
    let name: String
    let trait: SystemTrait
    let nativeOre: ResourceID       // which ore the mining rig yields
    let pos: CGPoint                // normalized 0..1 position on map
    let surveyCost: Double          // credits to survey
    let claimTier: Int              // min command tier to claim
}

// MARK: - Relay lane (graph edge)
struct LaneDef: Hashable {
    let a: Int
    let b: Int
    let hops: Int                   // convoy travel cycles
    let requiresTech: String?       // gated lane
    let hazard: Double              // 0..1 base raider chance modifier
}

// MARK: - Galaxy catalog
enum Galaxy {
    static let systems: [StarSystemDef] = GalaxyData.systems
    static let lanes: [LaneDef] = GalaxyData.lanes

    static func system(_ id: Int) -> StarSystemDef { systems.first { $0.id == id }! }
    static func lanesFrom(_ id: Int) -> [LaneDef] { lanes.filter { $0.a == id || $0.b == id } }

    static func neighbors(_ id: Int) -> [Int] {
        lanes.compactMap { l in
            if l.a == id { return l.b }
            if l.b == id { return l.a }
            return nil
        }
    }

    static func lane(_ a: Int, _ b: Int) -> LaneDef? {
        lanes.first { ($0.a == a && $0.b == b) || ($0.a == b && $0.b == a) }
    }

    /// BFS shortest path (by hop-count of lanes, respecting unlocked tech set), returns ordered node list incl endpoints
    static func path(from: Int, to: Int, unlockedTech: Set<String>) -> [Int]? {
        if from == to { return [from] }
        var queue: [Int] = [from]
        var prev: [Int: Int] = [:]
        var visited: Set<Int> = [from]
        while !queue.isEmpty {
            let cur = queue.removeFirst()
            for l in lanesFrom(cur) {
                if let req = l.requiresTech, !unlockedTech.contains(req) { continue }
                let nxt = (l.a == cur) ? l.b : l.a
                if visited.contains(nxt) { continue }
                visited.insert(nxt)
                prev[nxt] = cur
                if nxt == to {
                    var pathNodes = [to]
                    var c = to
                    while let p = prev[c] { pathNodes.append(p); c = p }
                    return pathNodes.reversed()
                }
                queue.append(nxt)
            }
        }
        return nil
    }

    /// list of lane segments along a node path, in order
    static func laneHops(along path: [Int]) -> [LaneDef] {
        guard path.count >= 2 else { return [] }
        var out: [LaneDef] = []
        for i in 0..<(path.count - 1) {
            if let l = lane(path[i], path[i+1]) { out.append(l) }
        }
        return out
    }
}
