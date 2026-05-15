import SwiftUI
import Combine

final class FrozenCatchStore: ObservableObject {
    @Published var state: FrozenCatchGameState

    private static let saveKey = "pat.gameState.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: FrozenCatchStore.saveKey),
           let decoded = try? JSONDecoder().decode(FrozenCatchGameState.self, from: data) {
            self.state = decoded
        } else {
            self.state = FrozenCatchGameState.newGame()
            persist()
        }
    }

    func persist() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: FrozenCatchStore.saveKey)
        }
    }

    func resetProgress() {
        // M5: Reset progress should NOT re-trigger onboarding. Preserve onboardingSeen,
        // plus keep user-facing preferences (sound/haptics) intact across resets.
        let wasOnboardingSeen = state.onboardingSeen
        let wasSoundOn = state.soundOn
        let wasHapticsOn = state.hapticsOn
        var fresh = FrozenCatchGameState.newGame()
        fresh.onboardingSeen = wasOnboardingSeen
        fresh.soundOn = wasSoundOn
        fresh.hapticsOn = wasHapticsOn
        state = fresh
        persist()
    }

    // MARK: - Derived
    var prestigeTier: FrozenCatchPrestigeTier {
        FrozenCatchCatalog.prestige[state.prestigeRank]
    }

    var rosterCap: Int {
        // 6 + research bonus from Insulated Sled (+1)
        var cap = 6
        if state.researchCompleted.contains(2) { cap += 1 }
        return cap
    }

    var assignmentCapacityForLake: [Int: Int] {
        var d: [Int: Int] = [:]
        for lake in FrozenCatchCatalog.lakes {
            var cap = lake.capacity
            // Sled Train gives +1 slot per 6 levels of gear[3]
            let sledLvl = state.gearTiers[3]
            if sledLvl >= 6 { cap += 1 }
            d[lake.id] = cap
        }
        return d
    }

    var weeklySalaryTotal: Double {
        state.workers.reduce(0) { $0 + $1.salary }
    }

    var weeklyMaintenanceTotal: Double {
        var total = 0.0
        for (idx, lvl) in state.gearTiers.enumerated() where lvl > 0 {
            let g = FrozenCatchCatalog.gear[idx]
            // tier cost approximated; maintenance 2% of cumulative tier cost
            let cumulative = (0..<lvl).reduce(0.0) { acc, l in
                acc + pow(1.5, Double(l)) * g.baseCost
            }
            total += cumulative * 0.02
        }
        return total
    }

    var weeklyInterest: Double {
        state.debt * 0.008
    }

    var foragerPassive: Double {
        guard state.researchCompleted.contains(10) else { return 0 }
        let foragerCount = state.workers.filter { $0.classObj == .forager }.count
        return Double(foragerCount) * 200
    }

    // MARK: - Multipliers
    func gearMultiplier(lakeID: Int) -> Double {
        // Auger Set +5% per level; Tackle Set adds rare drop separate
        let auger = state.gearTiers[0]
        var m = 1.0 + Double(auger) * 0.05
        // Sonar Use +10%
        if state.researchCompleted.contains(0) { m *= 1.10 }
        // Smoked Fish boost — applied to price; not here.
        // FrozenCatch Lab — FrozenCatch Trench +20%
        if lakeID == 6 && state.researchCompleted.contains(13) { m *= 1.20 }
        return m
    }

    func moraleFactor(_ w: FrozenCatchWorker) -> Double {
        let baseline = 50.0
        // morale 0..100 maps to 0.7..1.2
        let v = 0.7 + (w.morale / 100.0) * 0.5
        // Stoic resilience adds small +
        if w.traitObj == .stoic { return v + 0.03 }
        if w.traitObj == .patient { return v + 0.05 }
        _ = baseline
        return v
    }

    func fatigueDrag(_ w: FrozenCatchWorker) -> Double {
        // fatigue 0..100 maps to 0..0.6 drag
        return min(0.6, w.fatigue / 100.0 * 0.6)
    }

    // MARK: - Pool & names
    static let firstNames = [
        "Yrjö", "Pellervo", "Aino", "Tarja", "Kalevi", "Sirkka", "Veikko", "Saima",
        "Eino", "Helmi", "Toivo", "Maire", "Olli", "Hilkka", "Jorma", "Kerttu",
        "Reima", "Lyyli", "Antero", "Anneli", "Risto", "Tuula", "Heimo", "Liisa",
        "Mauno", "Pirjo", "Esa", "Marja", "Hannu", "Sari", "Kauko", "Eila"
    ]

    static let lastNames = [
        "Lampinen", "Korhonen", "Vainio", "Saari", "Niemi", "Mäkelä", "Laine", "Heikkinen",
        "Aaltonen", "Salminen", "Toivanen", "Kallio", "Hakala", "Lehtinen", "Halonen", "Lehto",
        "Räsänen", "Aho", "Hänninen", "Tuominen", "Pietilä", "Pulkkinen", "Karjalainen", "Ranta",
        "Manninen", "Rantanen", "Hyvärinen", "Nieminen", "Heinonen", "Kettunen", "Saastamoinen", "Linna"
    ]

    static func buildNamedPool(seed: UInt64) -> [FrozenCatchWorker] {
        var rng = FrozenCatchRNG(seed: seed)
        var pool: [FrozenCatchWorker] = []
        // Use distinct (first, last) pairs — shuffle indices
        var firstIdx = Array(0..<firstNames.count)
        var lastIdx = Array(0..<lastNames.count)
        // simple shuffle
        for i in stride(from: firstIdx.count - 1, through: 1, by: -1) {
            let j = rng.intRange(0, i)
            firstIdx.swapAt(i, j)
        }
        for i in stride(from: lastIdx.count - 1, through: 1, by: -1) {
            let j = rng.intRange(0, i)
            lastIdx.swapAt(i, j)
        }
        for i in 0..<32 {
            let cls = FrozenCatchWorkerClass.allCases[rng.intRange(0, FrozenCatchWorkerClass.allCases.count - 1)]
            // weighted rank: I 50%, II 30%, III 15%, IV 5%
            let rankRoll = rng.unit()
            let rank: FrozenCatchWorkerRank
            if rankRoll < 0.5 { rank = .I }
            else if rankRoll < 0.8 { rank = .II }
            else if rankRoll < 0.95 { rank = .III }
            else { rank = .IV }
            let skillBase = cls.baseSkill * rank.statMult
            let endBase = cls.baseEndurance * rank.statMult
            // jitter
            let skill = min(100, max(1, skillBase + rng.range(-6, 6)))
            let endurance = min(100, max(1, endBase + rng.range(-6, 6)))
            let salary = cls.baseSalary * rank.salaryMult * rng.range(0.92, 1.08)
            let trait = FrozenCatchTrait.allCases[rng.intRange(0, FrozenCatchTrait.allCases.count - 1)]
            let fn = firstNames[firstIdx[i]]
            let ln = lastNames[lastIdx[i]]
            let w = FrozenCatchWorker(
                id: 10_000 + Int(seed % 100_000) * 100 + i,
                name: "\(fn) \(ln)",
                classID: cls.rawValue,
                rankID: rank.rawValue,
                skill: skill,
                endurance: endurance,
                morale: 70,
                fatigue: 0,
                salary: round(salary),
                traitID: trait.rawValue,
                assignedLakeID: nil,
                rested: false
            )
            pool.append(w)
        }
        return pool
    }

    func refreshCandidatesIfNeeded() {
        // refresh every 4 weeks
        if state.week - state.lastPoolRefreshWeek >= 4 {
            let newSeed = state.candidatePoolSeed &+ UInt64(state.week)
            state.namedPool = FrozenCatchStore.buildNamedPool(seed: newSeed)
            state.candidatePoolSeed = newSeed
            state.lastPoolRefreshWeek = state.week
            state.candidates = Array(state.namedPool.prefix(5))
        }
    }

    // MARK: - Hire / fire / promote / rest
    func hire(_ worker: FrozenCatchWorker) -> Bool {
        guard state.workers.count < rosterCap else { return false }
        var w = worker
        w.assignedLakeID = nil
        state.workers.append(w)
        // remove from candidates and pool
        state.candidates.removeAll { $0.id == worker.id }
        state.namedPool.removeAll { $0.id == worker.id }
        if state.candidates.count < 5, let next = state.namedPool.first(where: { p in
            !state.candidates.contains(where: { $0.id == p.id })
        }) {
            state.candidates.append(next)
        }
        checkAwards()
        persist()
        return true
    }

    func fire(_ workerID: Int) {
        state.workers.removeAll { $0.id == workerID }
        // remove from assignments
        for (k, v) in state.assignments {
            state.assignments[k] = v.filter { $0 != workerID }
        }
        persist()
    }

    func promote(_ workerID: Int) {
        guard let idx = state.workers.firstIndex(where: { $0.id == workerID }) else { return }
        var w = state.workers[idx]
        guard w.rankID < FrozenCatchWorkerRank.IV.rawValue else { return }
        let costNow = w.salary * 4 // 4 weeks of pay as promotion cost
        guard state.cash >= costNow else { return }
        let nextRankID = w.rankID + 1
        // C3: replace force unwraps with guarded lookups; no-op on failure.
        guard let newRank = FrozenCatchWorkerRank(rawValue: nextRankID),
              let oldRank = FrozenCatchWorkerRank(rawValue: w.rankID) else { return }
        state.cash -= costNow
        w.rankID = nextRankID
        w.skill = min(100, w.skill * (newRank.statMult / oldRank.statMult))
        w.endurance = min(100, w.endurance * (newRank.statMult / oldRank.statMult))
        w.salary = round(w.salary * (newRank.salaryMult / oldRank.salaryMult))
        state.workers[idx] = w
        persist()
    }

    func toggleRest(_ workerID: Int) {
        guard let idx = state.workers.firstIndex(where: { $0.id == workerID }) else { return }
        state.workers[idx].rested.toggle()
        if state.workers[idx].rested {
            // remove from assignments
            for (k, v) in state.assignments {
                state.assignments[k] = v.filter { $0 != workerID }
            }
        }
        persist()
    }

    // MARK: - Assignments
    func assign(workerID: Int, toLake lakeID: Int?) {
        // remove from all
        for (k, v) in state.assignments {
            state.assignments[k] = v.filter { $0 != workerID }
        }
        guard let idx = state.workers.firstIndex(where: { $0.id == workerID }) else { return }
        if state.workers[idx].rested { return }
        if let lid = lakeID {
            let cap = assignmentCapacityForLake[lid] ?? 0
            var arr = state.assignments[lid] ?? []
            if arr.count < cap {
                arr.append(workerID)
                state.assignments[lid] = arr
                state.workers[idx].assignedLakeID = lid
            }
        } else {
            state.workers[idx].assignedLakeID = nil
        }
        persist()
    }

    // MARK: - Gear upgrade
    func gearCost(idx: Int) -> Double {
        let lvl = state.gearTiers[idx]
        guard lvl < 12 else { return Double.infinity }
        let base = FrozenCatchCatalog.gear[idx].baseCost
        var cost = pow(1.5, Double(lvl)) * base
        if state.researchCompleted.contains(11) {
            cost *= 0.80 // Frostsmith Atelier -20%
        }
        return round(cost)
    }

    func upgradeGear(idx: Int) {
        let lvl = state.gearTiers[idx]
        guard lvl < 12 else { return }
        let cost = gearCost(idx: idx)
        guard state.cash >= cost else { return }
        state.cash -= cost
        state.gearTiers[idx] += 1
        checkAwards()
        persist()
    }

    // MARK: - Research
    func canStartResearch(_ id: Int) -> Bool {
        if state.researchActive != nil { return false }
        if state.researchCompleted.contains(id) { return false }
        let r = FrozenCatchCatalog.research[id]
        for prereq in r.prerequisites {
            if !state.researchCompleted.contains(prereq) { return false }
        }
        if state.cash < r.cost { return false }
        return true
    }

    func startResearch(_ id: Int) {
        guard canStartResearch(id) else { return }
        let r = FrozenCatchCatalog.research[id]
        state.cash -= r.cost
        state.researchActive = id
        state.researchWeeksLeft = r.weeks
        persist()
    }

    // MARK: - Market
    func sellSpecies(speciesID: Int, units: Int) {
        guard speciesID >= 0, speciesID < state.marketPrices.count else { return }
        let inv = state.inventory[speciesID] ?? 0
        let qty = min(units, inv)
        guard qty > 0 else { return }
        let price = state.marketPrices[speciesID]
        var revenue = price * Double(qty)
        if state.researchCompleted.contains(3) { revenue *= 1.15 }
        if state.researchCompleted.contains(9) { revenue *= 1.30 }
        if state.researchCompleted.contains(4) && speciesID == 8 { revenue *= 1.40 }
        if state.sponsorDealWeeksLeft > 0 { revenue *= 1.20 * 0.95 } // net effect
        state.cash += revenue
        state.inventory[speciesID] = inv - qty
        state.totalFishSold += qty
        checkAwards()
        persist()
    }

    // MARK: - Loans
    func takeLoan(_ amount: Double) {
        let openMax: Double = 2_000_000
        let available = openMax - state.debt
        let take = min(amount, available)
        guard take > 0 else { return }
        state.cash += take
        state.debt += take
        persist()
    }

    func repayLoan(_ amount: Double) {
        let repay = min(amount, min(state.debt, state.cash))
        guard repay > 0 else { return }
        state.cash -= repay
        state.debt -= repay
        persist()
    }

    // MARK: - Advance Week
    func advanceWeek() {
        var rng = FrozenCatchRNG(seed: UInt64(state.week) &* 2654435761 &+ state.candidatePoolSeed)

        var revenue = 0.0
        var perWorker: [WorkerCatch] = []

        // Compute catches per assignment
        for lake in FrozenCatchCatalog.lakes {
            guard state.unlockedLakes.contains(lake.id) else { continue }
            let assignedIDs = state.assignments[lake.id] ?? []
            for wid in assignedIDs {
                guard let widx = state.workers.firstIndex(where: { $0.id == wid }) else { continue }
                var w = state.workers[widx]
                if w.rested { continue }
                let baseUnits = w.skill * 0.1
                var mods = gearMultiplier(lakeID: lake.id) * lake.factor
                let weatherMod = rng.range(0.85, 1.15)
                mods *= weatherMod
                mods *= moraleFactor(w)
                mods *= (1.0 - fatigueDrag(w))
                mods *= prestigeTier.drawMult
                // trait
                switch w.traitObj {
                case .patient: mods *= 1.05
                case .quick:   mods *= 1.03
                default: break
                }
                let units = max(0, Int(round(baseUnits * mods)))
                // pick primary species via weighted pool
                let pool = lake.speciesPool
                let weights = pool.map { FrozenCatchCatalog.fish[$0].rarityWeight }
                let pickIdx = rng.weightedPick(weights)
                let primaryID = pool[pickIdx]
                state.inventory[primaryID, default: 0] += units
                // rare drop chance: tackle set + lucky
                let tackleBonus = Double(state.gearTiers[1]) * 0.04
                let luckBonus = w.traitObj == .lucky ? 0.05 : 0.0
                let rareChance = 0.05 + tackleBonus + luckBonus
                if rng.unit() < rareChance, !pool.isEmpty {
                    let rareIdx = rng.weightedPick(pool.map { 1.0 / FrozenCatchCatalog.fish[$0].rarityWeight })
                    let rareID = pool[rareIdx]
                    let rareUnits = max(1, units / 6)
                    state.inventory[rareID, default: 0] += rareUnits
                }

                // fatigue
                var fatigueDelta: Double = 12
                if w.traitObj == .tough  { fatigueDelta -= 4 }
                if w.traitObj == .frail  { fatigueDelta += 5 }
                // coats
                fatigueDelta *= max(0.4, 1.0 - 0.02 * Double(state.gearTiers[2]))
                w.fatigue = min(100, w.fatigue + fatigueDelta)
                // morale shift
                let salaryExpectation = w.salary
                let salaryNorm = min(2.0, Double(units) * FrozenCatchCatalog.fish[primaryID].basePrice / max(salaryExpectation, 1))
                if salaryNorm > 1.0 { w.morale = min(100, w.morale + 4) }
                else {
                    // M1: greedy trait halves the weekly morale drop ("slow morale drop").
                    let drop: Double = w.traitObj == .greedy ? 1 : 2
                    w.morale = max(0, w.morale - drop)
                }
                if w.traitObj == .drunkard, rng.unit() < 0.25 { w.morale = max(0, w.morale - 6) }

                if w.fatigue > 90 {
                    w.rested = true
                    state.assignments[lake.id] = state.assignments[lake.id]?.filter { $0 != wid }
                }

                state.workers[widx] = w
                perWorker.append(WorkerCatch(id: wid, workerName: w.name, lakeName: lake.name, units: units, primarySpeciesID: primaryID))
            }
        }

        // Rest recovery for resting workers
        for i in state.workers.indices {
            if state.workers[i].rested {
                state.workers[i].fatigue = max(0, state.workers[i].fatigue - 30)
                state.workers[i].morale = min(100, state.workers[i].morale + 6)
                if state.workers[i].fatigue < 30 { state.workers[i].rested = false }
            } else if state.workers[i].assignedLakeID == nil {
                state.workers[i].fatigue = max(0, state.workers[i].fatigue - 12)
                // M2: Heated Tent (gear 4) blurb is +3% morale recovery/level — multiplier 3.0 makes it match.
                let moraleRecovery = 3 + Double(state.gearTiers[4]) * 3.0
                state.workers[i].morale = min(100, state.workers[i].morale + moraleRecovery * (state.researchCompleted.contains(1) ? 1.5 : 1.0))
            }
        }

        // Auto-sell: leave the choice to player. (Inventory accumulates.)
        // Forager passive
        state.cash += foragerPassive

        // Roll market prices ±25% from base.
        // H2: Auction House (research 9) affects SELL revenue only (sellSpecies +30%),
        // it must NOT compound the weekly market price.
        var newPrices: [Double] = []
        for (i, f) in FrozenCatchCatalog.fish.enumerated() {
            let mult = rng.range(0.75, 1.25)
            let p = f.basePrice * mult
            newPrices.append(round(p * 10) / 10)
            _ = i
        }
        // append snapshot before replacement
        state.priceHistory.append(state.marketPrices)
        if state.priceHistory.count > 8 { state.priceHistory.removeFirst(state.priceHistory.count - 8) }
        state.marketPrices = newPrices

        // H5: if cash can't cover salaries, scale by paying who we can in roster order and
        //     zeroing the catches/morale of unpaid workers (already-computed catches stay,
        //     but unpaid workers take a morale hit and skip pay this week).
        let maintenance = weeklyMaintenanceTotal
        let interest = weeklyInterest
        // Interest compounds into principal per design — only drained from cash via repayment.
        let salaryBudget = max(0.0, state.cash - maintenance)
        var paidSalaries = 0.0
        var unpaidWorkerIDs: [Int] = []
        for w in state.workers {
            if paidSalaries + w.salary <= salaryBudget {
                paidSalaries += w.salary
            } else {
                unpaidWorkerIDs.append(w.id)
            }
        }
        for wid in unpaidWorkerIDs {
            if let widx = state.workers.firstIndex(where: { $0.id == wid }) {
                state.workers[widx].morale = max(0, state.workers[widx].morale - 8)
            }
        }
        let totalExpenses = paidSalaries + maintenance
        state.cash -= totalExpenses
        // H4/C2: cap debt to prevent runaway compounding (and prevent C2 slider inversion).
        state.debt = min(2_500_000, state.debt + interest)
        // H5: clamp negative cash floor and trigger forced layoff if too deep underwater.
        if state.cash < -100_000 {
            state.cash = -100_000
            // Forced layoff: auto-fire up to 2 workers (highest salary first).
            let toFire = state.workers
                .sorted { $0.salary > $1.salary }
                .prefix(2)
                .map { $0.id }
            for wid in toFire {
                state.workers.removeAll { $0.id == wid }
                for (k, v) in state.assignments {
                    state.assignments[k] = v.filter { $0 != wid }
                }
            }
        }

        // Sponsor deal countdown
        if state.sponsorDealWeeksLeft > 0 {
            state.sponsorDealWeeksLeft -= 1
        }

        // Research progress
        if let rid = state.researchActive {
            state.researchWeeksLeft -= 1
            if state.researchWeeksLeft <= 0 {
                state.researchCompleted.append(rid)
                state.researchActive = nil
                state.researchWeeksLeft = 0
            }
        }

        // Random event roll — fire every 2..4 weeks
        var triggeredEventIDs: [Int] = []
        if state.pendingEventID == nil {
            // expected freq ~33% per week
            if rng.unit() < 0.33 {
                let id = rng.intRange(0, FrozenCatchCatalog.events.count - 1)
                state.pendingEventID = id
                triggeredEventIDs.append(id)
            }
        }

        // Apprentice program — every 6 weeks free Junior I
        if state.researchCompleted.contains(8), state.week % 6 == 0, state.workers.count < rosterCap {
            let app = makeApprentice(seed: rng.next())
            state.workers.append(app)
        }

        // Reputation: derived
        let revFromInv = perWorker.reduce(0) { $0 + Double($1.units) * FrozenCatchCatalog.fish[$1.primarySpeciesID].basePrice }
        revenue = revFromInv // virtual revenue rep counter
        let repGain: Int = {
            var g = Int(revenue / 4000)
            g += state.researchCompleted.count / 2
            g += state.workers.count / 2
            if state.researchCompleted.contains(15) { g = Int(Double(g) * 1.25) }
            return max(0, g)
        }()
        state.reputationPoints += repGain
        let oldRank = state.prestigeRank
        for tier in FrozenCatchCatalog.prestige.reversed() {
            if state.reputationPoints >= tier.minPoints {
                state.prestigeRank = tier.id
                break
            }
        }
        // Unlock lakes at new prestige
        for lake in FrozenCatchCatalog.lakes {
            if state.prestigeRank >= lake.requiredPrestige, !state.unlockedLakes.contains(lake.id) {
                state.unlockedLakes.append(lake.id)
            }
        }

        // M2: estimate weekly revenue from this week's catches using current market prices,
        //     so the chart and Week Report reflect actual profit potential, not just expenses.
        var estimatedRevenue = 0.0
        for c in perWorker {
            let sid = c.primarySpeciesID
            guard sid >= 0, sid < state.marketPrices.count else { continue }
            estimatedRevenue += Double(c.units) * state.marketPrices[sid]
        }

        // Net history (revenue minus expenses, plus forager passive — see M2)
        let net = estimatedRevenue - totalExpenses + foragerPassive
        state.netHistory.append(net)
        if state.netHistory.count > 60 { state.netHistory.removeFirst(state.netHistory.count - 60) }

        // Last week result
        state.lastWeekResult = WeekResult(
            week: state.week,
            perWorkerCatches: perWorker,
            revenue: estimatedRevenue,
            expenses: totalExpenses,
            net: net,
            prestigeDelta: state.prestigeRank - oldRank,
            eventsTriggered: triggeredEventIDs
        )

        // tick
        state.week += 1
        refreshCandidatesIfNeeded()
        checkAwards()
        persist()
    }

    func makeApprentice(seed: UInt64) -> FrozenCatchWorker {
        var rng = FrozenCatchRNG(seed: seed)
        let fnIdx = rng.intRange(0, FrozenCatchStore.firstNames.count - 1)
        let lnIdx = rng.intRange(0, FrozenCatchStore.lastNames.count - 1)
        let name = "\(FrozenCatchStore.firstNames[fnIdx]) \(FrozenCatchStore.lastNames[lnIdx])"
        let cls = FrozenCatchWorkerClass.junior
        let rank = FrozenCatchWorkerRank.I
        return FrozenCatchWorker(
            id: 50_000 + Int(seed % 1_000_000),
            name: name,
            classID: cls.rawValue,
            rankID: rank.rawValue,
            skill: cls.baseSkill * rank.statMult,
            endurance: cls.baseEndurance * rank.statMult,
            morale: 80,
            fatigue: 0,
            salary: round(cls.baseSalary * rank.salaryMult),
            traitID: FrozenCatchTrait.allCases[rng.intRange(0, FrozenCatchTrait.allCases.count - 1)].rawValue,
            assignedLakeID: nil,
            rested: false
        )
    }

    // MARK: - Event resolution
    func resolvePendingEvent(choice: Int) {
        guard let eid = state.pendingEventID else { return }
        // M4: bounds-check catalog lookups.
        guard eid >= 0, eid < FrozenCatchCatalog.events.count else {
            state.pendingEventID = nil
            persist()
            return
        }
        let evt = FrozenCatchCatalog.events[eid]
        var outcome = ""
        var rng = FrozenCatchRNG(seed: UInt64(state.week) &* 1664525 &+ UInt64(eid))

        switch eid {
        case 0:
            if choice == 0 {
                // Cancel a lake → clear the most-staffed lake's assignment for the week.
                if let lakeID = state.assignments.max(by: { ($0.value.count) < ($1.value.count) })?.key,
                   lakeID >= 0, lakeID < FrozenCatchCatalog.lakes.count {
                    state.assignments[lakeID] = []
                    outcome = "\(FrozenCatchCatalog.lakes[lakeID].name) cleared for the week."
                } else {
                    outcome = "No lake to cancel."
                }
            } else if choice == 1 {
                state.cash -= 1500
                outcome = "Pushed through. -$1,500 in damages."
            } else {
                // Brave the storm — 50% chance to gain a bonus, otherwise heavier penalty.
                if rng.unit() < 0.5 {
                    let bonus = 2500
                    state.cash += Double(bonus)
                    outcome = "Braved the storm. Crews returned with a x1.5 windfall (+$\(bonus))."
                } else {
                    state.cash -= 3000
                    outcome = "Storm broke gear. -$3,000 in damages."
                }
            }
        case 1:
            if choice == 1 {
                // Hire defense — pay $1000 to negate raid (regardless of Security research).
                state.cash -= 1000
                outcome = "Hired defense for $1,000. No catch lost."
            } else if state.researchCompleted.contains(6) {
                outcome = "Security stopped the raid."
            } else {
                var lost = 0
                for (k, v) in state.inventory {
                    let take = v / 10
                    state.inventory[k] = v - take
                    lost += take
                }
                outcome = "Poachers took \(lost) units."
            }
        case 2:
            if choice == 1 {
                // Rest the team — clear all assignments, all workers recover.
                state.assignments = [:]
                for i in state.workers.indices {
                    state.workers[i].assignedLakeID = nil
                    state.workers[i].fatigue = max(0, state.workers[i].fatigue - 25)
                    state.workers[i].morale  = min(100, state.workers[i].morale + 10)
                }
                outcome = "Team rested. Assignments cleared, fatigue and morale improved."
            } else {
                // Send the crew home: M1 — pick a random worker, prefer high-fatigue/assigned.
                let assignedFirst = state.workers.filter { $0.assignedLakeID != nil }
                let pool = assignedFirst.isEmpty ? state.workers : assignedFirst
                if let picked = pool.max(by: { $0.fatigue < $1.fatigue }),
                   let idx = state.workers.firstIndex(where: { $0.id == picked.id }) {
                    state.workers[idx].fatigue = min(100, state.workers[idx].fatigue + 60)
                    state.workers[idx].rested = true
                    outcome = "\(state.workers[idx].name) needs rest."
                } else {
                    outcome = "No crew involved."
                }
            }
        case 3:
            if choice == 1 {
                outcome = "Politely declined. No bonus, no cost."
            } else {
                state.cash -= 500
                if state.prestigeRank >= 2 {
                    state.cash += 3000
                    outcome = "Sponsor impressed. +$2,500 net."
                } else {
                    outcome = "Sponsor noted but no payout. -$500."
                }
            }
        case 4:
            if state.researchCompleted.contains(5) {
                outcome = "Compliance Office handled the inspector."
            } else {
                let fine = Double(rng.intRange(500, 5000))
                state.cash -= fine
                outcome = "Inspector issued a $\(Int(fine)) fine."
            }
        case 5:
            if choice == 0 {
                // sell 50 of the most-stocked species at 3x base
                if let (sid, qty) = state.inventory.max(by: { $0.value < $1.value }),
                   qty > 0, sid >= 0, sid < FrozenCatchCatalog.fish.count {
                    let take = min(50, qty)
                    let revenue = Double(take) * FrozenCatchCatalog.fish[sid].basePrice * 3
                    state.cash += revenue
                    state.inventory[sid] = qty - take
                    outcome = "Sold \(take) \(FrozenCatchCatalog.fish[sid].name) for $\(Int(revenue))."
                } else {
                    outcome = "No inventory to sell."
                }
            } else {
                outcome = "Declined the buyer."
            }
        case 6:
            if choice == 1 {
                outcome = "Skipped the festival. Workers stay focused — no morale change."
            } else {
                for i in state.workers.indices { state.workers[i].morale = min(100, state.workers[i].morale + 12) }
                outcome = "All workers gained morale."
            }
        case 7:
            if choice == 1 && state.researchCompleted.contains(1) {
                // Use heated tents — cancel penalty (requires Heated Tent research).
                outcome = "Heated tents kept the crew warm. No penalty this week."
            } else if choice == 1 {
                // Tried heated tents but research not done — same penalty as braving the cold.
                for (k, v) in state.inventory {
                    state.inventory[k] = Int(Double(v) * 0.9)
                }
                outcome = "No heated tents available. Cold snap chilled the inventory."
            } else {
                for (k, v) in state.inventory {
                    state.inventory[k] = Int(Double(v) * 0.9)
                }
                outcome = "Cold snap. Inventory chilled, rare drops to come."
            }
        case 8:
            if choice == 1 {
                // Save for later — record a 2-week buff via reusing sponsorDealWeeksLeft is wrong;
                // instead bump every fish's market price slightly for 2 weeks via an immediate
                // permanent-style nudge (1.2x on next pricing roll's basePrice handled here as a
                // one-time price boost on current prices to keep state additive without new fields).
                for i in state.marketPrices.indices {
                    state.marketPrices[i] = round(state.marketPrices[i] * 1.2 * 10) / 10
                }
                outcome = "Saved the aurora glow — current market prices x1.2 ride out."
            } else if state.unlockedLakes.contains(5) {
                outcome = "Aurora boosted Aurora Strait next tick."
            } else {
                outcome = "Aurora was visible. No bonus this season."
            }
        case 9:
            if state.researchCompleted.contains(7) {
                outcome = "Maintenance crew repaired it free."
            } else {
                if let idx = state.gearTiers.firstIndex(where: { $0 > 0 }),
                   idx >= 0, idx < FrozenCatchCatalog.gear.count {
                    state.gearTiers[idx] -= 1
                    outcome = "\(FrozenCatchCatalog.gear[idx].name) lost a tier."
                } else {
                    outcome = "No gear to damage."
                }
            }
        case 10:
            if choice == 0, state.workers.count < rosterCap {
                let app = makeApprentice(seed: rng.next())
                state.workers.append(app)
                outcome = "\(app.name) joined for free."
            } else {
                outcome = "Sent the apprentice elsewhere."
            }
        case 11:
            if choice == 0 {
                state.sponsorDealWeeksLeft = 4
                outcome = "Sponsor deal active for 4 weeks."
            } else {
                outcome = "Declined the sponsor deal."
            }
        default:
            outcome = "—"
        }

        let entry = FrozenCatchEventEntry(id: state.week * 1000 + eid, week: state.week, eventID: eid, choice: choice, outcome: outcome)
        state.eventsLog.insert(entry, at: 0)
        if state.eventsLog.count > 20 { state.eventsLog.removeLast(state.eventsLog.count - 20) }
        state.pendingEventID = nil
        _ = evt
        persist()
    }

    // MARK: - Awards
    func checkAwards() {
        var unlocked = Set(state.awardsUnlocked)
        if state.totalFishSold >= 1 { unlocked.insert(0) }
        if state.workers.count >= 5 { unlocked.insert(1) }
        if state.assignments.values.contains(where: { !$0.isEmpty }) { unlocked.insert(2) }
        if state.prestigeRank >= 1 { unlocked.insert(3) }
        if state.prestigeRank >= 2 { unlocked.insert(4) }
        if state.prestigeRank >= 3 { unlocked.insert(5) }
        if state.prestigeRank >= 5 { unlocked.insert(6) }
        if state.researchCompleted.count >= 3 { unlocked.insert(7) }
        if state.gearTiers.contains(where: { $0 >= 6 }) { unlocked.insert(8) }
        if state.cash >= 500_000 { unlocked.insert(9) }
        if state.totalFishSold >= 1000 { unlocked.insert(10) }
        if state.assignments[7]?.isEmpty == false { unlocked.insert(11) }
        state.awardsUnlocked = Array(unlocked).sorted()
    }

    func setOnboardingSeen() {
        state.onboardingSeen = true
        persist()
    }
}
