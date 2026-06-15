import SwiftUI

// MARK: - Event / anomaly definitions
enum EventKind: String, Codable {
    case solarFlare
    case salvage
    case raid
    case artifact
    case tradeBoom
    case plague
    case isotopeSurge
    case driftAnomaly
    case neutral
}

struct EventChoiceDef {
    let label: String
    let resultText: String
    // effects applied to game state when chosen
    let credits: Double
    let alloy: Double
    let fuel: Double
    let components: Double
    let isotope: Double
    let food: Double
    let research: Double
    let powerPenaltyCycles: Int   // cycles of reduced power
    let raidsRepelled: Int        // counts toward metric if defended

    init(label: String, resultText: String, credits: Double = 0, alloy: Double = 0,
         fuel: Double = 0, components: Double = 0, isotope: Double = 0, food: Double = 0,
         research: Double = 0, powerPenaltyCycles: Int = 0, raidsRepelled: Int = 0) {
        self.label = label; self.resultText = resultText
        self.credits = credits; self.alloy = alloy; self.fuel = fuel
        self.components = components; self.isotope = isotope; self.food = food
        self.research = research
        self.powerPenaltyCycles = powerPenaltyCycles; self.raidsRepelled = raidsRepelled
    }
}

struct EventDef: Identifiable {
    let id: String
    let kind: EventKind
    let title: String
    let body: String
    let choices: [EventChoiceDef]
}

enum EventCatalog {
    static let all: [EventDef] = [
        EventDef(id: "e_flare", kind: .solarFlare, title: "Solar Flare",
            body: "A stellar flare washes across your relay grid, threatening to overload reactors.",
            choices: [
                EventChoiceDef(label: "Shunt the surge (lose some power)", resultText: "Reactors throttled for two cycles, but no hardware lost.", powerPenaltyCycles: 2),
                EventChoiceDef(label: "Vent reaction fuel to ground it", resultText: "You burn fuel reserves to ground the surge.", fuel: -40)
            ]),
        EventDef(id: "e_salvage", kind: .salvage, title: "Derelict Salvage",
            body: "Survey drones find an intact derelict freighter drifting in the dark.",
            choices: [
                EventChoiceDef(label: "Strip it for alloys", resultText: "Your crews cut the hull down to its bones.", alloy: 120),
                EventChoiceDef(label: "Recover its data core", resultText: "Ancient navigation data feeds your labs.", research: 60)
            ]),
        EventDef(id: "e_raid", kind: .raid, title: "Raider Fleet Sighted",
            body: "A raider squadron probes one of your relay lanes, hunting for cargo.",
            choices: [
                EventChoiceDef(label: "Mobilize defense arrays", resultText: "Your arrays drive the raiders off. Lane secured.", raidsRepelled: 1),
                EventChoiceDef(label: "Pay them off in components", resultText: "A tribute of components buys quiet passage.", components: -30)
            ]),
        EventDef(id: "e_artifact", kind: .artifact, title: "Alien Artifact",
            body: "An anomaly resolves into a geometric artifact of unknown make.",
            choices: [
                EventChoiceDef(label: "Study it carefully", resultText: "Months of analysis yield a research windfall.", research: 90),
                EventChoiceDef(label: "Sell it to a collector", resultText: "A populated world pays handsomely for the curio.", credits: 400)
            ]),
        EventDef(id: "e_boom", kind: .tradeBoom, title: "Trade Boom",
            body: "Demand spikes across the populated worlds. Markets are paying premium rates.",
            choices: [
                EventChoiceDef(label: "Flood the market with surplus", resultText: "Your hubs ship out everything not bolted down.", credits: 320),
                EventChoiceDef(label: "Hold for better prices", resultText: "You wait — and pocket a smaller, safer gain.", credits: 120)
            ]),
        EventDef(id: "e_plague", kind: .plague, title: "Habitat Plague",
            body: "A microbial outbreak sweeps a habitat ring, sapping the workforce.",
            choices: [
                EventChoiceDef(label: "Quarantine and treat", resultText: "Med supplies cost components but population recovers.", components: -20),
                EventChoiceDef(label: "Ration food to slow it", resultText: "Lean rations stall the spread at a cost in stores.", food: -40)
            ]),
        EventDef(id: "e_isosurge", kind: .isotopeSurge, title: "Isotope Surge",
            body: "A hazardous system's core flares, exposing a rich seam of rare isotopes.",
            choices: [
                EventChoiceDef(label: "Mine the seam aggressively", resultText: "Risky drilling pays off with a rich isotope haul.", isotope: 60),
                EventChoiceDef(label: "Take a careful sample", resultText: "A cautious survey yields modest returns.", isotope: 20, research: 30)
            ]),
        EventDef(id: "e_drift", kind: .driftAnomaly, title: "Drift Anomaly",
            body: "Convoys report a gravitational eddy bending a relay lane.",
            choices: [
                EventChoiceDef(label: "Chart a path through it", resultText: "Your navigators map the eddy, banking research data.", research: 50),
                EventChoiceDef(label: "Reroute around it", resultText: "A safe detour costs a little fuel but spares your fleet.", fuel: -15)
            ]),
        EventDef(id: "e_windfall", kind: .neutral, title: "Supply Windfall",
            body: "A friendly settlement gifts your network a cache of refined goods.",
            choices: [
                EventChoiceDef(label: "Accept the cache", resultText: "Alloys and fuel join your stores.", alloy: 60, fuel: 60)
            ]),
        EventDef(id: "e_pirateambush", kind: .raid, title: "Lane Ambush",
            body: "Pirates spring an ambush on a lightly defended lane.",
            choices: [
                EventChoiceDef(label: "Send an armed escort", resultText: "Your escort scatters the pirates.", fuel: -20, raidsRepelled: 1),
                EventChoiceDef(label: "Abandon the cargo", resultText: "You cut losses and let the cargo go.", alloy: -40)
            ]),
        EventDef(id: "e_lab", kind: .artifact, title: "Abandoned Lab",
            body: "A derelict system hides a forgotten research station, still powered.",
            choices: [
                EventChoiceDef(label: "Reboot its archives", resultText: "Decades of stored work flow into your projects.", research: 110),
                EventChoiceDef(label: "Salvage its reactor", resultText: "Its fusion core and parts are stripped for use.", components: 40, isotope: 20)
            ]),
        EventDef(id: "e_market_crash", kind: .tradeBoom, title: "Market Correction",
            body: "Prices wobble across the cluster. A shrewd commander can still profit.",
            choices: [
                EventChoiceDef(label: "Buy low on components", resultText: "You stockpile cheap components for later.", credits: -100, components: 50),
                EventChoiceDef(label: "Sell into the panic", resultText: "You offload surplus before prices fall further.", credits: 180)
            ]),
    ]

    static func event(_ id: String) -> EventDef? { all.first { $0.id == id } }
}

// MARK: - Logged event entry (persisted)
struct LogEntry: Codable, Identifiable {
    var id = UUID()
    var cycle: Int
    var text: String
    var kindRaw: String   // EventKind raw or "system"
}
