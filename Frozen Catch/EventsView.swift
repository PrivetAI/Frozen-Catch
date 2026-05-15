import SwiftUI

struct EventsView: View {
    let dismiss: () -> Void
    @EnvironmentObject var store: FrozenCatchStore

    var body: some View {
        NavigationView {
            ZStack {
                FrozenCatchPalette.jet.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 12) {
                        if let pid = store.state.pendingEventID {
                            pendingBanner(pid)
                        }

                        if store.state.eventsLog.isEmpty {
                            Text("No events yet. They appear as the season unfolds.")
                                .font(.system(size: 13))
                                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.5))
                                .padding(20)
                        } else {
                            ForEach(store.state.eventsLog) { entry in
                                eventEntryRow(entry)
                            }
                        }
                    }
                    .padding(14)
                }
            }
            .navigationBarTitle("Events Feed", displayMode: .inline)
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
    private func pendingBanner(_ id: Int) -> some View {
        // M4: bounds-check
        let evtTitle: String = (id >= 0 && id < FrozenCatchCatalog.events.count)
            ? FrozenCatchCatalog.events[id].title
            : "Unknown Event"
        HStack(spacing: 12) {
            RiskDiamondShape().fill(FrozenCatchPalette.sodiumGold).frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text("Pending: \(evtTitle)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(FrozenCatchPalette.ivory)
                Text("Tap the map's Events button or finish via Advance Week prompt.")
                    .font(.system(size: 11))
                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.6))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(FrozenCatchPalette.sodiumGold.opacity(0.15)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(FrozenCatchPalette.sodiumGold, lineWidth: 0.8))
    }

    @ViewBuilder
    private func eventEntryRow(_ entry: FrozenCatchEventEntry) -> some View {
        // M4: bounds-check
        let evtTitle: String = (entry.eventID >= 0 && entry.eventID < FrozenCatchCatalog.events.count)
            ? FrozenCatchCatalog.events[entry.eventID].title
            : "Unknown Event"
        FrozenCatchPanel {
            HStack {
                Text("Week \(entry.week)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(FrozenCatchPalette.frostMint)
                Spacer()
                Text(evtTitle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(FrozenCatchPalette.ivory)
            }
            Text(entry.outcome)
                .font(.system(size: 12))
                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.7))
                .lineSpacing(2)
        }
    }
}
