import SwiftUI

struct FrozenCatchLoadingScreen: View {
    @State private var pulse: Bool = false
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [FrozenCatchPalette.steelBlue, FrozenCatchPalette.jet],
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 32) {
                ZStack {
                    HexagonShape()
                        .stroke(FrozenCatchPalette.sodiumGold, lineWidth: 6)
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(rotation))

                    HexagonShape()
                        .fill(FrozenCatchPalette.frostMint)
                        .frame(width: 78, height: 78)
                        .scaleEffect(pulse ? 1.08 : 0.92)

                    HexagonShape()
                        .fill(FrozenCatchPalette.ivory)
                        .frame(width: 34, height: 34)
                }
                .animation(
                    Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: pulse
                )
                .animation(
                    Animation.linear(duration: 12).repeatForever(autoreverses: false),
                    value: rotation
                )

                VStack(spacing: 6) {
                    Text("Frozen Catch")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(FrozenCatchPalette.ivory)
                    Text("Winter Fishing Cooperative")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
                }
            }
        }
        .onAppear {
            pulse = true
            rotation = 360
        }
    }
}
