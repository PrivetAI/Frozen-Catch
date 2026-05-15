import SwiftUI

enum MapSheet: Identifiable {
    case assignment(lakeID: Int)
    case weekResult
    case events
    case pendingEvent(eventID: Int)

    var id: String {
        switch self {
        case .assignment(let lid):     return "assignment-\(lid)"
        case .weekResult:              return "weekResult"
        case .events:                  return "events"
        case .pendingEvent(let eid):   return "pendingEvent-\(eid)"
        }
    }
}

struct MapView: View {
    @EnvironmentObject var store: FrozenCatchStore
    @State private var activeSheet: MapSheet? = nil

    var body: some View {
        ZStack {
            FrozenCatchPalette.jet.edgesIgnoringSafeArea(.all)

            VStack(spacing: 10) {
                FrozenCatchStatusBar()
                    .padding(.horizontal, 12)
                    .padding(.top, 6)

                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    ZStack {
                        // map backdrop
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [FrozenCatchPalette.steelBlue.opacity(0.55), FrozenCatchPalette.panel],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(FrozenCatchPalette.slate.opacity(0.55), lineWidth: 1)
                            )

                        // decorative aurora bars
                        ForEach(0..<4, id: \.self) { i in
                            Capsule()
                                .fill(FrozenCatchPalette.frostMint.opacity(0.07 + 0.03 * Double(i)))
                                .frame(width: w * 0.78, height: 1.5)
                                .position(x: w * 0.5, y: h * (0.12 + 0.04 * Double(i)))
                        }

                        // grid lines
                        ForEach(0..<6, id: \.self) { i in
                            Rectangle()
                                .fill(FrozenCatchPalette.slate.opacity(0.18))
                                .frame(width: 0.6)
                                .position(x: w * (0.15 + Double(i) * 0.14), y: h / 2)
                                .frame(height: h * 0.9)
                        }

                        // HQ marker (frozenCatch headquarters)
                        VStack(spacing: 4) {
                            HexagonShape()
                                .fill(FrozenCatchPalette.sodiumGold)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    HexagonShape().fill(FrozenCatchPalette.jet).frame(width: 14, height: 14)
                                )
                            Text("HQ")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(FrozenCatchPalette.sodiumGold)
                        }
                        .position(x: w * 0.5, y: h * 0.88)

                        // lakes
                        ForEach(FrozenCatchCatalog.lakes) { lake in
                            lakeMarker(lake: lake)
                                .position(x: w * lake.position.x, y: h * lake.position.y)
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack(spacing: 10) {
                    Button(action: { activeSheet = .events }) {
                        HStack(spacing: 6) {
                            BellShape()
                                .stroke(FrozenCatchPalette.frostMint, lineWidth: 1.8)
                                .frame(width: 16, height: 18)
                            Text("Events")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(FrozenCatchPalette.frostMint)
                            if store.state.pendingEventID != nil {
                                Circle()
                                    .fill(FrozenCatchPalette.alertRed)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 11).fill(FrozenCatchPalette.panel))
                        .overlay(RoundedRectangle(cornerRadius: 11).stroke(FrozenCatchPalette.frostMint.opacity(0.5), lineWidth: 0.8))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: advanceWeek) {
                        HStack(spacing: 8) {
                            TrianglePointerShape(pointsUp: false)
                                .fill(FrozenCatchPalette.jet)
                                .rotationEffect(.degrees(90))
                                .frame(width: 14, height: 14)
                            Text("Advance Week")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(FrozenCatchPalette.jet)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 11)
                                .fill(FrozenCatchPalette.sodiumGold)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .navigationBarTitle("Crew Map", displayMode: .inline)
        .onChange(of: store.state.pendingEventID) { newValue in
            // Auto-surface a pending event when one is set externally (e.g., after Advance Week).
            // Don't clobber an already-open sheet besides the week result.
            if let eid = newValue {
                switch activeSheet {
                case .pendingEvent: break
                case .none, .weekResult: activeSheet = .pendingEvent(eventID: eid)
                default: break
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .assignment(let lakeID):
                AssignmentSheet(lakeID: lakeID, dismiss: { activeSheet = nil })
                    .environmentObject(store)
            case .weekResult:
                if let res = store.state.lastWeekResult {
                    WeekResultSheet(result: res, dismiss: { activeSheet = nil })
                        .environmentObject(store)
                } else {
                    EmptyView()
                }
            case .events:
                EventsView(dismiss: { activeSheet = nil })
                    .environmentObject(store)
            case .pendingEvent(let eid):
                PendingEventSheet(eventID: eid, dismiss: { activeSheet = nil })
                    .environmentObject(store)
            }
        }
    }

    @ViewBuilder
    private func lakeMarker(lake: FrozenCatchLake) -> some View {
        let unlocked = store.state.unlockedLakes.contains(lake.id)
        let assignedCount = store.state.assignments[lake.id]?.count ?? 0
        let cap = store.assignmentCapacityForLake[lake.id] ?? lake.capacity

        Button(action: {
            if unlocked { activeSheet = .assignment(lakeID: lake.id) }
        }) {
            VStack(spacing: 3) {
                ZStack {
                    HexagonShape()
                        .fill(unlocked ? FrozenCatchPalette.steelBlue : FrozenCatchPalette.panel)
                        .frame(width: 44, height: 44)
                    HexagonShape()
                        .stroke(unlocked ? FrozenCatchPalette.frostMint : FrozenCatchPalette.slate, lineWidth: 1.5)
                        .frame(width: 44, height: 44)
                    if unlocked {
                        Text("\(Int(lake.factor * 10) / 10).\(Int(lake.factor * 10) % 10)x")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.ivory)
                    } else {
                        PadlockShape()
                            .fill(FrozenCatchPalette.slate)
                            .frame(width: 14, height: 18)
                    }
                }
                Text(lake.name)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(unlocked ? FrozenCatchPalette.ivory : FrozenCatchPalette.ivory.opacity(0.4))
                if unlocked {
                    Text("\(assignedCount)/\(cap)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(FrozenCatchPalette.sodiumGold)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!unlocked)
    }

    private func advanceWeek() {
        store.advanceWeek()
        activeSheet = .weekResult
    }
}

// MARK: - Helpers for sheet identification
struct LakeIDWrap: Identifiable { let id: Int }
struct EventIDWrap: Identifiable { let id: Int }

// MARK: - Assignment Sheet
struct AssignmentSheet: View {
    let lakeID: Int
    let dismiss: () -> Void
    @EnvironmentObject var store: FrozenCatchStore

    var lake: FrozenCatchLake {
        // Bounds-checked lake lookup (M4)
        guard lakeID >= 0, lakeID < FrozenCatchCatalog.lakes.count else {
            return FrozenCatchCatalog.lakes[0]
        }
        return FrozenCatchCatalog.lakes[lakeID]
    }
    var assigned: [FrozenCatchWorker] {
        let ids = store.state.assignments[lakeID] ?? []
        return ids.compactMap { id in store.state.workers.first(where: { $0.id == id }) }
    }
    var available: [FrozenCatchWorker] {
        store.state.workers.filter { w in
            !w.rested && (w.assignedLakeID == nil || w.assignedLakeID == lakeID)
        }
        .filter { w in !assigned.contains(where: { $0.id == w.id }) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                FrozenCatchPalette.jet.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        FrozenCatchPanel {
                            HStack {
                                Text(lake.name)
                                    .font(.system(size: 19, weight: .bold))
                                    .foregroundColor(FrozenCatchPalette.ivory)
                                Spacer()
                                Text("Factor \(String(format: "%.1f", lake.factor))x")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(FrozenCatchPalette.frostMint)
                            }
                            Text(lake.blurb)
                                .font(.system(size: 13))
                                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.7))
                                .lineSpacing(2)
                            HStack {
                                FrozenCatchPill(label: "Cap", value: "\(store.assignmentCapacityForLake[lakeID] ?? lake.capacity)", accent: FrozenCatchPalette.sodiumGold)
                                FrozenCatchPill(label: "Filled", value: "\(assigned.count)", accent: FrozenCatchPalette.frostMint)
                                FrozenCatchPill(label: "Species", value: "\(lake.speciesPool.count)", accent: FrozenCatchPalette.ivory)
                            }
                        }

                        Text("ASSIGNED")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.5))
                            .padding(.leading, 4)

                        if assigned.isEmpty {
                            Text("No one assigned. Pick from the roster below.")
                                .font(.system(size: 13))
                                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.5))
                                .padding(8)
                        } else {
                            ForEach(assigned) { w in
                                workerRow(w, isAssigned: true)
                            }
                        }

                        Text("AVAILABLE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.5))
                            .padding(.leading, 4)
                            .padding(.top, 4)

                        if available.isEmpty {
                            Text("No available workers. Hire from the Crew tab.")
                                .font(.system(size: 13))
                                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.5))
                                .padding(8)
                        } else {
                            ForEach(available) { w in
                                workerRow(w, isAssigned: false)
                            }
                        }
                    }
                    .padding(14)
                }
            }
            .navigationBarTitle("Assign Crew", displayMode: .inline)
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
    private func workerRow(_ w: FrozenCatchWorker, isAssigned: Bool) -> some View {
        Button(action: {
            if isAssigned {
                store.assign(workerID: w.id, toLake: nil)
            } else {
                let cap = store.assignmentCapacityForLake[lakeID] ?? lake.capacity
                if assigned.count < cap {
                    store.assign(workerID: w.id, toLake: lakeID)
                }
            }
        }) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(FrozenCatchPalette.steelBlue).frame(width: 32, height: 32)
                    PersonSilhouetteShape()
                        .fill(FrozenCatchPalette.ivory)
                        .frame(width: 18, height: 22)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(w.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(FrozenCatchPalette.ivory)
                    Text("\(w.classObj.label) \(w.rankObj.label)  •  Skill \(Int(w.skill))  •  Morale \(Int(w.morale))")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(FrozenCatchPalette.ivory.opacity(0.6))
                }
                Spacer()
                if isAssigned {
                    CrossShape()
                        .stroke(FrozenCatchPalette.alertRed, lineWidth: 2)
                        .frame(width: 14, height: 14)
                } else {
                    PlusShape()
                        .stroke(FrozenCatchPalette.frostMint, lineWidth: 2)
                        .frame(width: 14, height: 14)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(FrozenCatchPalette.panel))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(FrozenCatchPalette.slate.opacity(0.4), lineWidth: 0.8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Week Result Sheet
struct WeekResultSheet: View {
    let result: WeekResult
    let dismiss: () -> Void
    @EnvironmentObject var store: FrozenCatchStore

    var body: some View {
        NavigationView {
            ZStack {
                FrozenCatchPalette.jet.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Week \(result.week) Summary")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(FrozenCatchPalette.ivory)
                            .padding(.bottom, 4)

                        FrozenCatchPanel {
                            HStack {
                                metricBlock(label: "Revenue", value: formatCash(result.revenue), color: FrozenCatchPalette.frostMint)
                                Divider().background(FrozenCatchPalette.slate)
                                metricBlock(label: "Expenses", value: formatCash(result.expenses), color: FrozenCatchPalette.alertRed)
                                Divider().background(FrozenCatchPalette.slate)
                                metricBlock(label: "Net", value: formatCash(result.net), color: result.net >= 0 ? FrozenCatchPalette.frostMint : FrozenCatchPalette.alertRed)
                                Divider().background(FrozenCatchPalette.slate)
                                metricBlock(label: "RP", value: "+\(max(0, result.prestigeDelta))", color: FrozenCatchPalette.sodiumGold)
                            }
                        }

                        FrozenCatchPanel {
                            Text("CATCHES BY WORKER")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
                            if result.perWorkerCatches.isEmpty {
                                Text("No assignments this week.")
                                    .font(.system(size: 13))
                                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.5))
                                    .padding(.vertical, 4)
                            } else {
                                ForEach(result.perWorkerCatches) { c in
                                    HStack {
                                        Text(c.workerName)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(FrozenCatchPalette.ivory)
                                        Spacer()
                                        Text("\(c.units) \(safeFishName(c.primarySpeciesID))")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(FrozenCatchPalette.frostMint)
                                        Text("@ \(c.lakeName)")
                                            .font(.system(size: 11))
                                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
                                    }
                                    .padding(.vertical, 3)
                                }
                            }
                        }

                        if !result.eventsTriggered.isEmpty {
                            FrozenCatchPanel {
                                Text("EVENT TRIGGERED")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
                                ForEach(result.eventsTriggered, id: \.self) { eid in
                                    Text(safeEventTitle(eid))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(FrozenCatchPalette.sodiumGold)
                                }
                                Text("Open the Events button on the map to resolve.")
                                    .font(.system(size: 11))
                                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.5))
                            }
                        }

                        Button(action: dismiss) {
                            Text("Continue")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(FrozenCatchPalette.jet)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(RoundedRectangle(cornerRadius: 11).fill(FrozenCatchPalette.sodiumGold))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 6)
                    }
                    .padding(14)
                }
            }
            .navigationBarTitle("Week Report", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: dismiss) {
                Text("Done")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FrozenCatchPalette.sodiumGold)
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(FrozenCatchPalette.sodiumGold)
    }

    private func safeFishName(_ id: Int) -> String {
        guard id >= 0, id < FrozenCatchCatalog.fish.count else { return "?" }
        return FrozenCatchCatalog.fish[id].name
    }

    private func safeEventTitle(_ id: Int) -> String {
        guard id >= 0, id < FrozenCatchCatalog.events.count else { return "Unknown Event" }
        return FrozenCatchCatalog.events[id].title
    }

    @ViewBuilder
    private func metricBlock(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pending Event Sheet
struct PendingEventSheet: View {
    let eventID: Int
    let dismiss: () -> Void
    @EnvironmentObject var store: FrozenCatchStore

    var evt: FrozenCatchEventDef? {
        guard eventID >= 0, eventID < FrozenCatchCatalog.events.count else { return nil }
        return FrozenCatchCatalog.events[eventID]
    }

    var body: some View {
        ZStack {
            FrozenCatchPalette.jet.edgesIgnoringSafeArea(.all)
            if let evt = evt {
                VStack(spacing: 18) {
                    Spacer()
                    ZStack {
                        HexagonShape()
                            .fill(FrozenCatchPalette.sodiumGold.opacity(0.15))
                            .frame(width: 80, height: 80)
                        RiskDiamondShape()
                            .fill(FrozenCatchPalette.sodiumGold)
                            .frame(width: 40, height: 40)
                    }

                    Text(evt.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(FrozenCatchPalette.ivory)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text(evt.body)
                        .font(.system(size: 14))
                        .foregroundColor(FrozenCatchPalette.ivory.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(3)

                    Spacer()

                    VStack(spacing: 10) {
                        ForEach(0..<evt.choices.count, id: \.self) { idx in
                            Button(action: {
                                store.resolvePendingEvent(choice: idx)
                                dismiss()
                            }) {
                                Text(evt.choices[idx])
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(idx == 0 ? FrozenCatchPalette.jet : FrozenCatchPalette.ivory)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 11)
                                            .fill(idx == 0 ? FrozenCatchPalette.sodiumGold : FrozenCatchPalette.panel)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 11)
                                            .stroke(FrozenCatchPalette.slate.opacity(0.45), lineWidth: 0.8)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            } else {
                VStack(spacing: 16) {
                    Text("No active event.")
                        .font(.system(size: 14))
                        .foregroundColor(FrozenCatchPalette.ivory.opacity(0.6))
                    Button(action: dismiss) {
                        Text("Close")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.jet)
                            .padding(.horizontal, 18).padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(FrozenCatchPalette.sodiumGold))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}
