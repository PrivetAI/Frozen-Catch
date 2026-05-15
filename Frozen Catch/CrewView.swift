import SwiftUI

struct CrewView: View {
    @EnvironmentObject var store: FrozenCatchStore
    @State private var detailWorkerID: Int? = nil

    var body: some View {
        ZStack {
            FrozenCatchPalette.jet.edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    FrozenCatchStatusBar()

                    headerStrip

                    sectionLabel("ROSTER  \(store.state.workers.count)/\(store.rosterCap)")
                    if store.state.workers.isEmpty {
                        emptyHint("No workers hired yet. Pick from the candidate pool below.")
                    } else {
                        ForEach(store.state.workers) { w in
                            workerRow(w) { detailWorkerID = w.id }
                        }
                    }

                    sectionLabel("CANDIDATES  refresh in \(weeksUntilRefresh) wk")
                    if store.state.candidates.isEmpty {
                        emptyHint("Pool empty. Wait for the next refresh cycle.")
                    } else {
                        ForEach(store.state.candidates) { w in
                            candidateRow(w)
                        }
                    }
                }
                .padding(14)
            }
        }
        .navigationBarTitle("Crew", displayMode: .inline)
        .sheet(item: Binding<WorkerIDWrap?>(
            get: { detailWorkerID.map { WorkerIDWrap(id: $0) } },
            set: { detailWorkerID = $0?.id }
        )) { wrap in
            WorkerDetailSheet(workerID: wrap.id, dismiss: { detailWorkerID = nil })
                .environmentObject(store)
        }
    }

    private var weeksUntilRefresh: Int {
        max(0, 4 - (store.state.week - store.state.lastPoolRefreshWeek))
    }

    @ViewBuilder
    private var headerStrip: some View {
        HStack(spacing: 10) {
            statBlock(label: "Roster", value: "\(store.state.workers.count)/\(store.rosterCap)", color: FrozenCatchPalette.frostMint)
            statBlock(label: "Salaries", value: formatCash(store.weeklySalaryTotal), color: FrozenCatchPalette.sodiumGold)
            statBlock(label: "Forager$/wk", value: formatCash(store.foragerPassive), color: FrozenCatchPalette.ivory)
        }
    }

    @ViewBuilder
    private func statBlock(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
            Text(value).font(.system(size: 14, weight: .semibold)).foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(FrozenCatchPalette.panel))
    }

    @ViewBuilder
    private func sectionLabel(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
            .padding(.leading, 4)
            .padding(.top, 4)
    }

    @ViewBuilder
    private func emptyHint(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 12))
            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.45))
            .padding(10)
    }

    @ViewBuilder
    private func workerRow(_ w: FrozenCatchWorker, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(FrozenCatchPalette.steelBlue).frame(width: 42, height: 42)
                    PersonSilhouetteShape().fill(FrozenCatchPalette.ivory).frame(width: 22, height: 28)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(w.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.ivory)
                        Text("\(w.classObj.label) \(w.rankObj.label)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.sodiumGold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(FrozenCatchPalette.sodiumGold.opacity(0.15)))
                    }
                    HStack(spacing: 6) {
                        miniPill("Skill", "\(Int(w.skill))", FrozenCatchPalette.frostMint)
                        miniPill("End", "\(Int(w.endurance))", FrozenCatchPalette.ivory.opacity(0.85))
                        miniPill("Mor", "\(Int(w.morale))", FrozenCatchPalette.frostMint)
                        miniPill("Fat", "\(Int(w.fatigue))", w.fatigue > 70 ? FrozenCatchPalette.alertRed : FrozenCatchPalette.ivory.opacity(0.85))
                    }
                    HStack(spacing: 6) {
                        Text(w.traitObj.label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(FrozenCatchPalette.frostMint)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(FrozenCatchPalette.frostMint.opacity(0.12)))
                        if w.rested {
                            Text("Resting")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(FrozenCatchPalette.alertRed)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(FrozenCatchPalette.alertRed.opacity(0.18)))
                        }
                        if let lid = w.assignedLakeID, lid >= 0, lid < FrozenCatchCatalog.lakes.count {
                            Text("@ \(FrozenCatchCatalog.lakes[lid].name)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.65))
                        }
                        Spacer()
                        Text("$\(Int(w.salary))/wk")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.sodiumGold)
                    }
                }
                ChevronShape()
                    .stroke(FrozenCatchPalette.ivory.opacity(0.5), lineWidth: 2)
                    .frame(width: 10, height: 14)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(FrozenCatchPalette.panel))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(FrozenCatchPalette.slate.opacity(0.4), lineWidth: 0.8))
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func candidateRow(_ w: FrozenCatchWorker) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(FrozenCatchPalette.panelElev).frame(width: 40, height: 40)
                PersonSilhouetteShape().fill(FrozenCatchPalette.frostMint).frame(width: 20, height: 26)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(w.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(FrozenCatchPalette.ivory)
                    Text("\(w.classObj.label) \(w.rankObj.label)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(FrozenCatchPalette.sodiumGold)
                }
                HStack(spacing: 6) {
                    miniPill("Skill", "\(Int(w.skill))", FrozenCatchPalette.frostMint)
                    miniPill("End", "\(Int(w.endurance))", FrozenCatchPalette.ivory.opacity(0.85))
                    Text(w.traitObj.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(FrozenCatchPalette.frostMint)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(FrozenCatchPalette.frostMint.opacity(0.12)))
                }
                Text("$\(Int(w.salary))/wk")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(FrozenCatchPalette.sodiumGold)
            }
            Spacer()
            Button(action: {
                _ = store.hire(w)
            }) {
                HStack(spacing: 5) {
                    PlusShape().stroke(FrozenCatchPalette.jet, lineWidth: 2).frame(width: 10, height: 10)
                    Text("Hire")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(FrozenCatchPalette.jet)
                }
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 9).fill(canHire(w) ? FrozenCatchPalette.sodiumGold : FrozenCatchPalette.slate.opacity(0.5)))
            }
            .disabled(!canHire(w))
            .buttonStyle(PlainButtonStyle())
        }
        .padding(11)
        .background(RoundedRectangle(cornerRadius: 12).fill(FrozenCatchPalette.panelElev))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(FrozenCatchPalette.slate.opacity(0.35), lineWidth: 0.8))
    }

    private func canHire(_ w: FrozenCatchWorker) -> Bool {
        store.state.workers.count < store.rosterCap
    }

    @ViewBuilder
    private func miniPill(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label).font(.system(size: 9, weight: .medium)).foregroundColor(FrozenCatchPalette.ivory.opacity(0.5))
            Text(value).font(.system(size: 10, weight: .semibold)).foregroundColor(color)
        }
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(Capsule().fill(FrozenCatchPalette.panelElev))
    }
}

struct WorkerIDWrap: Identifiable { let id: Int }

// MARK: - Worker Detail
struct WorkerDetailSheet: View {
    let workerID: Int
    let dismiss: () -> Void
    @EnvironmentObject var store: FrozenCatchStore

    var w: FrozenCatchWorker? { store.state.workers.first { $0.id == workerID } }

    var body: some View {
        NavigationView {
            ZStack {
                FrozenCatchPalette.jet.edgesIgnoringSafeArea(.all)
                if let w = w {
                    ScrollView {
                        VStack(spacing: 14) {
                            // header
                            VStack(spacing: 10) {
                                ZStack {
                                    Circle().fill(FrozenCatchPalette.steelBlue).frame(width: 90, height: 90)
                                    PersonSilhouetteShape().fill(FrozenCatchPalette.ivory).frame(width: 46, height: 60)
                                }
                                Text(w.name)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(FrozenCatchPalette.ivory)
                                HStack(spacing: 8) {
                                    Text("\(w.classObj.label) \(w.rankObj.label)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(FrozenCatchPalette.sodiumGold)
                                        .padding(.horizontal, 9).padding(.vertical, 4)
                                        .background(Capsule().fill(FrozenCatchPalette.sodiumGold.opacity(0.15)))
                                    Text(w.traitObj.label)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(FrozenCatchPalette.frostMint)
                                        .padding(.horizontal, 9).padding(.vertical, 4)
                                        .background(Capsule().fill(FrozenCatchPalette.frostMint.opacity(0.15)))
                                }
                                Text(w.traitObj.blurb)
                                    .font(.system(size: 12))
                                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.6))
                            }
                            .padding(.top, 10)

                            // stats grid
                            FrozenCatchPanel {
                                Text("STATISTICS")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
                                statBar(label: "Skill", value: w.skill, color: FrozenCatchPalette.frostMint)
                                statBar(label: "Endurance", value: w.endurance, color: FrozenCatchPalette.ivory.opacity(0.85))
                                statBar(label: "Morale", value: w.morale, color: FrozenCatchPalette.frostMint)
                                statBar(label: "Fatigue", value: w.fatigue, color: w.fatigue > 70 ? FrozenCatchPalette.alertRed : FrozenCatchPalette.sodiumGold)
                                HStack {
                                    Text("Weekly salary")
                                        .font(.system(size: 12))
                                        .foregroundColor(FrozenCatchPalette.ivory.opacity(0.65))
                                    Spacer()
                                    Text("$\(Int(w.salary))")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(FrozenCatchPalette.sodiumGold)
                                }
                                if let lid = w.assignedLakeID, lid >= 0, lid < FrozenCatchCatalog.lakes.count {
                                    HStack {
                                        Text("Assigned to")
                                            .font(.system(size: 12))
                                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.65))
                                        Spacer()
                                        Text(FrozenCatchCatalog.lakes[lid].name)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(FrozenCatchPalette.frostMint)
                                    }
                                }
                                if w.rested {
                                    HStack {
                                        Text("Status")
                                            .font(.system(size: 12))
                                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.65))
                                        Spacer()
                                        Text("Resting")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(FrozenCatchPalette.alertRed)
                                    }
                                }
                            }

                            // actions
                            VStack(spacing: 9) {
                                actionButton(title: w.rested ? "End Rest" : "Send to Rest", color: FrozenCatchPalette.frostMint) {
                                    store.toggleRest(workerID)
                                }
                                if w.rankID < FrozenCatchWorkerRank.IV.rawValue {
                                    actionButton(title: "Promote ($\(Int(w.salary * 4)))", color: FrozenCatchPalette.sodiumGold, enabled: store.state.cash >= w.salary * 4) {
                                        store.promote(workerID)
                                    }
                                }
                                actionButton(title: "Dismiss", color: FrozenCatchPalette.alertRed) {
                                    store.fire(workerID)
                                    dismiss()
                                }
                            }
                            .padding(.top, 6)
                        }
                        .padding(14)
                    }
                } else {
                    Text("Worker not found.").foregroundColor(FrozenCatchPalette.ivory)
                }
            }
            .navigationBarTitle("Worker", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: dismiss) {
                Text("Done")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FrozenCatchPalette.sodiumGold)
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(FrozenCatchPalette.sodiumGold)
    }

    @ViewBuilder
    private func statBar(label: String, value: Double, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.65))
                .frame(width: 80, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(FrozenCatchPalette.panelElev).frame(height: 6)
                    Capsule().fill(color).frame(width: geo.size.width * CGFloat(value / 100), height: 6)
                }
            }
            .frame(height: 8)
            Text("\(Int(value))")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 30, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func actionButton(title: String, color: Color, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: { if enabled { action() } }) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(enabled ? FrozenCatchPalette.jet : FrozenCatchPalette.ivory.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 11).fill(enabled ? color : FrozenCatchPalette.slate.opacity(0.4)))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!enabled)
    }
}
