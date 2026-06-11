import SwiftUI

// MARK: - Research node
struct ResearchNode: Identifiable {
    let id: String
    let name: String
    let prereqs: [String]
    let cost: Double          // research points required
    let creditCost: Double    // upfront credits to begin
    let blurb: String
    let column: Int           // for tree layout (tier/depth)
}

enum ResearchTree {
    /// Baseline research points generated every cycle by command staff,
    /// even with no Research Labs built (labs add on top of this).
    static let baseOutput: Double = 4

    // 16 nodes, acyclic. Roots have no prereqs.
    static let nodes: [ResearchNode] = [
        ResearchNode(id: "t_refining", name: "Ore Refining", prereqs: [], cost: 40, creditCost: 120,
            blurb: "Unlocks the Refinery module: turn ore into Alloys and Fuel.", column: 0),
        ResearchNode(id: "t_logistics", name: "Logistics Grid", prereqs: [], cost: 50, creditCost: 140,
            blurb: "Unlocks the Cargo Hub: raises convoy capacity and stockpile ceilings.", column: 0),
        ResearchNode(id: "t_science", name: "Applied Science", prereqs: [], cost: 60, creditCost: 160,
            blurb: "Unlocks the Research Lab to accelerate all future projects.", column: 0),

        ResearchNode(id: "t_trade", name: "Trade Charters", prereqs: ["t_logistics"], cost: 90, creditCost: 220,
            blurb: "Unlocks the Trade Post: sell surplus in populated systems for Credits.", column: 1),
        ResearchNode(id: "t_shipbuild", name: "Shipwright Doctrine", prereqs: ["t_refining"], cost: 110, creditCost: 260,
            blurb: "Unlocks the Shipyard: construct convoy ships to run cargo routes.", column: 1),
        ResearchNode(id: "t_fabrication", name: "Fabrication", prereqs: ["t_refining"], cost: 130, creditCost: 300,
            blurb: "Unlocks the Fabricator: build Components for advanced modules.", column: 1),

        ResearchNode(id: "t_efficiency", name: "Refining Efficiency", prereqs: ["t_refining", "t_science"], cost: 160, creditCost: 320,
            blurb: "+30% refinery output ratios cluster-wide.", column: 2),
        ResearchNode(id: "t_longlane", name: "Long-Range Relays", prereqs: ["t_logistics", "t_science"], cost: 180, creditCost: 360,
            blurb: "Opens gated long-range relay lanes to distant systems.", column: 2),
        ResearchNode(id: "t_defense", name: "Defense Systems", prereqs: ["t_fabrication"], cost: 200, creditCost: 380,
            blurb: "Unlocks the Defense Array to repel raider fleets.", column: 2),

        ResearchNode(id: "t_fastconvoy", name: "Convoy Drives", prereqs: ["t_shipbuild"], cost: 220, creditCost: 400,
            blurb: "Convoys travel one extra lane-hop progress per cycle.", column: 2),
        ResearchNode(id: "t_markets", name: "Market Networks", prereqs: ["t_trade"], cost: 240, creditCost: 420,
            blurb: "+40% credit yield from Trade Posts.", column: 3),
        ResearchNode(id: "t_deepmining", name: "Deep Extraction", prereqs: ["t_efficiency"], cost: 260, creditCost: 440,
            blurb: "+35% mining yields and richer isotope returns.", column: 3),
        ResearchNode(id: "t_anomaly", name: "Anomaly Sensors", prereqs: ["t_science", "t_defense"], cost: 300, creditCost: 480,
            blurb: "Better anomaly outcomes and early raider warnings.", column: 3),

        ResearchNode(id: "t_jumpcore", name: "Jump Cores", prereqs: ["t_longlane", "t_fastconvoy"], cost: 360, creditCost: 560,
            blurb: "Opens the deepest relay lanes to the cluster's edge systems.", column: 4),
        ResearchNode(id: "t_fusion", name: "Fusion Lattice", prereqs: ["t_deepmining", "t_efficiency"], cost: 420, creditCost: 620,
            blurb: "+50% power plant output, lowering energy bottlenecks.", column: 4),
        ResearchNode(id: "t_command", name: "Command Synthesis", prereqs: ["t_jumpcore", "t_fusion", "t_anomaly"], cost: 600, creditCost: 900,
            blurb: "Master doctrine: +20% to all module output cluster-wide.", column: 5),
    ]

    static func node(_ id: String) -> ResearchNode? { nodes.first { $0.id == id } }

    static var byId: [String: ResearchNode] {
        var d: [String: ResearchNode] = [:]
        for n in nodes { d[n.id] = n }
        return d
    }
}
