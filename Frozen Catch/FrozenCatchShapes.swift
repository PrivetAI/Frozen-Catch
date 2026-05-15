import SwiftUI

// MARK: - Shapes
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        for i in 0..<6 {
            let angle = CGFloat.pi / 3 * CGFloat(i) - CGFloat.pi / 2
            let x = cx + r * cos(angle)
            let y = cy + r * sin(angle)
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
            else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        p.closeSubpath()
        return p
    }
}

struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

struct TrianglePointerShape: Shape {
    var pointsUp: Bool = true
    func path(in rect: CGRect) -> Path {
        var p = Path()
        if pointsUp {
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        }
        p.closeSubpath()
        return p
    }
}

struct OctagonCogShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX, cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        let teeth = 8
        let inner = r * 0.7
        for i in 0..<(teeth * 2) {
            let angle = CGFloat.pi * 2 * CGFloat(i) / CGFloat(teeth * 2) - CGFloat.pi / 2
            let rr = (i % 2 == 0) ? r : inner
            let x = cx + rr * cos(angle)
            let y = cy + rr * sin(angle)
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
            else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        p.closeSubpath()
        return p
    }
}

struct PadlockShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let bodyTop = rect.minY + rect.height * 0.45
        let bodyRect = CGRect(x: rect.minX + rect.width * 0.15,
                              y: bodyTop,
                              width: rect.width * 0.7,
                              height: rect.height * 0.55)
        p.addRoundedRect(in: bodyRect, cornerSize: CGSize(width: 6, height: 6))
        // shackle
        let shackleRect = CGRect(x: rect.minX + rect.width * 0.27,
                                 y: rect.minY + rect.height * 0.10,
                                 width: rect.width * 0.46,
                                 height: rect.height * 0.50)
        p.addEllipse(in: shackleRect)
        let inner = shackleRect.insetBy(dx: 7, dy: 7)
        p.addEllipse(in: inner)
        return p
    }
}

struct CheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.midY + rect.height * 0.05))
        p.addLine(to: CGPoint(x: rect.midX - rect.width * 0.05, y: rect.maxY - rect.height * 0.18))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.10, y: rect.minY + rect.height * 0.18))
        return p
    }
}

struct CrossShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return p
    }
}

struct ChevronShape: Shape {
    var forward: Bool = true
    func path(in rect: CGRect) -> Path {
        var p = Path()
        if forward {
            p.move(to: CGPoint(x: rect.minX + rect.width * 0.3, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.3, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.3, y: rect.maxY))
        } else {
            p.move(to: CGPoint(x: rect.maxX - rect.width * 0.3, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.3, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.3, y: rect.maxY))
        }
        return p
    }
}

struct PlusShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.15))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.15))
        p.move(to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.15, y: rect.midY))
        return p
    }
}

struct MinusShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.15, y: rect.midY))
        return p
    }
}

struct CoinShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        p.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
        // inner ring
        let inset: CGFloat = r * 0.25
        p.addEllipse(in: CGRect(x: center.x - r + inset, y: center.y - r + inset, width: (r - inset) * 2, height: (r - inset) * 2))
        return p
    }
}

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX, cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        let inner = r * 0.4
        for i in 0..<10 {
            let angle = CGFloat.pi * 2 * CGFloat(i) / 10 - CGFloat.pi / 2
            let rr = (i % 2 == 0) ? r : inner
            let x = cx + rr * cos(angle)
            let y = cy + rr * sin(angle)
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
            else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        p.closeSubpath()
        return p
    }
}

struct BellShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let topY = rect.minY + rect.height * 0.18
        let bottomY = rect.maxY - rect.height * 0.18
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + 4))
        p.addLine(to: CGPoint(x: rect.midX + 4, y: topY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - 6, y: bottomY), control: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX + 6, y: bottomY))
        p.addQuadCurve(to: CGPoint(x: rect.midX - 4, y: topY), control: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        // clapper
        let cl = CGRect(x: rect.midX - 4, y: rect.maxY - rect.height * 0.12, width: 8, height: 8)
        p.addEllipse(in: cl)
        return p
    }
}

struct PersonSilhouetteShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let headR = rect.width * 0.18
        let headCenter = CGPoint(x: rect.midX, y: rect.minY + headR + 2)
        p.addEllipse(in: CGRect(x: headCenter.x - headR, y: headCenter.y - headR, width: headR * 2, height: headR * 2))
        // body
        let bodyTop = headCenter.y + headR + 4
        let body = CGRect(x: rect.minX + rect.width * 0.15,
                          y: bodyTop,
                          width: rect.width * 0.7,
                          height: rect.maxY - bodyTop - 2)
        let bodyPath = Path { sp in
            sp.move(to: CGPoint(x: body.minX, y: body.maxY))
            sp.addLine(to: CGPoint(x: body.minX, y: body.midY))
            sp.addQuadCurve(to: CGPoint(x: body.midX, y: body.minY), control: CGPoint(x: body.minX, y: body.minY))
            sp.addQuadCurve(to: CGPoint(x: body.maxX, y: body.midY), control: CGPoint(x: body.maxX, y: body.minY))
            sp.addLine(to: CGPoint(x: body.maxX, y: body.maxY))
            sp.closeSubpath()
        }
        p.addPath(bodyPath)
        return p
    }
}

struct BuildingBlockShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let baseR = CGRect(x: rect.minX, y: rect.maxY - rect.height * 0.55,
                           width: rect.width, height: rect.height * 0.55)
        p.addRect(baseR)
        // roof triangle
        p.move(to: CGPoint(x: rect.minX - 2, y: baseR.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX + 2, y: baseR.minY))
        p.closeSubpath()
        return p
    }
}

struct SquareStackShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let inset: CGFloat = 4
        let r1 = CGRect(x: rect.minX, y: rect.minY, width: rect.width - inset, height: rect.height - inset)
        let r2 = CGRect(x: rect.minX + inset, y: rect.minY + inset, width: rect.width - inset, height: rect.height - inset)
        p.addRect(r1)
        p.addRect(r2)
        return p
    }
}

struct ArrowUpShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX + 4, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX + 4, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX - 4, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX - 4, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX + 4, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

struct ArrowDownShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX + 4, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX + 4, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX - 4, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX - 4, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX + 4, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

struct CubeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let off = w * 0.18
        // front
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + off))
        p.addLine(to: CGPoint(x: rect.maxX - off, y: rect.minY + off))
        p.addLine(to: CGPoint(x: rect.maxX - off, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        // top
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + off))
        p.addLine(to: CGPoint(x: rect.minX + off, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - off, y: rect.minY + off))
        p.closeSubpath()
        // side
        p.move(to: CGPoint(x: rect.maxX - off, y: rect.minY + off))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - off))
        p.addLine(to: CGPoint(x: rect.maxX - off, y: rect.maxY))
        p.closeSubpath()
        _ = w; _ = h
        return p
    }
}

struct BanknoteShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.insetBy(dx: 2, dy: 6)
        p.addRoundedRect(in: r, cornerSize: CGSize(width: 3, height: 3))
        let center = CGRect(x: r.midX - r.width * 0.18, y: r.midY - r.height * 0.22, width: r.width * 0.36, height: r.height * 0.44)
        p.addEllipse(in: center)
        return p
    }
}

struct ThreeBarsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let barW = rect.width * 0.20
        let gap = rect.width * 0.10
        let totalW = barW * 3 + gap * 2
        let startX = rect.midX - totalW / 2
        for i in 0..<3 {
            let x = startX + CGFloat(i) * (barW + gap)
            let height = rect.height * (0.5 + 0.18 * CGFloat(i))
            let y = rect.maxY - height
            p.addRect(CGRect(x: x, y: y, width: barW, height: height))
        }
        return p
    }
}

struct RiskDiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        // bang
        p.move(to: CGPoint(x: rect.midX, y: rect.midY - rect.height * 0.18))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.05))
        p.addEllipse(in: CGRect(x: rect.midX - 2, y: rect.midY + rect.height * 0.12, width: 4, height: 4))
        return p
    }
}

// MARK: - Icon containers
struct PaletteIcon<Content: View>: View {
    let size: CGFloat
    let color: Color
    let strokeMode: Bool
    let lineWidth: CGFloat
    @ViewBuilder let content: () -> Content

    init(size: CGFloat = 22, color: Color = FrozenCatchPalette.ivory, strokeMode: Bool = false, lineWidth: CGFloat = 2, @ViewBuilder content: @escaping () -> Content) {
        self.size = size
        self.color = color
        self.strokeMode = strokeMode
        self.lineWidth = lineWidth
        self.content = content
    }

    var body: some View {
        content()
            .frame(width: size, height: size)
            .foregroundColor(color)
    }
}

// MARK: - Pill / Panel
struct FrozenCatchPanel<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FrozenCatchPalette.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(FrozenCatchPalette.slate.opacity(0.4), lineWidth: 1)
        )
    }
}

struct FrozenCatchPill: View {
    let label: String
    let value: String
    let accent: Color
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(FrozenCatchPalette.ivory.opacity(0.65))
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(accent)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(FrozenCatchPalette.panelElev)
        )
        .overlay(
            Capsule().stroke(accent.opacity(0.4), lineWidth: 0.7)
        )
    }
}

// MARK: - Status bar (top of map)
struct FrozenCatchStatusBar: View {
    @EnvironmentObject var store: FrozenCatchStore

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                CoinShape()
                    .fill(FrozenCatchPalette.sodiumGold)
                    .frame(width: 18, height: 18)
                Text(formatCash(store.state.cash))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(FrozenCatchPalette.ivory)
            }
            Spacer()
            HStack(spacing: 6) {
                BanknoteShape()
                    .fill(FrozenCatchPalette.alertRed.opacity(store.state.debt > 0 ? 1 : 0.5))
                    .frame(width: 18, height: 14)
                Text(formatCash(store.state.debt))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(store.state.debt > 0 ? FrozenCatchPalette.alertRed : FrozenCatchPalette.ivory.opacity(0.6))
            }
            Spacer()
            HStack(spacing: 6) {
                HexagonShape()
                    .fill(FrozenCatchPalette.frostMint)
                    .frame(width: 16, height: 16)
                Text(store.prestigeTier.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(FrozenCatchPalette.frostMint)
                Text("\(store.state.reputationPoints) RP")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.55))
            }
            Spacer()
            HStack(spacing: 4) {
                Text("Week")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(FrozenCatchPalette.ivory.opacity(0.65))
                Text("\(store.state.week)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FrozenCatchPalette.ivory)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FrozenCatchPalette.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(FrozenCatchPalette.slate.opacity(0.5), lineWidth: 0.8)
        )
    }
}

func formatCash(_ v: Double) -> String {
    let absv = abs(v)
    let sign = v < 0 ? "-" : ""
    if absv >= 1_000_000 {
        return "\(sign)$\(String(format: "%.2f", absv / 1_000_000))M"
    } else if absv >= 1_000 {
        return "\(sign)$\(String(format: "%.1f", absv / 1_000))K"
    } else {
        return "\(sign)$\(Int(absv.rounded()))"
    }
}
