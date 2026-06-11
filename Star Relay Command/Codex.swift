import SwiftUI

// MARK: - Codex categories
enum CodexCategory: String, CaseIterable, Identifiable {
    case modules, resources, systems, anomalies
    var id: String { rawValue }
    var title: String {
        switch self {
        case .modules: return "Modules"
        case .resources: return "Resources"
        case .systems: return "Star Systems"
        case .anomalies: return "Anomalies"
        }
    }
}

struct CodexEntry: Identifiable {
    let id: String
    let title: String
    let body: String
    let accent: Color
}

enum Codex {
    static func entries(for cat: CodexCategory) -> [CodexEntry] {
        switch cat {
        case .modules:
            return ModuleType.buildOrder.map { t in
                CodexEntry(id: "m_\(t.rawValue)", title: t.name, body: moduleLore(t), accent: t.accent)
            }
        case .resources:
            return ResourceID.allCases.map { r in
                CodexEntry(id: "r_\(r.rawValue)", title: r.name, body: r.lore, accent: r.color)
            }
        case .systems:
            return SystemTrait.allCases.map { tr in
                CodexEntry(id: "s_\(tr.rawValue)", title: tr.label + " Systems", body: tr.blurb + " " + traitDetail(tr), accent: tr.color)
            }
        case .anomalies:
            // unique by kind
            var seen = Set<String>()
            var out: [CodexEntry] = []
            for e in EventCatalog.all {
                let k = e.kind.rawValue
                if seen.contains(k) { continue }
                seen.insert(k)
                out.append(CodexEntry(id: "a_\(k)", title: anomalyTitle(e.kind), body: anomalyLore(e.kind), accent: anomalyColor(e.kind)))
            }
            return out
        }
    }

    static func moduleLore(_ t: ModuleType) -> String {
        let extra: String
        switch t {
        case .habitat: extra = "Population grows slowly with surplus food and provides the labor every other module needs to run."
        case .power: extra = "Without enough power, modules throttle down — a power deficit is the most common cause of stalled production."
        case .mining: extra = "Yields scale with the system's resource trait; only hazardous systems yield rare isotopes."
        case .refinery: extra = "The heart of the supply chain: ferrite and cuprite become alloys, silicate becomes fuel."
        case .fabricator: extra = "Components gate every advanced module and convoy ship. Build a steady fabrication base early."
        case .cargoHub: extra = "Raises how much each system can stockpile and how much a convoy can carry per run."
        case .shipyard: extra = "Convoy ships are built here from alloys, components and fuel, then assigned to routes on the map."
        case .research: extra = "More labs mean faster research, compounding every other system over time."
        case .market: extra = "Only effective in populated systems, where demand turns your surplus into credits."
        case .defense: extra = "A defended system and its lanes shrug off raids that would cripple an unguarded outpost."
        }
        return t.blurb + " " + extra + " Four tiers (Mk I–IV) and per-tier upgrade levels multiply output, power draw and upkeep."
    }

    static func traitDetail(_ tr: SystemTrait) -> String {
        switch tr {
        case .resourceRich: return "Mining rigs here return roughly 60% more ore."
        case .hazardous: return "These are the only systems that yield rare isotopes, but raids and flares strike more often."
        case .populated: return "Trade Posts thrive here, and habitats find ready labor — but the worlds demand more food."
        case .derelict: return "Salvage anomalies are common, and claiming costs a little less."
        case .balanced: return "No bonuses, no penalties — reliable backbone systems for your network."
        }
    }

    static func anomalyTitle(_ k: EventKind) -> String {
        switch k {
        case .solarFlare: return "Solar Flares"
        case .salvage: return "Derelict Salvage"
        case .raid: return "Raider Fleets"
        case .artifact: return "Alien Artifacts"
        case .tradeBoom: return "Market Swings"
        case .plague: return "Habitat Plagues"
        case .isotopeSurge: return "Isotope Surges"
        case .driftAnomaly: return "Drift Anomalies"
        case .neutral: return "Windfalls"
        }
    }
    static func anomalyColor(_ k: EventKind) -> Color {
        switch k {
        case .solarFlare, .isotopeSurge: return Brand.amber
        case .raid, .plague: return Brand.red
        case .artifact, .driftAnomaly: return Brand.violet
        case .salvage, .neutral: return Brand.green
        case .tradeBoom: return Brand.teal
        }
    }
    static func anomalyLore(_ k: EventKind) -> String {
        switch k {
        case .solarFlare: return "Stellar flares overload reactors. Shunt the surge to throttle power briefly, or vent fuel to ground it safely."
        case .salvage: return "Drifting wrecks reward bold crews with alloys or rare data cores for research."
        case .raid: return "Raiders prey on cargo lanes. Defense Arrays repel them; an undefended network pays in lost goods or tribute."
        case .artifact: return "Artifacts of unknown make offer a choice between research insight and a quick sale to collectors."
        case .tradeBoom: return "Demand and prices swing across populated worlds. Read the market and ship surplus at the right moment."
        case .plague: return "Outbreaks sap a habitat's workforce. Quarantine with med components or ration through it."
        case .isotopeSurge: return "Hazardous cores flare open seams of rare isotopes — a risky but rich mining opportunity."
        case .driftAnomaly: return "Gravitational eddies bend relay lanes. Chart them for research or reroute around them."
        case .neutral: return "Not every cycle brings danger — sometimes a friendly settlement simply lends a hand."
        }
    }
}
