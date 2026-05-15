import SwiftUI

struct OnboardingView: View {
    @Binding var visible: Bool
    @EnvironmentObject var store: FrozenCatchStore
    @State private var step: Int = 0

    private let steps: [(String, String)] = [
        ("Welcome to Frozen Catch", "You manage a winter fishing crew — a cooperative crew working frozen lakes for catch, coin, and prestige. Plan carefully; every choice ripples across the season."),
        ("Hire your first crew member", "Open the Crew tab and pick a candidate from the rotating pool. Each worker has a class, rank, traits, and salary that shape their output and cost."),
        ("Assign a worker to a lake", "On the Map tab, tap a lake to open its assignment sheet. Drop workers onto the lake and they'll fish there next week."),
        ("Advance the week", "Use the Advance Week button on the Map. Catches are resolved, the market is rolled, expenses paid, and a result summary appears."),
        ("Research and Prestige", "Reputation Points accumulate as your crew performs. Higher ranks unlock more lakes and bigger draw multipliers. Research nodes layer permanent bonuses on top.")
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.78).edgesIgnoringSafeArea(.all)

            VStack(spacing: 22) {
                HStack(spacing: 6) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Capsule()
                            .fill(i == step ? FrozenCatchPalette.sodiumGold : FrozenCatchPalette.slate)
                            .frame(width: i == step ? 24 : 12, height: 5)
                    }
                }

                HexagonShape()
                    .fill(FrozenCatchPalette.frostMint)
                    .frame(width: 64, height: 64)

                Text(steps[step].0)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(FrozenCatchPalette.ivory)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text(steps[step].1)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 38)
                    .lineSpacing(3)

                HStack(spacing: 16) {
                    Button(action: skip) {
                        Text("Skip")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(FrozenCatchPalette.ivory.opacity(0.7))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: next) {
                        Text(step < steps.count - 1 ? "Next" : "Start")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(FrozenCatchPalette.jet)
                            .padding(.horizontal, 36)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(FrozenCatchPalette.sodiumGold)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 22)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(FrozenCatchPalette.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(FrozenCatchPalette.slate, lineWidth: 1)
            )
            .padding(28)
        }
    }

    private func next() {
        if step < steps.count - 1 {
            step += 1
        } else {
            store.setOnboardingSeen()
            visible = false
        }
    }

    private func skip() {
        store.setOnboardingSeen()
        visible = false
    }
}
