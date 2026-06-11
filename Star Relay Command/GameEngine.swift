import SwiftUI

extension GameStore {

    // Global tech multipliers
    private func techMult(_ id: String, _ amount: Double) -> Double {
        state.unlockedTech.contains(id) ? amount : 1.0
    }

    /// Master cluster-wide output multiplier
    private var globalOutputMult: Double {
        techMult("t_command", 1.20)
    }

    // MARK: - Advance one cycle
    func advanceCycle() {
        var result = CycleResult(cycle: state.cycle + 1)
        state.cycle += 1

        // ---- 1. Per-system production / consumption ----
        for sIdx in state.systems.indices {
            guard state.systems[sIdx].claimed else { continue }
            runSystemProduction(systemIndex: sIdx, result: &result)
        }

        // ---- 2. Trade posts: sell surplus for credits ----
        runTrade(result: &result)

        // ---- 3. Research ----
        runResearch(result: &result)

        // ---- 4. Convoys move ----
        runConvoys(result: &result)

        // ---- 5. Power penalty decay ----
        if state.powerPenaltyCycles > 0 { state.powerPenaltyCycles -= 1 }

        // ---- 6. Tier / objectives / achievements ----
        recomputeTier()
        checkObjectives()
        bump(.cyclesAdvanced, 1)
        checkAchievements()

        // ---- 7. Random event (queued for player choice) ----
        maybeTriggerEvent(result: &result)

        // record current tier in result if it changed this cycle is handled in log already
        result.newTier = state.commandTier

        recordHistory()

        lastResult = result
        save()
    }

    private func recordHistory() {
        let tracked: [ResourceID] = [.alloy, .fuel, .components, .isotope, .food, .credits]
        for r in tracked {
            var series = state.history[r.rawValue] ?? []
            series.append(state.totalStock(r))
            if series.count > 40 { series.removeFirst(series.count - 40) }
            state.history[r.rawValue] = series
        }
        state.creditHistory = state.history[ResourceID.credits.rawValue] ?? []
    }

    // MARK: - System production
    private func runSystemProduction(systemIndex sIdx: Int, result: inout CycleResult) {
        let sysId = state.systems[sIdx].id
        let def = Galaxy.system(sysId)
        let modules = state.systems[sIdx].modules

        // Power supply/demand
        var powerGen = 0.0, powerDemand = 0.0
        var laborGen = 0.0, laborDemand = 0.0
        for m in modules {
            let pf = m.powerFlow
            if pf > 0 { powerGen += pf * (m.type == .power ? techMult("t_fusion", 1.50) : 1) }
            else { powerDemand += -pf }
            let lf = m.laborFlow
            if lf > 0 { laborGen += lf } else { laborDemand += -lf }
        }
        if state.powerPenaltyCycles > 0 { powerGen *= 0.5 }

        // throttle factor: if demand exceeds supply, modules run at ratio
        let powerRatio = powerDemand <= 0 ? 1.0 : min(1.0, powerGen / max(powerDemand, 0.0001))
        let laborRatio = laborDemand <= 0 ? 1.0 : min(1.0, laborGen / max(laborDemand, 0.0001))
        let runRatio = max(0.0, min(1.0, min(powerRatio, laborRatio)))

        result.powerBalance += (powerGen - powerDemand)
        result.laborBalance += (laborGen - laborDemand)

        // Food: habitats consume; deficit reduces effective run ratio a touch
        var foodDemand = 0.0
        for m in modules where m.type == .habitat { foodDemand += m.foodConsumption }
        let foodHave = state.systems[sIdx].stockOf(.food)
        var foodRatio = 1.0
        if foodDemand > 0 {
            if foodHave >= foodDemand {
                state.systems[sIdx].stock[ResourceID.food.rawValue] = foodHave - foodDemand
                result.consumed[.food, default: 0] += foodDemand
            } else {
                foodRatio = max(0.3, foodHave / max(foodDemand, 0.0001))
                result.consumed[.food, default: 0] += foodHave
                state.systems[sIdx].stock[ResourceID.food.rawValue] = 0
                result.notes.append("\(def.name): food shortage throttles labor")
            }
        }
        let effRatio = max(0.0, runRatio * (0.5 + 0.5 * foodRatio))

        // ---- Mining ----
        for m in modules where m.type == .mining {
            let traitMult = def.trait == .resourceRich ? 1.6 : (def.trait == .hazardous ? 1.0 : 1.0)
            let deepMult = techMult("t_deepmining", 1.35)
            let yield = 8.0 * m.scale * effRatio * traitMult * deepMult * globalOutputMult
            let ore = def.nativeOre
            addStock(sIdx, ore, yield, result: &result, produced: true)
            if ore == .isotope { bump(.isotopeMined, yield) }
            // trace yield of the other basic ores (25% of native rate) so cross-ore
            // recipes (alloys, components) stay solvable before convoys exist
            for trace in [ResourceID.ferrite, .cuprite, .silicate] where trace != ore {
                addStock(sIdx, trace, yield * 0.25, result: &result, produced: true)
            }
        }

        // ---- Habitat food production + slow population growth (modeled as food) ----
        for m in modules where m.type == .habitat {
            // habitats also farm a little food
            let farmed = 3.0 * m.scale * effRatio
            addStock(sIdx, .food, farmed, result: &result, produced: true)
        }

        // ---- Refinery: ore -> alloy & fuel ----
        for m in modules where m.type == .refinery {
            let effMult = techMult("t_efficiency", 1.30) * globalOutputMult
            let cap = 6.0 * m.scale * effRatio
            // Alloy from ferrite + cuprite
            let ferrite = state.systems[sIdx].stockOf(.ferrite)
            let cuprite = state.systems[sIdx].stockOf(.cuprite)
            let alloyRuns = min(cap, min(ferrite / 2.0, cuprite / 1.0))
            if alloyRuns > 0 {
                consumeStock(sIdx, .ferrite, alloyRuns * 2.0, result: &result)
                consumeStock(sIdx, .cuprite, alloyRuns * 1.0, result: &result)
                let alloyOut = alloyRuns * 1.5 * effMult
                addStock(sIdx, .alloy, alloyOut, result: &result, produced: true)
                bump(.alloyRefined, alloyOut)
            }
            // Fuel from silicate
            let silicate = state.systems[sIdx].stockOf(.silicate)
            let fuelRuns = min(cap, silicate / 2.0)
            if fuelRuns > 0 {
                consumeStock(sIdx, .silicate, fuelRuns * 2.0, result: &result)
                let fuelOut = fuelRuns * 1.6 * effMult
                addStock(sIdx, .fuel, fuelOut, result: &result, produced: true)
                bump(.fuelRefined, fuelOut)
            }
        }

        // ---- Fabricator: alloy + cuprite -> components ----
        for m in modules where m.type == .fabricator {
            let cap = 4.0 * m.scale * effRatio * globalOutputMult
            let alloy = state.systems[sIdx].stockOf(.alloy)
            let cuprite = state.systems[sIdx].stockOf(.cuprite)
            let runs = min(cap, min(alloy / 2.0, cuprite / 1.0))
            if runs > 0 {
                consumeStock(sIdx, .alloy, runs * 2.0, result: &result)
                consumeStock(sIdx, .cuprite, runs * 1.0, result: &result)
                let out = runs * 1.0
                addStock(sIdx, .components, out, result: &result, produced: true)
                bump(.componentsMade, out)
            }
        }
    }

    // MARK: - Stock helpers (clamp >= 0)
    private func addStock(_ sIdx: Int, _ r: ResourceID, _ amt: Double, result: inout CycleResult, produced: Bool) {
        guard amt > 0, amt.isFinite else { return }
        let cap = stockCap(sIdx, r)
        let cur = state.systems[sIdx].stockOf(r)
        let newVal = min(cap, cur + amt)
        let actual = max(0, newVal - cur)
        state.systems[sIdx].stock[r.rawValue] = max(0, newVal)
        if produced { result.produced[r, default: 0] += actual }
    }
    private func consumeStock(_ sIdx: Int, _ r: ResourceID, _ amt: Double, result: inout CycleResult) {
        guard amt > 0 else { return }
        let cur = state.systems[sIdx].stockOf(r)
        let take = min(cur, amt)
        state.systems[sIdx].stock[r.rawValue] = max(0, cur - take)
        result.consumed[r, default: 0] += take
    }

    /// per-system stockpile ceiling (raised by cargo hubs)
    func stockCap(_ sIdx: Int, _ r: ResourceID) -> Double {
        if r == .credits { return 1_000_000_000 } // credits effectively uncapped
        var cap = 500.0
        for m in state.systems[sIdx].modules where m.type == .cargoHub {
            cap += m.cargoCapacityBonus
        }
        return cap
    }

    // MARK: - Trade
    private func runTrade(result: inout CycleResult) {
        let marketMult = techMult("t_markets", 1.40)
        for sIdx in state.systems.indices {
            guard state.systems[sIdx].claimed else { continue }
            let sysId = state.systems[sIdx].id
            let def = Galaxy.system(sysId)
            let markets = state.systems[sIdx].modules.filter { $0.type == .market }
            guard !markets.isEmpty else { continue }
            let popMult = def.trait == .populated ? 1.5 : 0.8
            var capacity = 0.0
            for m in markets { capacity += 12.0 * m.scale }
            // sell surplus of refined goods above a reserve
            let sellable: [(ResourceID, Double)] = [(.alloy, 6.0), (.fuel, 5.0), (.components, 9.0), (.isotope, 14.0)]
            for (res, price) in sellable {
                let reserve = 150.0
                let have = state.systems[sIdx].stockOf(res)
                let surplus = max(0, have - reserve)
                let sellAmt = min(surplus, capacity)
                if sellAmt > 0 {
                    state.systems[sIdx].stock[res.rawValue] = max(0, have - sellAmt)
                    let credits = sellAmt * price * popMult * marketMult
                    credit(.credits, credits, to: sysId)
                    result.creditsFromTrade += credits
                    bump(.creditsEarned, credits)
                    capacity -= sellAmt
                }
                if capacity <= 0 { break }
            }
        }
    }

    // MARK: - Research
    private func runResearch(result: inout CycleResult) {
        // command staff baseline keeps the tree reachable before the first lab
        var points = ResearchTree.baseOutput
        for s in state.systems where s.claimed {
            for m in s.modules where m.type == .research {
                points += m.researchOutput
            }
        }
        points *= globalOutputMult
        result.researchGained = points
        guard points > 0, var ar = state.activeResearch, let node = ResearchTree.node(ar.nodeId) else { return }
        ar.progress += points
        if ar.progress >= node.cost {
            state.unlockedTech.insert(node.id)
            state.researchCompletedCount += 1
            bump(.researchDone, 1)
            state.activeResearch = nil
            result.researchCompleted = node.name
            log("Research complete: \(node.name).", kind: "system")
            checkObjectives(); checkAchievements()
        } else {
            state.activeResearch = ar
        }
    }

    // MARK: - Convoys
    private func runConvoys(result: inout CycleResult) {
        let hopBonus = state.unlockedTech.contains("t_fastconvoy") ? 2 : 1
        for ci in state.convoys.indices {
            guard let routeId = state.convoys[ci].routeId,
                  let route = state.routes.first(where: { $0.id == routeId }) else { continue }
            state.convoys[ci].idle = false
            stepConvoy(ci, route: route, hopsThisCycle: hopBonus, result: &result)
        }
    }

    private func stepConvoy(_ ci: Int, route: CargoRoute, hopsThisCycle: Int, result: inout CycleResult) {
        var conv = state.convoys[ci]
        let res = ResourceID(rawValue: route.resource) ?? .alloy

        // Determine target endpoint based on direction
        let targetNode = conv.headingToDest ? route.destination : route.origin
        let startNode = conv.headingToDest ? route.origin : route.destination

        // If at start of a leg and no path, plan one
        if conv.pathNodes.isEmpty || conv.legIndex >= max(0, conv.pathNodes.count - 1) {
            // we are sitting at a node; if it's the target, do load/unload + flip
            if conv.currentSystem == targetNode {
                handleConvoyArrival(&conv, route: route, res: res, result: &result)
                // re-plan for new direction
            }
            // plan path from current to (new) target
            let newTarget = conv.headingToDest ? route.destination : route.origin
            let newStart = conv.currentSystem
            if let path = Galaxy.path(from: newStart, to: newTarget, unlockedTech: state.unlockedTech), path.count >= 2 {
                conv.pathNodes = path
                conv.legIndex = 0
                conv.hopProgress = 0
            } else {
                // no valid path; idle in place
                conv.idle = true
                state.convoys[ci] = conv
                return
            }
            _ = startNode
        }

        // Move hopsThisCycle along the path
        var hopsLeft = hopsThisCycle
        var guardCounter = 0
        while hopsLeft > 0 && guardCounter < 64 {
            guardCounter += 1
            guard conv.legIndex < conv.pathNodes.count - 1 else { break }
            let a = conv.pathNodes[conv.legIndex]
            let b = conv.pathNodes[conv.legIndex + 1]
            let lane = Galaxy.lane(a, b)
            let laneHops = max(1, lane?.hops ?? 1)
            conv.hopProgress += 1
            // fuel burn per hop (from origin reserve, best-effort)
            burnFuel(0.5)
            // raider chance per hop
            if let lane = lane, conv.carrying > 0 {
                maybeRaid(lane: lane, conv: &conv, res: res, result: &result)
            }
            if conv.hopProgress >= laneHops {
                conv.hopProgress = 0
                conv.legIndex += 1
                conv.currentSystem = b
                // reached end of path?
                if conv.legIndex >= conv.pathNodes.count - 1 {
                    handleConvoyArrival(&conv, route: route, res: res, result: &result)
                    // plan next direction path
                    let nextTarget = conv.headingToDest ? route.destination : route.origin
                    if let path = Galaxy.path(from: conv.currentSystem, to: nextTarget, unlockedTech: state.unlockedTech), path.count >= 2 {
                        conv.pathNodes = path; conv.legIndex = 0; conv.hopProgress = 0
                    } else {
                        conv.idle = true
                        break
                    }
                }
            }
            hopsLeft -= 1
        }
        state.convoys[ci] = conv
    }

    private func handleConvoyArrival(_ conv: inout Convoy, route: CargoRoute, res: ResourceID, result: inout CycleResult) {
        if conv.currentSystem == route.origin && conv.headingToDest {
            // load at origin
            let avail = state.sys(route.origin)?.stockOf(res) ?? 0
            let load = min(route.amountPerRun, avail) * convoyCapacityFactor()
            let actualLoad = min(load, avail)
            if actualLoad > 0 {
                state.updateSys(route.origin) { $0.stock[res.rawValue] = max(0, $0.stockOf(res) - actualLoad) }
                conv.carrying = actualLoad
                conv.carryingResource = res.rawValue
            }
            // now head to destination (path planned by caller)
        } else if conv.currentSystem == route.destination {
            // deliver
            if conv.carrying > 0 {
                let destIdx = state.systems.firstIndex(where: { $0.id == route.destination }) ?? 0
                let cap = stockCap(destIdx, res)
                let cur = state.systems[destIdx].stockOf(res)
                let space = max(0, cap - cur)
                let delivered = min(conv.carrying, space)
                state.systems[destIdx].stock[res.rawValue] = min(cap, cur + delivered)
                conv.carrying = 0
                result.deliveries += 1
                bump(.deliveries, 1)
            }
            if route.loop {
                conv.headingToDest = false   // now return to origin to reload
            } else {
                conv.idle = true
                conv.routeId = nil
            }
        } else if conv.currentSystem == route.origin && !conv.headingToDest {
            // returned to origin on a loop; flip to head out again and load
            conv.headingToDest = true
            let avail = state.sys(route.origin)?.stockOf(res) ?? 0
            let load = min(route.amountPerRun, avail) * convoyCapacityFactor()
            let actualLoad = min(load, avail)
            if actualLoad > 0 {
                state.updateSys(route.origin) { $0.stock[res.rawValue] = max(0, $0.stockOf(res) - actualLoad) }
                conv.carrying = actualLoad
                conv.carryingResource = res.rawValue
            }
        }
        checkObjectives(); checkAchievements()
    }

    private func convoyCapacityFactor() -> Double {
        // cargo hubs cluster-wide modestly raise per-run capacity
        var bonus = 1.0
        for s in state.systems where s.claimed {
            for m in s.modules where m.type == .cargoHub { bonus += 0.05 * m.scale }
        }
        return min(bonus, 4.0)
    }

    private func burnFuel(_ amt: Double) {
        // best effort: take fuel from any claimed system
        for s in state.systems where s.claimed {
            let idx = state.systems.firstIndex(where: { $0.id == s.id })!
            let have = state.systems[idx].stockOf(.fuel)
            if have >= amt {
                state.systems[idx].stock[ResourceID.fuel.rawValue] = have - amt
                return
            }
        }
    }

    private func maybeRaid(lane: LaneDef, conv: inout Convoy, res: ResourceID, result: inout CycleResult) {
        // deterministic pseudo-random based on cycle + convoy + node to avoid true RNG nondeterminism issues
        let defense = clusterDefenseRating()
        let baseChance = lane.hazard * max(0.1, 1.0 - defense / 60.0)
        let seed = (state.cycle &* 31 &+ conv.legIndex &* 17 &+ Int(conv.carrying)) % 100
        if Double(seed) < baseChance * 100 * 0.25 {
            // raid hits: lose part of cargo unless defense high
            if defense > 30 {
                bump(.raidsRepelled, 1)
                result.notes.append("Escort repelled raiders on a lane")
                log("Raiders struck a convoy lane but were driven off.", kind: "raid")
            } else {
                let loss = conv.carrying * 0.5
                conv.carrying = max(0, conv.carrying - loss)
                result.notes.append("Raiders took cargo on a lane")
                log("Raiders seized cargo from \(conv.name).", kind: "raid")
            }
        }
    }

    func clusterDefenseRating() -> Double {
        var d = 0.0
        for s in state.systems where s.claimed {
            for m in s.modules where m.type == .defense { d += m.defenseRating }
        }
        return d
    }

    // MARK: - Events
    private func maybeTriggerEvent(result: inout CycleResult) {
        guard state.pendingEventId == nil else { return }
        // ~35% chance per cycle, deterministic-ish
        let seed = (state.cycle &* 7919) % 100
        guard seed < 35 else { return }
        // weight events by current situation
        var pool = EventCatalog.all
        // require shipyard/convoys for some? keep simple: filter raid events only if convoys exist
        if state.convoys.isEmpty {
            pool = pool.filter { $0.kind != .raid }
        }
        // need a hazardous claimed system for isotope surge
        let hasHazard = state.systems.contains { $0.claimed && Galaxy.system($0.id).trait == .hazardous }
        if !hasHazard { pool = pool.filter { $0.kind != .isotopeSurge } }
        guard !pool.isEmpty else { return }
        let pick = pool[(state.cycle &* 13) % pool.count]
        state.pendingEventId = pick.id
        result.triggeredEventId = pick.id
        log("Anomaly detected: \(pick.title). Command decision required.", kind: pick.kind.rawValue)
    }
}
