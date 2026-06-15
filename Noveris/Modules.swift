import SwiftUI

// MARK: - Module types (10)
enum ModuleType: String, Codable, CaseIterable, Hashable {
    case habitat
    case power
    case mining
    case refinery
    case fabricator
    case cargoHub
    case shipyard
    case research
    case market
    case defense

    var name: String {
        switch self {
        case .habitat: return "Habitat"
        case .power: return "Power Plant"
        case .mining: return "Mining Rig"
        case .refinery: return "Refinery"
        case .fabricator: return "Fabricator"
        case .cargoHub: return "Cargo Hub"
        case .shipyard: return "Shipyard"
        case .research: return "Research Lab"
        case .market: return "Trade Post"
        case .defense: return "Defense Array"
        }
    }
    var blurb: String {
        switch self {
        case .habitat: return "Houses population, producing Labor and consuming Food."
        case .power: return "Generates Power for every running module in the system."
        case .mining: return "Extracts the system's native ore each cycle (needs power+labor)."
        case .refinery: return "Transforms ore into Alloys and Fuel."
        case .fabricator: return "Builds Components from Alloys and Cuprite."
        case .cargoHub: return "Raises convoy capacity and local stockpile ceilings."
        case .shipyard: return "Constructs convoy ships from Alloys, Components and Fuel."
        case .research: return "Generates Research points toward the active project."
        case .market: return "Sells surplus stockpiles for Credits in populated systems."
        case .defense: return "Protects the system and nearby lanes from raider events."
        }
    }
    var icon: ResIconKind? { // used for some; others have dedicated icon view
        switch self {
        case .habitat: return .people
        case .power: return .power
        case .refinery: return .alloy
        case .fabricator: return .component
        case .market: return .credit
        default: return nil
        }
    }
    var accent: Color {
        switch self {
        case .habitat: return Brand.teal
        case .power: return Brand.amber
        case .mining: return Brand.violet
        case .refinery: return Brand.cyan
        case .fabricator: return Brand.cyan
        case .cargoHub: return Brand.green
        case .shipyard: return Brand.green
        case .research: return Brand.violet
        case .market: return Brand.amber
        case .defense: return Brand.red
        }
    }
    /// research node id required before this module can be built (nil = available from start)
    var requiresTech: String? {
        switch self {
        case .habitat, .power, .mining: return nil
        case .refinery: return "t_refining"
        case .cargoHub: return "t_logistics"
        case .market: return "t_trade"
        case .shipyard: return "t_shipbuild"
        case .fabricator: return "t_fabrication"
        case .research: return "t_science"
        case .defense: return "t_defense"
        }
    }
    /// minimum command tier (0-indexed rank) to build
    var minTier: Int {
        switch self {
        case .habitat, .power, .mining: return 0
        case .refinery, .cargoHub: return 0
        case .market, .shipyard: return 1
        case .fabricator, .research: return 1
        case .defense: return 2
        }
    }

    static let buildOrder: [ModuleType] = [
        .habitat, .power, .mining, .refinery, .fabricator,
        .cargoHub, .shipyard, .research, .market, .defense
    ]
}

// MARK: - Tier names
let tierNames = ["Mk I", "Mk II", "Mk III", "Mk IV"]

// MARK: - Built module instance
struct BuiltModule: Codable, Hashable, Identifiable {
    var id = UUID()
    var type: ModuleType
    var tier: Int      // 0..3
    var level: Int     // 1..N upgrade level within tier influence

    init(type: ModuleType, tier: Int = 0, level: Int = 1) {
        self.type = type; self.tier = tier; self.level = level
    }

    /// scalar that scales output/draw/cost with tier and level
    var scale: Double {
        let tierMult = pow(1.85, Double(tier))
        let levelMult = 1.0 + 0.35 * Double(level - 1)
        return tierMult * levelMult
    }

    // Base power draw (negative for power plants = generation)
    var powerFlow: Double {
        switch type {
        case .power: return 18.0 * scale          // generates
        default:
            let base: Double = {
                switch type {
                case .habitat: return 4
                case .mining: return 6
                case .refinery: return 8
                case .fabricator: return 9
                case .cargoHub: return 2
                case .shipyard: return 5
                case .research: return 7
                case .market: return 3
                case .defense: return 6
                case .power: return 0
                }
            }()
            return -base * scale                    // consumes
        }
    }

    // Labor: positive = produced (habitat), negative = required
    var laborFlow: Double {
        switch type {
        case .habitat: return 10.0 * scale
        default:
            let base: Double = {
                switch type {
                case .mining: return 5
                case .refinery: return 4
                case .fabricator: return 5
                case .cargoHub: return 2
                case .shipyard: return 4
                case .research: return 5
                case .market: return 3
                case .defense: return 3
                default: return 0
                }
            }()
            return -base * scale
        }
    }

    var foodConsumption: Double {
        type == .habitat ? 6.0 * scale : 0
    }

    var cargoCapacityBonus: Double {
        type == .cargoHub ? 40.0 * scale : 0
    }

    var researchOutput: Double {
        type == .research ? 5.0 * scale : 0
    }

    var defenseRating: Double {
        type == .defense ? 8.0 * scale : 0
    }

    var displayName: String { "\(type.name) \(tierNames[min(tier,3)])" }
}

// MARK: - Build & upgrade costs
enum ModuleCost {
    /// cost to build a fresh module of given type at tier 0 level 1
    static func buildCost(_ type: ModuleType) -> [ResourceID: Double] {
        switch type {
        case .habitat:    return [.credits: 120, .alloy: 20]
        case .power:      return [.credits: 140, .alloy: 25]
        case .mining:     return [.credits: 100, .alloy: 18]
        case .refinery:   return [.credits: 200, .alloy: 40, .components: 8]
        case .fabricator: return [.credits: 320, .alloy: 60, .components: 18]
        case .cargoHub:   return [.credits: 180, .alloy: 35]
        case .shipyard:   return [.credits: 360, .alloy: 70, .components: 24]
        case .research:   return [.credits: 280, .alloy: 50, .components: 16]
        case .market:     return [.credits: 220, .alloy: 30, .components: 6]
        case .defense:    return [.credits: 300, .alloy: 55, .components: 20]
        }
    }

    /// cost to upgrade a level (scales with current level), or tier-up at level 4
    static func upgradeCost(_ m: BuiltModule) -> [ResourceID: Double] {
        let base = buildCost(m.type)
        let mult = 0.6 * m.scale * (m.level >= 4 ? 1.8 : 1.0) // tier-up is pricier
        var out: [ResourceID: Double] = [:]
        for (k, v) in base { out[k] = (v * mult).rounded() }
        // tier-ups also need isotopes from Mk II onward
        if m.level >= 4 && m.tier >= 1 {
            out[.isotope, default: 0] += Double(m.tier) * 12
        }
        return out
    }

    /// applying an upgrade: returns the resulting module (level up, or tier up resetting level)
    static func applyUpgrade(_ m: BuiltModule) -> BuiltModule {
        var r = m
        if m.level >= 4 && m.tier < 3 {
            r.tier += 1
            r.level = 1
        } else if m.level < 4 {
            r.level += 1
        }
        return r
    }

    static func canUpgrade(_ m: BuiltModule) -> Bool {
        !(m.tier >= 3 && m.level >= 4)
    }
}
