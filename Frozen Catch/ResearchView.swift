import SwiftUI

struct ResearchView: View {
    @EnvironmentObject var store: FrozenCatchStore
    @State private var detailNodeID: Int? = nil

    var body: some View {
        ZStack {
            FrozenCatchPalette.jet.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 14) {
                    FrozenCatchStatusBar()

                    if let active = store.state.researchActive,
                       active >= 0, active < FrozenCatchCatalog.research.count {
                        let r = FrozenCatchCatalog.research[active]
                        FrozenCatchPanel {
                            HStack {
                                Text("ACTIVE RESEARCH")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
                                Spacer()
                                Text("\(store.state.researchWeeksLeft) wk left")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(FrozenCatchPalette.sodiumGold)
                            }
                            Text(r.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(FrozenCatchPalette.ivory)
                            Text(r.blurb)
                                .font(.system(size: 12))
                                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.65))
                            GeometryReader { geo in
                                let pct: CGFloat = CGFloat(r.weeks - store.state.researchWeeksLeft) / CGFloat(max(r.weeks, 1))
                                ZStack(alignment: .leading) {
                                    Capsule().fill(FrozenCatchPalette.panelElev).frame(height: 8)
                                    Capsule().fill(FrozenCatchPalette.frostMint).frame(width: geo.size.width * pct, height: 8)
                                }
                            }
                            .frame(height: 10)
                        }
                    }

                    FrozenCatchPanel {
                        Text("RESEARCH TREE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))

                        ResearchGraph(detailNodeID: $detailNodeID)
                            .environmentObject(store)
                    }

                    FrozenCatchPanel {
                        Text("COMPLETED  \(store.state.researchCompleted.count) / \(FrozenCatchCatalog.research.count)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
                        if store.state.researchCompleted.isEmpty {
                            Text("No research completed yet.")
                                .font(.system(size: 12))
                                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.45))
                                .padding(.vertical, 4)
                        } else {
                            ForEach(store.state.researchCompleted.sorted(), id: \.self) { rid in
                                if rid >= 0, rid < FrozenCatchCatalog.research.count {
                                    HStack {
                                        CheckShape().stroke(FrozenCatchPalette.frostMint, lineWidth: 2).frame(width: 12, height: 10)
                                        Text(FrozenCatchCatalog.research[rid].name)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(FrozenCatchPalette.ivory)
                                        Spacer()
                                        Text(FrozenCatchCatalog.research[rid].blurb)
                                            .font(.system(size: 10))
                                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                }
                .padding(14)
            }
        }
        .navigationBarTitle("Research", displayMode: .inline)
        .sheet(item: Binding<ResearchIDWrap?>(
            get: { detailNodeID.map { ResearchIDWrap(id: $0) } },
            set: { detailNodeID = $0?.id }
        )) { wrap in
            ResearchDetailSheet(researchID: wrap.id, dismiss: { detailNodeID = nil })
                .environmentObject(store)
        }
    }
}

struct ResearchIDWrap: Identifiable { let id: Int }

struct ResearchGraph: View {
    @EnvironmentObject var store: FrozenCatchStore
    @Binding var detailNodeID: Int?

    // Lay out by gridX/gridY — column = gridX, row = gridY
    private let colW: CGFloat = 108
    private let rowH: CGFloat = 90
    private let nodeW: CGFloat = 90
    private let nodeH: CGFloat = 62

    var body: some View {
        let maxX = (FrozenCatchCatalog.research.map { $0.gridX }.max() ?? 0) + 1
        let maxY = (FrozenCatchCatalog.research.map { $0.gridY }.max() ?? 0) + 1
        let width = CGFloat(maxX) * colW
        let height = CGFloat(maxY) * rowH

        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                // edges
                Canvas { ctx, _ in
                    for r in FrozenCatchCatalog.research {
                        for prereqID in r.prerequisites {
                            let pre = FrozenCatchCatalog.research[prereqID]
                            let from = nodeCenter(pre)
                            let to = nodeCenter(r)
                            var path = Path()
                            path.move(to: from)
                            let midY = (from.y + to.y) / 2
                            path.addCurve(
                                to: to,
                                control1: CGPoint(x: from.x + 30, y: midY),
                                control2: CGPoint(x: to.x - 30, y: midY)
                            )
                            ctx.stroke(path, with: .color(edgeColor(pre: pre, post: r)), lineWidth: 1.5)
                        }
                    }
                }
                .frame(width: width, height: height)

                ForEach(FrozenCatchCatalog.research) { r in
                    nodeView(r)
                        .position(nodeCenter(r))
                }
            }
            .frame(width: width, height: height)
            .padding(.vertical, 6)
        }
    }

    private func nodeCenter(_ r: FrozenCatchResearch) -> CGPoint {
        CGPoint(
            x: CGFloat(r.gridX) * colW + nodeW / 2 + 8,
            y: CGFloat(r.gridY) * rowH + nodeH / 2 + 6
        )
    }

    private func edgeColor(pre: FrozenCatchResearch, post: FrozenCatchResearch) -> Color {
        if store.state.researchCompleted.contains(post.id) {
            return FrozenCatchPalette.frostMint.opacity(0.8)
        } else if store.state.researchCompleted.contains(pre.id) {
            return FrozenCatchPalette.sodiumGold.opacity(0.7)
        } else {
            return FrozenCatchPalette.slate.opacity(0.6)
        }
    }

    @ViewBuilder
    private func nodeView(_ r: FrozenCatchResearch) -> some View {
        let completed = store.state.researchCompleted.contains(r.id)
        let active = store.state.researchActive == r.id
        let prereqsDone = r.prerequisites.allSatisfy { store.state.researchCompleted.contains($0) }
        let canStart = !completed && !active && prereqsDone

        Button(action: { detailNodeID = r.id }) {
            VStack(spacing: 4) {
                Text(r.name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(textColor(completed: completed, active: active, canStart: canStart))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                HStack(spacing: 4) {
                    Text("$\(Int(r.cost / 1000))K")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(FrozenCatchPalette.sodiumGold)
                    Text("·")
                        .foregroundColor(FrozenCatchPalette.ivory.opacity(0.5))
                    Text("\(r.weeks)w")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(FrozenCatchPalette.frostMint)
                }
            }
            .padding(6)
            .frame(width: nodeW, height: nodeH)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(bgColor(completed: completed, active: active, canStart: canStart))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor(completed: completed, active: active, canStart: canStart), lineWidth: 1.2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func bgColor(completed: Bool, active: Bool, canStart: Bool) -> Color {
        if completed { return FrozenCatchPalette.frostMint.opacity(0.18) }
        if active { return FrozenCatchPalette.sodiumGold.opacity(0.18) }
        if canStart { return FrozenCatchPalette.panelElev }
        return FrozenCatchPalette.panel.opacity(0.6)
    }

    private func borderColor(completed: Bool, active: Bool, canStart: Bool) -> Color {
        if completed { return FrozenCatchPalette.frostMint }
        if active { return FrozenCatchPalette.sodiumGold }
        if canStart { return FrozenCatchPalette.slate }
        return FrozenCatchPalette.slate.opacity(0.4)
    }

    private func textColor(completed: Bool, active: Bool, canStart: Bool) -> Color {
        if completed { return FrozenCatchPalette.frostMint }
        if active { return FrozenCatchPalette.sodiumGold }
        return canStart ? FrozenCatchPalette.ivory : FrozenCatchPalette.ivory.opacity(0.4)
    }
}

struct ResearchDetailSheet: View {
    let researchID: Int
    let dismiss: () -> Void
    @EnvironmentObject var store: FrozenCatchStore

    var r: FrozenCatchResearch? {
        guard researchID >= 0, researchID < FrozenCatchCatalog.research.count else { return nil }
        return FrozenCatchCatalog.research[researchID]
    }

    var body: some View {
        guard let r = r else { return AnyView(EmptyView()) }
        return AnyView(
        NavigationView {
            ZStack {
                FrozenCatchPalette.jet.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 14) {
                        ZStack {
                            HexagonShape().fill(FrozenCatchPalette.steelBlue).frame(width: 80, height: 80)
                            SquareStackShape().stroke(FrozenCatchPalette.sodiumGold, lineWidth: 2.4).frame(width: 36, height: 36)
                        }
                        .padding(.top, 10)

                        Text(r.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(FrozenCatchPalette.ivory)
                        Text(r.blurb)
                            .font(.system(size: 14))
                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.72))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)

                        FrozenCatchPanel {
                            HStack {
                                Text("Cost")
                                Spacer()
                                Text(formatCash(r.cost))
                                    .foregroundColor(FrozenCatchPalette.sodiumGold)
                            }
                            .font(.system(size: 13, weight: .medium))
                            HStack {
                                Text("Duration")
                                Spacer()
                                Text("\(r.weeks) weeks")
                                    .foregroundColor(FrozenCatchPalette.frostMint)
                            }
                            .font(.system(size: 13, weight: .medium))
                            HStack {
                                Text("Prerequisites")
                                Spacer()
                                Text(r.prerequisites.isEmpty ? "None" : r.prerequisites.compactMap { pid -> String? in
                                    guard pid >= 0, pid < FrozenCatchCatalog.research.count else { return nil }
                                    return FrozenCatchCatalog.research[pid].name
                                }.joined(separator: ", "))
                                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.8))
                                    .multilineTextAlignment(.trailing)
                            }
                            .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(FrozenCatchPalette.ivory.opacity(0.85))

                        if store.state.researchCompleted.contains(researchID) {
                            statusBanner("Completed", color: FrozenCatchPalette.frostMint)
                        } else if store.state.researchActive == researchID {
                            statusBanner("In Progress · \(store.state.researchWeeksLeft) wk", color: FrozenCatchPalette.sodiumGold)
                        } else {
                            Button(action: {
                                store.startResearch(researchID)
                                dismiss()
                            }) {
                                Text("Start Research")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(canStart ? FrozenCatchPalette.jet : FrozenCatchPalette.ivory.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .background(RoundedRectangle(cornerRadius: 11).fill(canStart ? FrozenCatchPalette.sodiumGold : FrozenCatchPalette.slate.opacity(0.4)))
                            }
                            .disabled(!canStart)
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(14)
                }
            }
            .navigationBarTitle("Research Node", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: dismiss) {
                Text("Done")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FrozenCatchPalette.sodiumGold)
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(FrozenCatchPalette.sodiumGold)
        )
    }

    var canStart: Bool { store.canStartResearch(researchID) }

    @ViewBuilder
    private func statusBanner(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 11).fill(color.opacity(0.18)))
    }
}
