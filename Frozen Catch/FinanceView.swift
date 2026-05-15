import SwiftUI

struct FinanceView: View {
    @EnvironmentObject var store: FrozenCatchStore
    @State private var loanAmount: Double = 100_000
    @State private var repayAmount: Double = 50_000

    var body: some View {
        ZStack {
            FrozenCatchPalette.jet.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 14) {
                    FrozenCatchStatusBar()

                    HStack(spacing: 10) {
                        cashCard
                        debtCard
                    }

                    FrozenCatchPanel {
                        HStack {
                            Text("WEEKLY NET — last \(min(store.state.netHistory.count, 60)) weeks")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
                            Spacer()
                        }
                        netChart
                            .frame(height: 130)
                    }

                    FrozenCatchPanel {
                        Text("WEEKLY EXPENSES")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
                        expenseLine("Salaries", value: store.weeklySalaryTotal, color: FrozenCatchPalette.alertRed)
                        expenseLine("Gear Maintenance", value: store.weeklyMaintenanceTotal, color: FrozenCatchPalette.sodiumGold)
                        expenseLine("Loan Interest", value: store.weeklyInterest, color: FrozenCatchPalette.alertRed)
                        Divider().background(FrozenCatchPalette.slate)
                        expenseLine("Forager Passive Income", value: -store.foragerPassive, color: FrozenCatchPalette.frostMint)
                    }

                    FrozenCatchPanel {
                        Text("GEAR UPGRADES")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
                        ForEach(FrozenCatchCatalog.gear) { g in
                            gearRow(g)
                        }
                    }

                    FrozenCatchPanel {
                        Text("LOANS")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Outstanding")
                                    .font(.system(size: 11)).foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
                                Text(formatCash(store.state.debt))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(store.state.debt > 0 ? FrozenCatchPalette.alertRed : FrozenCatchPalette.ivory.opacity(0.55))
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Rate")
                                    .font(.system(size: 11)).foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
                                Text("0.8% / wk")
                                    .font(.system(size: 13, weight: .semibold)).foregroundColor(FrozenCatchPalette.sodiumGold)
                            }
                        }
                        .padding(.bottom, 4)

                        Text("Borrow")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.6))
                            .padding(.top, 4)
                        HStack(spacing: 6) {
                            ForEach([50_000.0, 100_000.0, 250_000.0, 500_000.0, 1_000_000.0], id: \.self) { q in
                                Button(action: { loanAmount = q }) {
                                    Text(formatCash(q))
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(loanAmount == q ? FrozenCatchPalette.jet : FrozenCatchPalette.ivory)
                                        .padding(.horizontal, 8).padding(.vertical, 6)
                                        .background(RoundedRectangle(cornerRadius: 7).fill(loanAmount == q ? FrozenCatchPalette.sodiumGold : FrozenCatchPalette.panelElev))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        // C2: guard against inverted Slider ClosedRange when debt approaches the cap.
                        let borrowLower: Double = 10_000
                        let borrowUpper: Double = max(borrowLower + 1_000,
                                                      min(2_000_000,
                                                          2_000_000 - store.state.debt + 10_000))
                        if store.state.debt >= 1_990_000 {
                            HStack {
                                Text("Loan cap reached")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(FrozenCatchPalette.alertRed)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        } else {
                            Slider(value: $loanAmount, in: borrowLower...borrowUpper, step: 5_000)
                                .accentColor(FrozenCatchPalette.sodiumGold)
                            HStack {
                                Text("Take Loan \(formatCash(loanAmount))")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.75))
                                Spacer()
                                Button(action: { store.takeLoan(loanAmount) }) {
                                    Text("Borrow")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(FrozenCatchPalette.jet)
                                        .padding(.horizontal, 16).padding(.vertical, 8)
                                        .background(RoundedRectangle(cornerRadius: 9).fill(FrozenCatchPalette.sodiumGold))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        if store.state.debt > 0 && store.state.cash > 0 {
                            Text("Repay")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.6))
                                .padding(.top, 8)
                            let repayLower: Double = 1_000
                            let repayUpper: Double = max(repayLower + 1_000,
                                                         min(store.state.debt, max(store.state.cash, 0)))
                            Slider(value: $repayAmount, in: repayLower...repayUpper, step: 1_000)
                                .accentColor(FrozenCatchPalette.frostMint)
                            HStack {
                                Text("Repay \(formatCash(repayAmount))")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.75))
                                Spacer()
                                Button(action: { store.repayLoan(repayAmount) }) {
                                    Text("Repay")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(FrozenCatchPalette.jet)
                                        .padding(.horizontal, 16).padding(.vertical, 8)
                                        .background(RoundedRectangle(cornerRadius: 9).fill(FrozenCatchPalette.frostMint))
                                }
                                .buttonStyle(PlainButtonStyle())
                                Button(action: { store.repayLoan(store.state.debt) }) {
                                    Text("All")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(FrozenCatchPalette.frostMint)
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(RoundedRectangle(cornerRadius: 9).fill(FrozenCatchPalette.frostMint.opacity(0.18)))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        } else if store.state.debt > 0 {
                            Text("Repay unavailable — cash depleted")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(FrozenCatchPalette.alertRed)
                                .padding(.top, 8)
                        }
                    }
                }
                .padding(14)
            }
        }
        .navigationBarTitle("Finance", displayMode: .inline)
    }

    @ViewBuilder
    private var cashCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                CoinShape().fill(FrozenCatchPalette.sodiumGold).frame(width: 16, height: 16)
                Text("Cash on Hand")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.6))
            }
            Text(formatCash(store.state.cash))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(FrozenCatchPalette.sodiumGold)
            Text("Available funds")
                .font(.system(size: 10))
                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.45))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(FrozenCatchPalette.panel))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(FrozenCatchPalette.sodiumGold.opacity(0.4), lineWidth: 0.8))
    }

    @ViewBuilder
    private var debtCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                BanknoteShape().fill(FrozenCatchPalette.alertRed).frame(width: 16, height: 14)
                Text("Outstanding Debt")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.6))
            }
            Text(formatCash(store.state.debt))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(store.state.debt > 0 ? FrozenCatchPalette.alertRed : FrozenCatchPalette.ivory.opacity(0.5))
            Text("Interest 0.8% /wk")
                .font(.system(size: 10))
                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.45))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(FrozenCatchPalette.panel))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(FrozenCatchPalette.alertRed.opacity(store.state.debt > 0 ? 0.4 : 0.2), lineWidth: 0.8))
    }

    @ViewBuilder
    private var netChart: some View {
        GeometryReader { geo in
            let history = store.state.netHistory
            if history.isEmpty {
                Text("No history. Advance a week to begin tracking.")
                    .font(.system(size: 12))
                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.45))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let maxVal = (history.map { abs($0) }.max() ?? 1) + 1
                let zeroY = geo.size.height / 2

                ZStack {
                    // baseline
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: zeroY))
                        p.addLine(to: CGPoint(x: geo.size.width, y: zeroY))
                    }
                    .stroke(FrozenCatchPalette.slate.opacity(0.7), style: StrokeStyle(lineWidth: 0.8, dash: [3, 3]))

                    // line stroke
                    Path { p in
                        for (i, v) in history.enumerated() {
                            let x = CGFloat(i) * (geo.size.width / CGFloat(max(history.count - 1, 1)))
                            let y = zeroY - CGFloat(v / maxVal) * (zeroY - 6)
                            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                            else { p.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(FrozenCatchPalette.frostMint, lineWidth: 1.8)

                    // dots at sample points
                    ForEach(0..<history.count, id: \.self) { i in
                        let x = CGFloat(i) * (geo.size.width / CGFloat(max(history.count - 1, 1)))
                        let v = history[i]
                        let y = zeroY - CGFloat(v / maxVal) * (zeroY - 6)
                        Circle()
                            .fill(v >= 0 ? FrozenCatchPalette.frostMint : FrozenCatchPalette.alertRed)
                            .frame(width: 3, height: 3)
                            .position(x: x, y: y)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func expenseLine(_ name: String, value: Double, color: Color) -> some View {
        HStack {
            Text(name).font(.system(size: 12)).foregroundColor(FrozenCatchPalette.ivory.opacity(0.7))
            Spacer()
            Text(formatCash(value))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func gearRow(_ g: FrozenCatchGear) -> some View {
        let lvl = store.state.gearTiers[g.id]
        let cost = store.gearCost(idx: g.id)
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(FrozenCatchPalette.steelBlue).frame(width: 38, height: 38)
                CubeShape().stroke(FrozenCatchPalette.sodiumGold, lineWidth: 1.6).frame(width: 22, height: 22)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(g.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(FrozenCatchPalette.ivory)
                Text(g.blurb)
                    .font(.system(size: 10))
                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
                HStack(spacing: 3) {
                    ForEach(0..<12, id: \.self) { i in
                        Rectangle()
                            .fill(i < lvl ? FrozenCatchPalette.sodiumGold : FrozenCatchPalette.panelElev)
                            .frame(width: 6, height: 5)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("L\(lvl)/12")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(FrozenCatchPalette.frostMint)
                if lvl < 12 {
                    Button(action: { store.upgradeGear(idx: g.id) }) {
                        Text(formatCash(cost))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(store.state.cash >= cost ? FrozenCatchPalette.jet : FrozenCatchPalette.ivory.opacity(0.4))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(store.state.cash >= cost ? FrozenCatchPalette.sodiumGold : FrozenCatchPalette.slate.opacity(0.4)))
                    }
                    .disabled(store.state.cash < cost)
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Text("MAX")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(FrozenCatchPalette.frostMint)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
