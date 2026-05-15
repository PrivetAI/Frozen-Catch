import SwiftUI

// MARK: - Palette
enum FrozenCatchPalette {
    static let jet = Color(red: 0.059, green: 0.071, blue: 0.090)        // #0F1217
    static let steelBlue = Color(red: 0.169, green: 0.282, blue: 0.388)   // #2B4863
    static let sodiumGold = Color(red: 0.882, green: 0.713, blue: 0.259)  // #E1B642
    static let frostMint = Color(red: 0.345, green: 0.851, blue: 0.698)   // #58D9B2
    static let alertRed = Color(red: 0.820, green: 0.294, blue: 0.247)    // #D14B3F
    static let ivory = Color(red: 0.910, green: 0.902, blue: 0.878)       // #E8E6E0
    static let slate = Color(red: 0.290, green: 0.353, blue: 0.431)       // #4A5A6E

    static let panel = Color(red: 0.118, green: 0.149, blue: 0.196)
    static let panelElev = Color(red: 0.145, green: 0.180, blue: 0.235)
}

// MARK: - Worker
enum FrozenCatchWorkerClass: Int, Codable, CaseIterable {
    case junior = 0, hauler, master, forager, foreman

    var label: String {
        switch self {
        case .junior:  return "Junior"
        case .hauler:  return "Hauler"
        case .master:  return "Master"
        case .forager: return "Forager"
        case .foreman: return "Foreman"
        }
    }

    var baseSalary: Double {
        switch self {
        case .junior:  return 380
        case .hauler:  return 520
        case .master:  return 720
        case .forager: return 460
        case .foreman: return 880
        }
    }

    var baseSkill: Double {
        switch self {
        case .junior:  return 22
        case .hauler:  return 34
        case .master:  return 52
        case .forager: return 28
        case .foreman: return 44
        }
    }

    var baseEndurance: Double {
        switch self {
        case .junior:  return 30
        case .hauler:  return 60
        case .master:  return 40
        case .forager: return 50
        case .foreman: return 70
        }
    }
}

enum FrozenCatchWorkerRank: Int, Codable, CaseIterable {
    case I = 0, II, III, IV

    var label: String {
        switch self {
        case .I:   return "I"
        case .II:  return "II"
        case .III: return "III"
        case .IV:  return "IV"
        }
    }

    var statMult: Double {
        switch self {
        case .I:   return 1.0
        case .II:  return 1.45
        case .III: return 2.1025
        case .IV:  return 3.04863
        }
    }

    var salaryMult: Double {
        switch self {
        case .I:   return 1.0
        case .II:  return 1.5
        case .III: return 2.25
        case .IV:  return 3.375
        }
    }
}

enum FrozenCatchTrait: Int, Codable, CaseIterable {
    case patient = 0, greedy, lucky, tough, frail, drunkard, stoic, quick

    var label: String {
        switch self {
        case .patient:  return "Patient"
        case .greedy:   return "Greedy"
        case .lucky:    return "Lucky"
        case .tough:    return "Tough"
        case .frail:    return "Frail"
        case .drunkard: return "Drunkard"
        case .stoic:    return "Stoic"
        case .quick:    return "Quick"
        }
    }

    var blurb: String {
        switch self {
        case .patient:  return "+5% catch yield"
        case .greedy:   return "Slow morale drop"
        case .lucky:    return "+rare drop chance"
        case .tough:    return "-fatigue gain"
        case .frail:    return "+fatigue gain"
        case .drunkard: return "Random morale loss"
        case .stoic:    return "Morale resilience"
        case .quick:    return "Faster assignments"
        }
    }
}

struct FrozenCatchWorker: Identifiable, Codable, Equatable {
    var id: Int
    var name: String
    var classID: Int
    var rankID: Int
    var skill: Double
    var endurance: Double
    var morale: Double       // 0..100, starts 70
    var fatigue: Double      // 0..100, starts 0
    var salary: Double
    var traitID: Int
    var assignedLakeID: Int? // nil = unassigned
    var rested: Bool         // true if on rest this week

    var classObj: FrozenCatchWorkerClass { FrozenCatchWorkerClass(rawValue: classID) ?? .junior }
    var rankObj: FrozenCatchWorkerRank { FrozenCatchWorkerRank(rawValue: rankID) ?? .I }
    var traitObj: FrozenCatchTrait { FrozenCatchTrait(rawValue: traitID) ?? .patient }
}

// MARK: - Lake
struct FrozenCatchLake: Identifiable {
    let id: Int
    let name: String
    let requiredPrestige: Int   // 0 = D unlocked from start
    let capacity: Int
    let factor: Double
    let speciesPool: [Int]      // species IDs
    let blurb: String
    let position: CGPoint       // 0..1 coords on map
}

// MARK: - Fish
struct FrozenCatchFish: Identifiable {
    let id: Int
    let name: String
    let basePrice: Double
    let rarityWeight: Double    // higher = more common
}

// MARK: - Gear
struct FrozenCatchGear: Identifiable {
    let id: Int
    let name: String
    let blurb: String
    let baseCost: Double
}

// MARK: - Event
struct FrozenCatchEventDef: Identifiable {
    let id: Int
    let title: String
    let body: String
    let choices: [String]       // option texts
}

struct FrozenCatchEventEntry: Identifiable, Codable {
    var id: Int            // week + idx*1000
    var week: Int
    var eventID: Int
    var choice: Int
    var outcome: String
}

// MARK: - Research
struct FrozenCatchResearch: Identifiable {
    let id: Int
    let name: String
    let weeks: Int
    let cost: Double
    let blurb: String
    let prerequisites: [Int]
    let gridX: Int
    let gridY: Int
}

// MARK: - Prestige
struct FrozenCatchPrestigeTier {
    let id: Int
    let label: String
    let minPoints: Int
    let drawMult: Double
    let blurb: String
}

// MARK: - Achievement
struct FrozenCatchAward: Identifiable {
    let id: Int
    let title: String
    let blurb: String
    // condition handled in store
}

// MARK: - Static data
enum FrozenCatchCatalog {
    static let lakes: [FrozenCatchLake] = [
        FrozenCatchLake(id: 0, name: "Town Lake",          requiredPrestige: 0, capacity: 4, factor: 1.0, speciesPool: [0, 1, 2], blurb: "Quiet shore near the village. Steady but modest yields.",                             position: CGPoint(x: 0.22, y: 0.74)),
        FrozenCatchLake(id: 1, name: "North Bay",          requiredPrestige: 1, capacity: 5, factor: 1.4, speciesPool: [0, 1, 2, 3, 4], blurb: "Wider bay with mid-tier species. Some chop in the wind.",                          position: CGPoint(x: 0.52, y: 0.62)),
        FrozenCatchLake(id: 2, name: "Glacier Run",        requiredPrestige: 1, capacity: 4, factor: 1.8, speciesPool: [2, 3, 4, 5], blurb: "Glacier-fed channel. Rare species, storm risk.",                                       position: CGPoint(x: 0.78, y: 0.55)),
        FrozenCatchLake(id: 3, name: "Mossy Inlet",        requiredPrestige: 2, capacity: 6, factor: 2.2, speciesPool: [2, 3, 4, 5, 6], blurb: "Reed-fringed inlet. Slow regen, generous payouts.",                                position: CGPoint(x: 0.18, y: 0.42)),
        FrozenCatchLake(id: 4, name: "Iron Cape",          requiredPrestige: 2, capacity: 5, factor: 2.8, speciesPool: [4, 5, 6, 7], blurb: "Sheer cliffs. Ice-break risk for unsteady crews.",                                    position: CGPoint(x: 0.46, y: 0.38)),
        FrozenCatchLake(id: 5, name: "Aurora Strait",      requiredPrestige: 3, capacity: 6, factor: 3.6, speciesPool: [5, 6, 7, 8], blurb: "Aurora-lit narrows. Legendary species sighted here.",                                  position: CGPoint(x: 0.74, y: 0.30)),
        FrozenCatchLake(id: 6, name: "FrozenCatch Trench",  requiredPrestige: 4, capacity: 7, factor: 4.8, speciesPool: [4, 5, 6, 7, 8], blurb: "Deep, ancient water. Boss-class catches reported.",                                position: CGPoint(x: 0.28, y: 0.20)),
        FrozenCatchLake(id: 7, name: "Frozen Abyss",       requiredPrestige: 5, capacity: 8, factor: 6.5, speciesPool: [3, 4, 5, 6, 7, 8], blurb: "The frozen frontier. All species, rare drops, full risk.",                       position: CGPoint(x: 0.62, y: 0.12))
    ]

    static let fish: [FrozenCatchFish] = [
        FrozenCatchFish(id: 0, name: "Roach",     basePrice: 8,    rarityWeight: 100),
        FrozenCatchFish(id: 1, name: "Perch",     basePrice: 14,   rarityWeight: 85),
        FrozenCatchFish(id: 2, name: "Pike",      basePrice: 26,   rarityWeight: 60),
        FrozenCatchFish(id: 3, name: "Zander",    basePrice: 42,   rarityWeight: 40),
        FrozenCatchFish(id: 4, name: "Burbot",    basePrice: 68,   rarityWeight: 28),
        FrozenCatchFish(id: 5, name: "Whitefish", basePrice: 95,   rarityWeight: 22),
        FrozenCatchFish(id: 6, name: "Trout",     basePrice: 140,  rarityWeight: 15),
        FrozenCatchFish(id: 7, name: "Salmon",    basePrice: 220,  rarityWeight: 10),
        FrozenCatchFish(id: 8, name: "Sturgeon",  basePrice: 520,  rarityWeight: 4)
    ]

    static let gear: [FrozenCatchGear] = [
        FrozenCatchGear(id: 0, name: "Auger Set",       blurb: "+5% catch rate / level",        baseCost: 200),
        FrozenCatchGear(id: 1, name: "Tackle Set",      blurb: "+4% rare drop / level",         baseCost: 300),
        FrozenCatchGear(id: 2, name: "Insulated Coats", blurb: "-2% fatigue gain / level",      baseCost: 400),
        FrozenCatchGear(id: 3, name: "Sled Train",      blurb: "+1 slot after L6 / level",      baseCost: 800),
        FrozenCatchGear(id: 4, name: "Heated Tent",     blurb: "+3% morale recovery / level",   baseCost: 600)
    ]

    static let events: [FrozenCatchEventDef] = [
        FrozenCatchEventDef(id: 0,  title: "Storm Warning",       body: "A blizzard threatens one of the lakes. Cancel a lake for one week or push through?", choices: ["Cancel a lake", "Push through (-15% catch)", "Brave the storm (50% chance, x1.5)"]),
        FrozenCatchEventDef(id: 1,  title: "Poacher Raid",        body: "Poachers hit the ice overnight. They will take 10% of this week's catch unless you have Security.", choices: ["Accept the loss", "Hire defense ($1,000)"]),
        FrozenCatchEventDef(id: 2,  title: "Ice-Break Incident",  body: "An ice plate cracks under your crew. One worker takes a heavy fatigue hit.", choices: ["Send the crew home", "Rest the team (skip catch, all recover)"]),
        FrozenCatchEventDef(id: 3,  title: "Sponsor Visit",       body: "A regional sponsor wants to see the operation. Reception costs $500, but if your rank is B or higher you'll earn $3000.", choices: ["Host the sponsor", "Decline politely"]),
        FrozenCatchEventDef(id: 4,  title: "Inspector",           body: "An inspector arrives unannounced. They want to see the books and may issue a fine.", choices: ["Cooperate"]),
        FrozenCatchEventDef(id: 5,  title: "Black Market Buyer",  body: "A buyer offers triple the price for up to 50 units of fish, no questions asked.", choices: ["Sell to buyer", "Decline"]),
        FrozenCatchEventDef(id: 6,  title: "Folk Festival",       body: "The village holds a winter festival. All workers gain a morale boost.", choices: ["Join the festival", "Skip — workers don't celebrate"]),
        FrozenCatchEventDef(id: 7,  title: "Cold Snap",           body: "Temperatures plummet. Catch yields drop 30% this week, but rare drops climb 30%.", choices: ["Brave the cold", "Use heated tents"]),
        FrozenCatchEventDef(id: 8,  title: "Aurora Week",         body: "The aurora is bright and steady. Aurora Strait catch yield jumps 50% if it is unlocked.", choices: ["Acknowledge", "Save for later (x1.2 next 2 wk)"]),
        FrozenCatchEventDef(id: 9,  title: "Equipment Failure",   body: "A piece of gear breaks down. Repair will set you back unless you have Maintenance research.", choices: ["Repair the gear"]),
        FrozenCatchEventDef(id: 10, title: "Apprentice Arrives",  body: "A young apprentice asks to join the crew at no cost. They are Junior I but eager.", choices: ["Take them on", "Send them away"]),
        FrozenCatchEventDef(id: 11, title: "Sponsor Deal",        body: "A long-term sponsor offers +20% revenue for four weeks in exchange for 5% off each sale.", choices: ["Sign the deal", "Decline"])
    ]

    static let research: [FrozenCatchResearch] = [
        FrozenCatchResearch(id: 0,  name: "Sonar Use",         weeks: 3, cost: 40000,  blurb: "+10% catch on all lakes",                       prerequisites: [],         gridX: 0, gridY: 0),
        FrozenCatchResearch(id: 1,  name: "Heated Tent",       weeks: 4, cost: 80000,  blurb: "+5% morale recovery",                           prerequisites: [0],        gridX: 1, gridY: 0),
        FrozenCatchResearch(id: 2,  name: "Insulated Sled",    weeks: 5, cost: 150000, blurb: "+1 worker slot",                                 prerequisites: [1],        gridX: 2, gridY: 0),
        FrozenCatchResearch(id: 3,  name: "Smoked Fish",       weeks: 3, cost: 60000,  blurb: "+15% market price (kept inventory)",            prerequisites: [],         gridX: 0, gridY: 1),
        FrozenCatchResearch(id: 4,  name: "Caviar Press",      weeks: 5, cost: 200000, blurb: "Sturgeon premium tier unlocked",                prerequisites: [3],        gridX: 1, gridY: 1),
        FrozenCatchResearch(id: 5,  name: "Compliance Office", weeks: 2, cost: 30000,  blurb: "Immune to Inspector fines",                     prerequisites: [],         gridX: 0, gridY: 2),
        FrozenCatchResearch(id: 6,  name: "Security Hut",      weeks: 3, cost: 50000,  blurb: "Immune to Poacher raids",                       prerequisites: [],         gridX: 0, gridY: 3),
        FrozenCatchResearch(id: 7,  name: "Maintenance Crew",  weeks: 4, cost: 100000, blurb: "Free Equipment Failure repair",                 prerequisites: [],         gridX: 0, gridY: 4),
        FrozenCatchResearch(id: 8,  name: "Apprentice Program",weeks: 5, cost: 120000, blurb: "Apprentices arrive every 6 weeks",              prerequisites: [0],        gridX: 1, gridY: 5),
        FrozenCatchResearch(id: 9,  name: "Auction House",     weeks: 4, cost: 150000, blurb: "+30% market price weekly",                      prerequisites: [3],        gridX: 1, gridY: 2),
        FrozenCatchResearch(id: 10, name: "Forager Routes",    weeks: 3, cost: 70000,  blurb: "Foragers earn $200/week passively",             prerequisites: [],         gridX: 0, gridY: 5),
        FrozenCatchResearch(id: 11, name: "Frostsmith Atelier",weeks: 6, cost: 300000, blurb: "Gear upgrade costs -20%",                       prerequisites: [2],        gridX: 3, gridY: 0),
        FrozenCatchResearch(id: 12, name: "Sponsor Network",   weeks: 4, cost: 150000, blurb: "Sponsor deals appear more often",               prerequisites: [9],        gridX: 2, gridY: 2),
        FrozenCatchResearch(id: 13, name: "FrozenCatch Lab",    weeks: 6, cost: 400000, blurb: "FrozenCatch Trench gear bonus",                  prerequisites: [0, 11],    gridX: 4, gridY: 0),
        FrozenCatchResearch(id: 14, name: "Boss Charters",     weeks: 6, cost: 500000, blurb: "Frozen Abyss bonus rare drop",                  prerequisites: [13],       gridX: 5, gridY: 0),
        FrozenCatchResearch(id: 15, name: "Eternal Reserve",   weeks: 8, cost: 800000, blurb: "+25% prestige gain on next rank",               prerequisites: [14],       gridX: 6, gridY: 0)
    ]

    static let prestige: [FrozenCatchPrestigeTier] = [
        FrozenCatchPrestigeTier(id: 0, label: "D",     minPoints: 0,    drawMult: 1.00, blurb: "Starting tier"),
        FrozenCatchPrestigeTier(id: 1, label: "C",     minPoints: 50,   drawMult: 1.05, blurb: "+1 lake, +1 worker cap"),
        FrozenCatchPrestigeTier(id: 2, label: "B",     minPoints: 150,  drawMult: 1.10, blurb: "+2 lakes, +1 worker cap"),
        FrozenCatchPrestigeTier(id: 3, label: "A",     minPoints: 400,  drawMult: 1.20, blurb: "+1 lake, +1 worker cap"),
        FrozenCatchPrestigeTier(id: 4, label: "A+",    minPoints: 900,  drawMult: 1.30, blurb: "Lakes 6-7 visible"),
        FrozenCatchPrestigeTier(id: 5, label: "Elite", minPoints: 2000, drawMult: 1.40, blurb: "Frozen Abyss unlocked")
    ]

    static let awards: [FrozenCatchAward] = [
        FrozenCatchAward(id: 0,  title: "First Catch",     blurb: "Sell your first fish"),
        FrozenCatchAward(id: 1,  title: "Solid Roster",    blurb: "Hire 5 workers"),
        FrozenCatchAward(id: 2,  title: "First Lake",      blurb: "Assign workers to a lake"),
        FrozenCatchAward(id: 3,  title: "Rank C",          blurb: "Reach prestige rank C"),
        FrozenCatchAward(id: 4,  title: "Rank B",          blurb: "Reach prestige rank B"),
        FrozenCatchAward(id: 5,  title: "Rank A",          blurb: "Reach prestige rank A"),
        FrozenCatchAward(id: 6,  title: "Elite Operator",  blurb: "Reach Elite rank"),
        FrozenCatchAward(id: 7,  title: "Research Nut",    blurb: "Complete 3 research nodes"),
        FrozenCatchAward(id: 8,  title: "Geared Up",       blurb: "Reach level 6 on any gear"),
        FrozenCatchAward(id: 9,  title: "Big Pockets",     blurb: "Hold $500,000 cash"),
        FrozenCatchAward(id: 10, title: "Master Trader",   blurb: "Sell 1000 fish total"),
        FrozenCatchAward(id: 11, title: "Frozen Frontier", blurb: "Catch from Frozen Abyss")
    ]
}

// MARK: - GameState (Codable)
struct FrozenCatchGameState: Codable {
    var week: Int
    var cash: Double
    var debt: Double
    var gearTiers: [Int]                       // length 5
    var workers: [FrozenCatchWorker]                 // roster
    var candidates: [FrozenCatchWorker]              // 5 visible
    var namedPool: [FrozenCatchWorker]               // 32
    var candidatePoolSeed: UInt64
    var lastPoolRefreshWeek: Int
    var assignments: [Int: [Int]]              // lakeID → [workerID]
    var inventory: [Int: Int]                  // speciesID → units
    var marketPrices: [Double]                 // length 9
    var priceHistory: [[Double]]               // length 8 of 9
    var researchCompleted: [Int]               // set encoded as array
    var researchActive: Int?                   // research id
    var researchWeeksLeft: Int
    var eventsLog: [FrozenCatchEventEntry]
    var reputationPoints: Int
    var prestigeRank: Int
    var unlockedLakes: [Int]
    var netHistory: [Double]
    var totalFishSold: Int
    var awardsUnlocked: [Int]
    var onboardingSeen: Bool
    var soundOn: Bool
    var hapticsOn: Bool
    var sponsorDealWeeksLeft: Int              // active 4-week boost
    var pendingEventID: Int?                   // currently shown event
    var lastWeekResult: WeekResult?

    static func newGame() -> FrozenCatchGameState {
        let seed: UInt64 = UInt64(Date().timeIntervalSince1970)
        let pool = FrozenCatchStore.buildNamedPool(seed: seed)
        let initialCands = Array(pool.prefix(5))
        return FrozenCatchGameState(
            week: 1,
            cash: 250_000,
            debt: 0,
            gearTiers: [0, 0, 0, 0, 0],
            workers: [],
            candidates: initialCands,
            namedPool: pool,
            candidatePoolSeed: seed,
            lastPoolRefreshWeek: 1,
            assignments: [:],
            inventory: [:],
            marketPrices: FrozenCatchCatalog.fish.map { $0.basePrice },
            priceHistory: [],
            researchCompleted: [],
            researchActive: nil,
            researchWeeksLeft: 0,
            eventsLog: [],
            reputationPoints: 0,
            prestigeRank: 0,
            unlockedLakes: [0],
            netHistory: [],
            totalFishSold: 0,
            awardsUnlocked: [],
            onboardingSeen: false,
            soundOn: true,
            hapticsOn: true,
            sponsorDealWeeksLeft: 0,
            pendingEventID: nil,
            lastWeekResult: nil
        )
    }
}

// MARK: - Weekly result snapshot
struct WeekResult: Codable {
    var week: Int
    var perWorkerCatches: [WorkerCatch]
    var revenue: Double
    var expenses: Double
    var net: Double
    var prestigeDelta: Int
    var eventsTriggered: [Int]        // event def IDs
}

struct WorkerCatch: Codable, Identifiable {
    var id: Int                        // worker id
    var workerName: String
    var lakeName: String
    var units: Int
    var primarySpeciesID: Int
}

// MARK: - Seedable RNG
struct FrozenCatchRNG {
    var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0xdeadbeef : seed }

    mutating func next() -> UInt64 {
        // xorshift64*
        var x = state
        x ^= x >> 12
        x ^= x << 25
        x ^= x >> 27
        state = x
        return x &* 2685821657736338717
    }

    mutating func unit() -> Double {
        let u = next()
        return Double(u % 1_000_000) / 1_000_000.0
    }

    mutating func range(_ low: Double, _ high: Double) -> Double {
        return low + (high - low) * unit()
    }

    mutating func intRange(_ low: Int, _ high: Int) -> Int {
        if high <= low { return low }
        let span = UInt64(high - low + 1)
        return low + Int(next() % span)
    }

    mutating func weightedPick(_ weights: [Double]) -> Int {
        let total = weights.reduce(0, +)
        let r = unit() * total
        var acc = 0.0
        for (i, w) in weights.enumerated() {
            acc += w
            if r <= acc { return i }
        }
        return weights.count - 1
    }
}
