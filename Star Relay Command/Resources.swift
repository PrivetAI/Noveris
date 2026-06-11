import SwiftUI

// MARK: - Resources (~12)
enum ResourceID: String, Codable, CaseIterable, Hashable {
    case credits
    case ferrite      // common ore
    case cuprite      // conductive ore
    case silicate     // refining ore
    case isotope      // rare isotopes (mined in hazardous systems)
    case alloy        // refined from ferrite+cuprite
    case fuel         // refined from silicate
    case components   // fabricated from alloy+cuprite
    case food         // produced by habitats/agri
    case power        // produced/consumed (not stockpiled, flow)
    case labor        // population-derived (flow)
    case research     // research points (flow into projects)

    var name: String {
        switch self {
        case .credits: return "Credits"
        case .ferrite: return "Ferrite Ore"
        case .cuprite: return "Cuprite Ore"
        case .silicate: return "Silicate Ore"
        case .isotope: return "Rare Isotopes"
        case .alloy: return "Alloys"
        case .fuel: return "Fuel"
        case .components: return "Components"
        case .food: return "Food"
        case .power: return "Power"
        case .labor: return "Labor"
        case .research: return "Research"
        }
    }
    var short: String {
        switch self {
        case .credits: return "CR"
        case .ferrite: return "FE"
        case .cuprite: return "CU"
        case .silicate: return "SI"
        case .isotope: return "ISO"
        case .alloy: return "ALY"
        case .fuel: return "FUL"
        case .components: return "CMP"
        case .food: return "FD"
        case .power: return "PWR"
        case .labor: return "LBR"
        case .research: return "RSC"
        }
    }
    /// flow resources are not stockpiled across cycles
    var isFlow: Bool {
        switch self {
        case .power, .labor, .research: return true
        default: return false
        }
    }
    var stockpiled: Bool { !isFlow }

    var color: Color {
        switch self {
        case .credits: return Brand.amber
        case .ferrite: return Color(red: 0.78, green: 0.55, blue: 0.45)
        case .cuprite: return Color(red: 0.55, green: 0.80, blue: 0.95)
        case .silicate: return Color(red: 0.70, green: 0.75, blue: 0.85)
        case .isotope: return Brand.violet
        case .alloy: return Brand.teal
        case .fuel: return Brand.amber
        case .components: return Brand.cyan
        case .food: return Brand.green
        case .power: return Brand.amber
        case .labor: return Brand.teal
        case .research: return Brand.violet
        }
    }
    var icon: ResIconKind {
        switch self {
        case .credits: return .credit
        case .ferrite, .cuprite, .silicate: return .ore
        case .isotope: return .isotope
        case .alloy: return .alloy
        case .fuel: return .fuel
        case .components: return .component
        case .food: return .food
        case .power: return .power
        case .labor: return .people
        case .research: return .ore
        }
    }

    var lore: String {
        switch self {
        case .credits: return "The cluster's settlement currency. Earned by selling surplus to populated markets and spent on construction, research, and convoys."
        case .ferrite: return "Iron-rich asteroid ore. The structural backbone of every station hull and the most abundant mineable resource."
        case .cuprite: return "Copper-bearing ore prized for its conductivity. Essential to alloys and high-grade components."
        case .silicate: return "Silicon-rich regolith refined into reaction fuel and habitat substrate. Common in rocky inner systems."
        case .isotope: return "Unstable rare isotopes found only in hazardous, radiation-bathed systems. Powers fusion plants and advanced research."
        case .alloy: return "Refined structural alloy. The primary build material for modules, cargo hubs, and convoy hulls."
        case .fuel: return "Refined reaction fuel. Convoys burn fuel per lane-hop; shipyards consume it during construction."
        case .components: return "Fabricated electronics and machinery. Required to construct and upgrade advanced modules and convoy ships."
        case .food: return "Synthesized and farmed rations. Habitats consume food every cycle; shortages cut population and labor."
        case .power: return "Reactor output. A per-cycle flow, not a stockpile. Every running module draws power; shortfall throttles production."
        case .labor: return "Working population capacity. A per-cycle flow from habitats. Modules need labor to operate at full output."
        case .research: return "Accumulated research output flowing into the active project from your labs."
        }
    }
}
