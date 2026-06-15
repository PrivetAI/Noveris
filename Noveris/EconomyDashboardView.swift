import SwiftUI

struct EconomyDashboardView: View {
    @EnvironmentObject var store: GameStore

    private let charted: [ResourceID] = [.credits, .alloy, .fuel, .components, .isotope, .food]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                clusterTotals()
                SectionHeader(title: "Production Flow", accent: Brand.cyan)
                flowCard()
                SectionHeader(title: "Stockpile Trends", accent: Brand.teal)
                ForEach(charted, id: \.self) { r in
                    chartCard(r)
                }
            }
            .padding(16)
            .clampedContent()
        }
        .background(Brand.background())
        .navigationBarTitle("Economy", displayMode: .inline)
    }

    private func clusterTotals() -> some View {
        let all: [ResourceID] = [.credits, .ferrite, .cuprite, .silicate, .isotope, .alloy, .fuel, .components, .food]
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
            ForEach(all, id: \.self) { r in
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        ResourceGlyph(kind: r.icon, size: 14, color: r.color)
                        Text(r.short).font(.console(9)).foregroundColor(Brand.textFaint)
                        Spacer(minLength: 0)
                    }
                    Text(Fmt.compact(store.state.totalStock(r)))
                        .font(.console(15, weight: .bold)).foregroundColor(Brand.text)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 9).fill(Brand.panel))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(r.color.opacity(0.25), lineWidth: 1))
            }
        }
    }

    private func flowCard() -> some View {
        // estimate per-cycle net by inspecting modules (approximate display)
        var powerNet = 0.0, laborNet = 0.0, defense = 0.0
        var researchOut = ResearchTree.baseOutput
        for s in store.state.systems where s.claimed {
            for m in s.modules {
                powerNet += m.powerFlow
                laborNet += m.laborFlow
                researchOut += m.researchOutput
                defense += m.defenseRating
            }
        }
        return ConsoleCard(accent: Brand.amber) {
            VStack(spacing: 8) {
                flowRow("Power balance", powerNet, .power, Brand.amber)
                flowRow("Labor balance", laborNet, .people, Brand.teal)
                flowRow("Research / cycle", researchOut, nil, Brand.violet, glyph: false)
                HStack {
                    ShieldIcon(size: 14, color: Brand.red)
                    Text("Cluster defense").font(.console(11)).foregroundColor(Brand.textDim)
                    Spacer()
                    Text(Fmt.compact(defense)).font(.console(13, weight: .bold)).foregroundColor(Brand.text)
                }
            }
        }
    }

    private func flowRow(_ label: String, _ value: Double, _ kind: ResIconKind?, _ color: Color, glyph: Bool = true) -> some View {
        HStack(spacing: 8) {
            if let kind = kind { ResourceGlyph(kind: kind, size: 14, color: color) }
            else { FlaskIcon(size: 14, color: color) }
            Text(label).font(.console(11)).foregroundColor(Brand.textDim)
            Spacer()
            Text(Fmt.signed(value)).font(.console(13, weight: .bold))
                .foregroundColor(value >= 0 ? Brand.green : Brand.red)
        }
    }

    private func chartCard(_ r: ResourceID) -> some View {
        let series = store.state.history[r.rawValue] ?? []
        return ConsoleCard(accent: r.color) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ResourceGlyph(kind: r.icon, size: 16, color: r.color)
                    Text(r.name).font(.console(13, weight: .bold)).foregroundColor(Brand.text)
                    Spacer()
                    Text(Fmt.compact(store.state.totalStock(r))).font(.console(13, weight: .bold)).foregroundColor(r.color)
                }
                SparkChart(values: series, color: r.color)
                    .frame(height: 64)
            }
        }
    }
}

// MARK: - Custom Path line chart (NOT Charts framework)
struct SparkChart: View {
    let values: [Double]
    var color: Color = Brand.cyan

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // baseline grid
                Path { p in
                    for i in 0...3 {
                        let y = h * CGFloat(i) / 3
                        p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: w, y: y))
                    }
                }.stroke(Brand.stroke.opacity(0.4), lineWidth: 0.5)

                if values.count < 2 {
                    Text(values.isEmpty ? "Advance a cycle to chart data" : "Collecting data…")
                        .font(.console(10)).foregroundColor(Brand.textFaint)
                        .frame(width: w, height: h)
                } else {
                    let minV = values.min() ?? 0
                    let maxV = values.max() ?? 1
                    let range = max(maxV - minV, 1)
                    let step = values.count > 1 ? w / CGFloat(values.count - 1) : w
                    // filled area
                    Path { p in
                        for (i, v) in values.enumerated() {
                            let x = CGFloat(i) * step
                            let y = h - CGFloat((v - minV) / range) * (h - 6) - 3
                            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                            else { p.addLine(to: CGPoint(x: x, y: y)) }
                        }
                        p.addLine(to: CGPoint(x: w, y: h))
                        p.addLine(to: CGPoint(x: 0, y: h))
                        p.closeSubpath()
                    }.fill(LinearGradient(colors: [color.opacity(0.28), color.opacity(0.02)],
                                          startPoint: .top, endPoint: .bottom))
                    // line
                    Path { p in
                        for (i, v) in values.enumerated() {
                            let x = CGFloat(i) * step
                            let y = h - CGFloat((v - minV) / range) * (h - 6) - 3
                            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                            else { p.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }.stroke(color, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }
}
