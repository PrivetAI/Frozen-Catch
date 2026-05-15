import SwiftUI

struct MoreHubView: View {
    @EnvironmentObject var store: FrozenCatchStore

    var body: some View {
        ZStack {
            FrozenCatchPalette.jet.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 14) {
                    FrozenCatchStatusBar()

                    NavigationLink(destination: FinanceView().environmentObject(store)) {
                        hubRow(title: "Finance", subtitle: "Cash, debt, net history, gear upgrades, loans", icon: AnyView(CoinShape().fill(FrozenCatchPalette.sodiumGold)))
                    }
                    .buttonStyle(PlainButtonStyle())

                    NavigationLink(destination: AwardsView().environmentObject(store)) {
                        hubRow(title: "Awards", subtitle: "\(store.state.awardsUnlocked.count) of \(FrozenCatchCatalog.awards.count) unlocked", icon: AnyView(StarShape().fill(FrozenCatchPalette.sodiumGold)))
                    }
                    .buttonStyle(PlainButtonStyle())

                    NavigationLink(destination: HelpView().environmentObject(store)) {
                        hubRow(title: "Game Guide", subtitle: "How your crew works", icon: AnyView(BellShape().stroke(FrozenCatchPalette.frostMint, lineWidth: 1.8)))
                    }
                    .buttonStyle(PlainButtonStyle())

                    NavigationLink(destination: SettingsView().environmentObject(store)) {
                        hubRow(title: "Settings", subtitle: "Sound, haptics, reset, privacy", icon: AnyView(OctagonCogShape().fill(FrozenCatchPalette.ivory.opacity(0.85))))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(14)
            }
        }
        .navigationBarTitle("More", displayMode: .inline)
    }

    @ViewBuilder
    private func hubRow(title: String, subtitle: String, icon: AnyView) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(FrozenCatchPalette.panelElev).frame(width: 42, height: 42)
                icon.frame(width: 24, height: 24)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(FrozenCatchPalette.ivory)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
            }
            Spacer()
            ChevronShape().stroke(FrozenCatchPalette.ivory.opacity(0.55), lineWidth: 2).frame(width: 10, height: 14)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(FrozenCatchPalette.panel))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(FrozenCatchPalette.slate.opacity(0.4), lineWidth: 0.8))
    }
}

struct AwardsView: View {
    @EnvironmentObject var store: FrozenCatchStore

    var body: some View {
        ZStack {
            FrozenCatchPalette.jet.edgesIgnoringSafeArea(.all)
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(FrozenCatchCatalog.awards) { a in
                        awardCell(a)
                    }
                }
                .padding(14)
            }
        }
        .navigationBarTitle("Awards", displayMode: .inline)
    }

    @ViewBuilder
    private func awardCell(_ a: FrozenCatchAward) -> some View {
        let unlocked = store.state.awardsUnlocked.contains(a.id)
        VStack(spacing: 8) {
            ZStack {
                StarShape().fill(unlocked ? FrozenCatchPalette.sodiumGold : FrozenCatchPalette.slate.opacity(0.4))
                    .frame(width: 38, height: 38)
                if !unlocked {
                    PadlockShape().fill(FrozenCatchPalette.jet).frame(width: 16, height: 18)
                }
            }
            Text(a.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(unlocked ? FrozenCatchPalette.ivory : FrozenCatchPalette.ivory.opacity(0.4))
                .multilineTextAlignment(.center)
            Text(a.blurb)
                .font(.system(size: 10))
                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, minHeight: 130)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(FrozenCatchPalette.panel))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(unlocked ? FrozenCatchPalette.sodiumGold.opacity(0.4) : FrozenCatchPalette.slate.opacity(0.35), lineWidth: 0.8))
    }
}

struct HelpView: View {
    var body: some View {
        ZStack {
            FrozenCatchPalette.jet.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    helpSection(title: "The Loop", body: "Each in-game week you assign workers to lakes, advance time, sell catches to the market, manage events, and reinvest into gear, research, or new hires. The cycle continues until you reach Elite prestige.")

                    helpSection(title: "Workers", body: "Five classes (Junior, Hauler, Master, Forager, Foreman) across four ranks (I–IV). Each worker has skill, endurance, morale, fatigue, and one trait that nudges performance. High morale boosts output; high fatigue drags it.")

                    helpSection(title: "Lakes", body: "Eight lakes unlock as your prestige rank climbs. Higher tier lakes have larger factor multipliers and rarer species pools — but also bigger event risks. Sled Train gear adds a slot once it reaches level 6.")

                    helpSection(title: "Market", body: "Nine species rotate price ±25% weekly. Sell when prices are favorable. Smoked Fish, Auction House, and Sponsor research nodes layer permanent revenue bonuses.")

                    helpSection(title: "Research", body: "Sixteen nodes form a dependency graph. Each node consumes cash and takes a fixed number of weeks. Only one node may be active at a time.")

                    helpSection(title: "Loans", body: "Up to $2,000,000 outstanding. Interest accrues 0.8% per week onto the principal. Repay any time. Use loans to bootstrap gear or seed research.")

                    helpSection(title: "Prestige", body: "Reputation Points accrue from weekly performance, research and a healthy crew. Crossing thresholds promotes you through D, C, B, A, A+, and Elite — each unlocking new lakes and bigger multipliers.")

                    helpSection(title: "Events", body: "Random events fire most weeks. Choices have lasting consequences — Security research blocks Poachers, Compliance Office handles Inspectors, and Maintenance Crew repairs free of charge.")
                }
                .padding(14)
            }
        }
        .navigationBarTitle("Game Guide", displayMode: .inline)
    }

    @ViewBuilder
    private func helpSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(FrozenCatchPalette.sodiumGold)
            Text(body)
                .font(.system(size: 13))
                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.75))
                .lineSpacing(3)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(FrozenCatchPalette.panel))
    }
}
