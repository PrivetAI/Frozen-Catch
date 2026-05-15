import SwiftUI

struct MarketView: View {
    @EnvironmentObject var store: FrozenCatchStore

    var body: some View {
        ZStack {
            FrozenCatchPalette.jet.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 14) {
                    FrozenCatchStatusBar()

                    FrozenCatchPanel {
                        Text("MARKET DEMAND")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
                        Text("Prices fluctuate weekly within a 25% band around base value. Stocked fish stay in inventory until sold.")
                            .font(.system(size: 12))
                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.6))
                            .lineSpacing(2)
                    }

                    ForEach(FrozenCatchCatalog.fish) { fish in
                        speciesRow(fish)
                    }

                    FrozenCatchPanel {
                        Text("PRICE HISTORY (last 8 weeks)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
                        priceHistoryGrid
                    }
                }
                .padding(14)
            }
        }
        .navigationBarTitle("Market", displayMode: .inline)
    }

    @ViewBuilder
    private func speciesRow(_ fish: FrozenCatchFish) -> some View {
        let price = store.state.marketPrices[fish.id]
        let prior = store.state.priceHistory.last?[fish.id] ?? fish.basePrice
        let deltaPct = ((price - prior) / max(prior, 0.01)) * 100
        let inv = store.state.inventory[fish.id] ?? 0

        FrozenCatchPanel {
            HStack(spacing: 12) {
                ZStack {
                    HexagonShape().fill(speciesColor(fish.id)).frame(width: 36, height: 36)
                    Text("\(fish.id + 1)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(FrozenCatchPalette.jet)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(fish.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.ivory)
                        if deltaPct > 1 {
                            HStack(spacing: 3) {
                                ArrowUpShape().fill(FrozenCatchPalette.frostMint).frame(width: 8, height: 10)
                                Text("\(String(format: "%.1f", deltaPct))%")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(FrozenCatchPalette.frostMint)
                            }
                        } else if deltaPct < -1 {
                            HStack(spacing: 3) {
                                ArrowDownShape().fill(FrozenCatchPalette.alertRed).frame(width: 8, height: 10)
                                Text("\(String(format: "%.1f", deltaPct))%")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(FrozenCatchPalette.alertRed)
                            }
                        } else {
                            MinusShape().stroke(FrozenCatchPalette.ivory.opacity(0.55), lineWidth: 1.5).frame(width: 10, height: 4)
                        }
                    }
                    Text("Stock: \(inv) units")
                        .font(.system(size: 11))
                        .foregroundColor(FrozenCatchPalette.ivory.opacity(0.6))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(String(format: "%.1f", price))")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(FrozenCatchPalette.sodiumGold)
                    Text("base $\(Int(fish.basePrice))")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(FrozenCatchPalette.ivory.opacity(0.45))
                }
            }
            SellControlsRow(speciesID: fish.id, maxUnits: inv)
                .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var priceHistoryGrid: some View {
        let history = store.state.priceHistory
        if history.isEmpty {
            Text("No history yet. Advance a week.")
                .font(.system(size: 12))
                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.45))
                .padding(.vertical, 6)
        } else {
            VStack(spacing: 6) {
                ForEach(FrozenCatchCatalog.fish) { f in
                    HStack(spacing: 6) {
                        Text(f.name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.7))
                            .frame(width: 72, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .bottomLeading) {
                                ForEach(0..<history.count, id: \.self) { wk in
                                    let prices = history[wk]
                                    if f.id < prices.count {
                                        let height = CGFloat(prices[f.id] / (f.basePrice * 1.5)) * geo.size.height
                                        Rectangle()
                                            .fill(FrozenCatchPalette.frostMint.opacity(0.5))
                                            .frame(width: max(3, geo.size.width / CGFloat(8) - 2), height: height)
                                            .offset(x: CGFloat(wk) * (geo.size.width / 8), y: 0)
                                    }
                                }
                            }
                            .frame(height: 22)
                        }
                        .frame(height: 22)
                    }
                }
            }
        }
    }

    private func speciesColor(_ id: Int) -> Color {
        switch id {
        case 0: return Color(red: 0.65, green: 0.69, blue: 0.74)
        case 1: return Color(red: 0.40, green: 0.55, blue: 0.62)
        case 2: return Color(red: 0.45, green: 0.62, blue: 0.36)
        case 3: return Color(red: 0.71, green: 0.55, blue: 0.36)
        case 4: return Color(red: 0.79, green: 0.65, blue: 0.36)
        case 5: return Color(red: 0.66, green: 0.86, blue: 0.84)
        case 6: return Color(red: 0.84, green: 0.55, blue: 0.46)
        case 7: return Color(red: 0.88, green: 0.41, blue: 0.39)
        case 8: return FrozenCatchPalette.sodiumGold
        default: return FrozenCatchPalette.ivory
        }
    }
}

struct SellControlsRow: View {
    let speciesID: Int
    let maxUnits: Int
    @EnvironmentObject var store: FrozenCatchStore
    @State private var qty: Double = 0

    var body: some View {
        HStack(spacing: 10) {
            if maxUnits > 0 {
                Slider(value: $qty, in: 0...Double(maxUnits), step: 1)
                    .accentColor(FrozenCatchPalette.sodiumGold)
                Text("\(Int(qty))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(FrozenCatchPalette.sodiumGold)
                    .frame(width: 32, alignment: .trailing)
                Button(action: {
                    store.sellSpecies(speciesID: speciesID, units: Int(qty))
                    qty = 0
                }) {
                    Text("Sell")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(FrozenCatchPalette.jet)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(qty > 0 ? FrozenCatchPalette.sodiumGold : FrozenCatchPalette.slate.opacity(0.5)))
                }
                .disabled(qty < 1)
                .buttonStyle(PlainButtonStyle())
                Button(action: {
                    store.sellSpecies(speciesID: speciesID, units: maxUnits)
                    qty = 0
                }) {
                    Text("All")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(FrozenCatchPalette.frostMint)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(FrozenCatchPalette.frostMint.opacity(0.18)))
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Text("No stock to sell")
                    .font(.system(size: 11))
                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.4))
            }
        }
    }
}
