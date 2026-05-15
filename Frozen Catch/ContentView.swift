import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: FrozenCatchStore
    @State private var selectedTab: Int = 0
    @State private var showOnboarding: Bool = false

    var body: some View {
        ZStack {
            FrozenCatchPalette.jet.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case 0:
                        NavigationView { MapView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 1:
                        NavigationView { CrewView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 2:
                        NavigationView { MarketView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 3:
                        NavigationView { ResearchView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 4:
                        NavigationView { MoreHubView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                FrozenCatchTabBar(selectedTab: $selectedTab)
            }

            if showOnboarding {
                OnboardingView(visible: $showOnboarding)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .onAppear {
            if !store.state.onboardingSeen {
                showOnboarding = true
            }
        }
    }
}

struct FrozenCatchTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            tabButton(idx: 0, label: "Map") {
                AnyView(BuildingBlockShape().fill(currentColor(0)))
            }
            tabButton(idx: 1, label: "Crew") {
                AnyView(PersonSilhouetteShape().fill(currentColor(1)))
            }
            tabButton(idx: 2, label: "Market") {
                AnyView(ThreeBarsShape().fill(currentColor(2)))
            }
            tabButton(idx: 3, label: "Research") {
                AnyView(SquareStackShape().stroke(currentColor(3), lineWidth: 1.8))
            }
            tabButton(idx: 4, label: "More") {
                AnyView(OctagonCogShape().fill(currentColor(4)))
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
        .padding(.horizontal, 4)
        .background(
            FrozenCatchPalette.panel.edgesIgnoringSafeArea(.bottom)
        )
        .overlay(
            Rectangle()
                .fill(FrozenCatchPalette.slate.opacity(0.5))
                .frame(height: 0.6),
            alignment: .top
        )
    }

    private func currentColor(_ idx: Int) -> Color {
        selectedTab == idx ? FrozenCatchPalette.sodiumGold : FrozenCatchPalette.ivory.opacity(0.45)
    }

    @ViewBuilder
    private func tabButton<Icon: View>(idx: Int, label: String, @ViewBuilder icon: () -> Icon) -> some View {
        Button(action: { selectedTab = idx }) {
            VStack(spacing: 3) {
                icon()
                    .frame(width: 22, height: 22)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(currentColor(idx))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
