import SwiftUI

// MARK: - Command Tier ladder (6 ranks)
struct CommandTier: Identifiable {
    let id: Int
    let name: String
    let claimedRequired: Int      // claimed systems to reach
    let alloyRequired: Double     // lifetime alloys refined
    let blurb: String
}

enum Tiers {
    static let ladder: [CommandTier] = [
        CommandTier(id: 0, name: "Outpost Warden",     claimedRequired: 0,  alloyRequired: 0,     blurb: "A single outpost and a dream of a network."),
        CommandTier(id: 1, name: "Relay Captain",      claimedRequired: 3,  alloyRequired: 200,   blurb: "Your first lanes hum with cargo."),
        CommandTier(id: 2, name: "Sector Commander",   claimedRequired: 6,  alloyRequired: 1500,  blurb: "A sector answers to your command."),
        CommandTier(id: 3, name: "Cluster Marshal",    claimedRequired: 10, alloyRequired: 6000,  blurb: "Half the cluster flies your colors."),
        CommandTier(id: 4, name: "Star Overseer",      claimedRequired: 15, alloyRequired: 20000, blurb: "The deep systems open to your fleets."),
        CommandTier(id: 5, name: "Cluster Sovereign",  claimedRequired: 22, alloyRequired: 75000, blurb: "The entire star cluster is your domain."),
    ]
    static func tier(_ i: Int) -> CommandTier { ladder[min(max(i,0), ladder.count-1)] }
}

// MARK: - Objectives (campaign, ~20)
enum ObjectiveMetric: String, Codable {
    case claimedSystems
    case modulesBuilt
    case alloyRefined
    case fuelRefined
    case componentsMade
    case creditsEarned
    case convoysBuilt
    case deliveries
    case researchDone
    case raidsRepelled
    case cyclesAdvanced
    case isotopeMined
}

struct Objective: Identifiable {
    let id: String
    let title: String
    let metric: ObjectiveMetric
    let target: Double
    let reward: Double            // credits
    let tierUnlock: Int           // min tier to display as active focus
}

enum Objectives {
    static let all: [Objective] = [
        Objective(id: "o_first_module", title: "Build your first module", metric: .modulesBuilt, target: 1, reward: 60, tierUnlock: 0),
        Objective(id: "o_claim3", title: "Claim 3 star systems", metric: .claimedSystems, target: 3, reward: 150, tierUnlock: 0),
        Objective(id: "o_refine200", title: "Refine 200 alloys", metric: .alloyRefined, target: 200, reward: 180, tierUnlock: 0),
        Objective(id: "o_build5", title: "Build 5 modules", metric: .modulesBuilt, target: 5, reward: 120, tierUnlock: 0),
        Objective(id: "o_research1", title: "Complete a research project", metric: .researchDone, target: 1, reward: 140, tierUnlock: 0),
        Objective(id: "o_convoy1", title: "Commission a convoy ship", metric: .convoysBuilt, target: 1, reward: 160, tierUnlock: 1),
        Objective(id: "o_deliver10", title: "Complete 10 convoy deliveries", metric: .deliveries, target: 10, reward: 220, tierUnlock: 1),
        Objective(id: "o_fuel500", title: "Refine 500 fuel", metric: .fuelRefined, target: 500, reward: 240, tierUnlock: 1),
        Objective(id: "o_claim6", title: "Claim 6 star systems", metric: .claimedSystems, target: 6, reward: 300, tierUnlock: 1),
        Objective(id: "o_components200", title: "Fabricate 200 components", metric: .componentsMade, target: 200, reward: 280, tierUnlock: 1),
        Objective(id: "o_credits5k", title: "Earn 5,000 credits from trade", metric: .creditsEarned, target: 5000, reward: 350, tierUnlock: 2),
        Objective(id: "o_research4", title: "Complete 4 research projects", metric: .researchDone, target: 4, reward: 320, tierUnlock: 2),
        Objective(id: "o_raid1", title: "Survive a raider attack", metric: .raidsRepelled, target: 1, reward: 300, tierUnlock: 2),
        Objective(id: "o_isotope100", title: "Mine 100 rare isotopes", metric: .isotopeMined, target: 100, reward: 380, tierUnlock: 2),
        Objective(id: "o_claim10", title: "Connect 10 systems", metric: .claimedSystems, target: 10, reward: 500, tierUnlock: 2),
        Objective(id: "o_alloy10k", title: "Refine 10,000 alloys", metric: .alloyRefined, target: 10000, reward: 600, tierUnlock: 3),
        Objective(id: "o_deliver100", title: "Complete 100 deliveries", metric: .deliveries, target: 100, reward: 650, tierUnlock: 3),
        Objective(id: "o_research10", title: "Complete 10 research projects", metric: .researchDone, target: 10, reward: 700, tierUnlock: 3),
        Objective(id: "o_claim15", title: "Claim 15 star systems", metric: .claimedSystems, target: 15, reward: 900, tierUnlock: 3),
        Objective(id: "o_raid5", title: "Repel 5 raider fleets", metric: .raidsRepelled, target: 5, reward: 800, tierUnlock: 4),
        Objective(id: "o_claim22", title: "Command 22 systems", metric: .claimedSystems, target: 22, reward: 1500, tierUnlock: 4),
        Objective(id: "o_research16", title: "Complete the research tree", metric: .researchDone, target: 16, reward: 2000, tierUnlock: 5),
    ]
}

// MARK: - Achievements (~24)
struct Achievement: Identifiable {
    let id: String
    let title: String
    let desc: String
    let metric: ObjectiveMetric
    let target: Double
}

enum Achievements {
    static let all: [Achievement] = [
        Achievement(id: "a_settle", title: "First Light", desc: "Build your first module.", metric: .modulesBuilt, target: 1),
        Achievement(id: "a_build10", title: "Architect", desc: "Build 10 modules.", metric: .modulesBuilt, target: 10),
        Achievement(id: "a_build30", title: "Master Builder", desc: "Build 30 modules.", metric: .modulesBuilt, target: 30),
        Achievement(id: "a_build60", title: "Cluster Engineer", desc: "Build 60 modules.", metric: .modulesBuilt, target: 60),
        Achievement(id: "a_claim3", title: "Pathfinder", desc: "Claim 3 systems.", metric: .claimedSystems, target: 3),
        Achievement(id: "a_claim8", title: "Trailblazer", desc: "Claim 8 systems.", metric: .claimedSystems, target: 8),
        Achievement(id: "a_claim15", title: "Cartographer", desc: "Claim 15 systems.", metric: .claimedSystems, target: 15),
        Achievement(id: "a_claim28", title: "Cluster Sovereign", desc: "Claim every system.", metric: .claimedSystems, target: 28),
        Achievement(id: "a_alloy1k", title: "Foundry", desc: "Refine 1,000 alloys.", metric: .alloyRefined, target: 1000),
        Achievement(id: "a_alloy25k", title: "Great Foundry", desc: "Refine 25,000 alloys.", metric: .alloyRefined, target: 25000),
        Achievement(id: "a_fuel5k", title: "Fuel Baron", desc: "Refine 5,000 fuel.", metric: .fuelRefined, target: 5000),
        Achievement(id: "a_comp2k", title: "Fabrications", desc: "Make 2,000 components.", metric: .componentsMade, target: 2000),
        Achievement(id: "a_iso500", title: "Isotope Hunter", desc: "Mine 500 isotopes.", metric: .isotopeMined, target: 500),
        Achievement(id: "a_convoy5", title: "Fleet Founder", desc: "Build 5 convoy ships.", metric: .convoysBuilt, target: 5),
        Achievement(id: "a_convoy15", title: "Logistics Lord", desc: "Build 15 convoy ships.", metric: .convoysBuilt, target: 15),
        Achievement(id: "a_deliver50", title: "Supply Line", desc: "Complete 50 deliveries.", metric: .deliveries, target: 50),
        Achievement(id: "a_deliver250", title: "Trade Empire", desc: "Complete 250 deliveries.", metric: .deliveries, target: 250),
        Achievement(id: "a_credits10k", title: "Merchant", desc: "Earn 10,000 trade credits.", metric: .creditsEarned, target: 10000),
        Achievement(id: "a_credits100k", title: "Tycoon", desc: "Earn 100,000 trade credits.", metric: .creditsEarned, target: 100000),
        Achievement(id: "a_research5", title: "Scholar", desc: "Complete 5 research projects.", metric: .researchDone, target: 5),
        Achievement(id: "a_research16", title: "Grand Scientist", desc: "Complete the research tree.", metric: .researchDone, target: 16),
        Achievement(id: "a_raid3", title: "Bulwark", desc: "Repel 3 raider fleets.", metric: .raidsRepelled, target: 3),
        Achievement(id: "a_raid10", title: "Warden of Lanes", desc: "Repel 10 raider fleets.", metric: .raidsRepelled, target: 10),
        Achievement(id: "a_cycle100", title: "Centurion", desc: "Advance 100 cycles.", metric: .cyclesAdvanced, target: 100),
        Achievement(id: "a_cycle500", title: "Timekeeper", desc: "Advance 500 cycles.", metric: .cyclesAdvanced, target: 500),
    ]
}
