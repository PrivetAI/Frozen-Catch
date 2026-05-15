import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: FrozenCatchStore
    @State private var showResetAlert: Bool = false
    @State private var showPrivacy: Bool = false

    var body: some View {
        ZStack {
            FrozenCatchPalette.jet.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 14) {
                    FrozenCatchPanel {
                        Text("PREFERENCES")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))

                        Toggle(isOn: Binding<Bool>(
                            get: { store.state.soundOn },
                            set: { v in store.state.soundOn = v; store.persist() }
                        )) {
                            HStack {
                                Text("Sound").font(.system(size: 14, weight: .medium)).foregroundColor(FrozenCatchPalette.ivory)
                                Spacer()
                            }
                        }
                        .tint(FrozenCatchPalette.sodiumGold)
                        .padding(.vertical, 2)

                        Divider().background(FrozenCatchPalette.slate)

                        Toggle(isOn: Binding<Bool>(
                            get: { store.state.hapticsOn },
                            set: { v in store.state.hapticsOn = v; store.persist() }
                        )) {
                            HStack {
                                Text("Haptics").font(.system(size: 14, weight: .medium)).foregroundColor(FrozenCatchPalette.ivory)
                                Spacer()
                            }
                        }
                        .tint(FrozenCatchPalette.sodiumGold)
                        .padding(.vertical, 2)
                    }

                    FrozenCatchPanel {
                        Text("DATA")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))

                        Button(action: { showResetAlert = true }) {
                            HStack {
                                Text("Reset Progress")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(FrozenCatchPalette.alertRed)
                                Spacer()
                                ChevronShape().stroke(FrozenCatchPalette.alertRed.opacity(0.7), lineWidth: 2).frame(width: 10, height: 14)
                            }
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    FrozenCatchPanel {
                        Text("ABOUT")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))

                        Button(action: { showPrivacy = true }) {
                            HStack {
                                Text("Privacy Policy")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(FrozenCatchPalette.ivory)
                                Spacer()
                                ChevronShape().stroke(FrozenCatchPalette.ivory.opacity(0.55), lineWidth: 2).frame(width: 10, height: 14)
                            }
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider().background(FrozenCatchPalette.slate)

                        HStack {
                            Text("Version")
                                .font(.system(size: 13))
                                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.7))
                            Spacer()
                            Text("1.0")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(14)
            }
        }
        .navigationBarTitle("Settings", displayMode: .inline)
        .alert(isPresented: $showResetAlert) {
            Alert(
                title: Text("Reset Progress?"),
                message: Text("This will erase all saved progress. You cannot undo this action."),
                primaryButton: .destructive(Text("Reset")) {
                    store.resetProgress()
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showPrivacy) {
            FrozenCatchWebPanel(urlString: "https://frozencatch.org/click.php")
                .edgesIgnoringSafeArea(.all)
        }
    }
}
