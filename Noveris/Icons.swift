import SwiftUI

// MARK: - Custom Shape icons (NO SF Symbols, NO emoji)

struct RelayDishIcon: View {
    var size: CGFloat = 24
    var color: Color = Brand.cyan
    var body: some View {
        ZStack {
            Path { p in
                let s = size
                // dish arc
                p.addArc(center: CGPoint(x: s*0.5, y: s*0.42), radius: s*0.32,
                         startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
            }.stroke(color, lineWidth: size*0.07)
            Path { p in
                let s = size
                p.move(to: CGPoint(x: s*0.5, y: s*0.42))
                p.addLine(to: CGPoint(x: s*0.5, y: s*0.86))
            }.stroke(color, lineWidth: size*0.07)
            Circle().fill(color).frame(width: size*0.12, height: size*0.12)
                .position(x: size*0.5, y: size*0.30)
        }
        .frame(width: size, height: size)
    }
}

struct StationHexIcon: View {
    var size: CGFloat = 24
    var color: Color = Brand.teal
    var body: some View {
        ZStack {
            HexShape().stroke(color, lineWidth: size*0.07)
            HexShape().fill(color.opacity(0.18))
            Circle().fill(color).frame(width: size*0.18, height: size*0.18)
        }
        .frame(width: size, height: size)
    }
}

struct HexShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX, cy = rect.midY
        let r = min(rect.width, rect.height) * 0.46
        for i in 0..<6 {
            let a = Double(i) * .pi/3 - .pi/2
            let pt = CGPoint(x: cx + r*CGFloat(cos(a)), y: cy + r*CGFloat(sin(a)))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

struct OreCrystalIcon: View {
    var size: CGFloat = 24
    var color: Color = Brand.violet
    var body: some View {
        Path { p in
            let s = size
            p.move(to: CGPoint(x: s*0.5, y: s*0.10))
            p.addLine(to: CGPoint(x: s*0.82, y: s*0.40))
            p.addLine(to: CGPoint(x: s*0.66, y: s*0.88))
            p.addLine(to: CGPoint(x: s*0.34, y: s*0.88))
            p.addLine(to: CGPoint(x: s*0.18, y: s*0.40))
            p.closeSubpath()
            p.move(to: CGPoint(x: s*0.5, y: s*0.10))
            p.addLine(to: CGPoint(x: s*0.5, y: s*0.88))
            p.move(to: CGPoint(x: s*0.18, y: s*0.40))
            p.addLine(to: CGPoint(x: s*0.82, y: s*0.40))
        }
        .stroke(color, style: StrokeStyle(lineWidth: size*0.06, lineJoin: .round))
        .background(
            Path { p in
                let s = size
                p.move(to: CGPoint(x: s*0.5, y: s*0.10))
                p.addLine(to: CGPoint(x: s*0.82, y: s*0.40))
                p.addLine(to: CGPoint(x: s*0.66, y: s*0.88))
                p.addLine(to: CGPoint(x: s*0.34, y: s*0.88))
                p.addLine(to: CGPoint(x: s*0.18, y: s*0.40))
                p.closeSubpath()
            }.fill(color.opacity(0.16))
        )
        .frame(width: size, height: size)
    }
}

struct FuelCellIcon: View {
    var size: CGFloat = 24
    var color: Color = Brand.amber
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size*0.12)
                .stroke(color, lineWidth: size*0.07)
                .frame(width: size*0.5, height: size*0.74)
            // bolt
            Path { p in
                let s = size
                p.move(to: CGPoint(x: s*0.54, y: s*0.24))
                p.addLine(to: CGPoint(x: s*0.42, y: s*0.52))
                p.addLine(to: CGPoint(x: s*0.52, y: s*0.52))
                p.addLine(to: CGPoint(x: s*0.46, y: s*0.76))
                p.addLine(to: CGPoint(x: s*0.60, y: s*0.46))
                p.addLine(to: CGPoint(x: s*0.50, y: s*0.46))
                p.closeSubpath()
            }.fill(color)
        }
        .frame(width: size, height: size)
    }
}

struct ConvoyShipIcon: View {
    var size: CGFloat = 24
    var color: Color = Brand.green
    var body: some View {
        Path { p in
            let s = size
            p.move(to: CGPoint(x: s*0.14, y: s*0.5))
            p.addLine(to: CGPoint(x: s*0.50, y: s*0.30))
            p.addLine(to: CGPoint(x: s*0.86, y: s*0.5))
            p.addLine(to: CGPoint(x: s*0.50, y: s*0.70))
            p.closeSubpath()
        }
        .stroke(color, style: StrokeStyle(lineWidth: size*0.06, lineJoin: .round))
        .background(
            Path { p in
                let s = size
                p.move(to: CGPoint(x: s*0.14, y: s*0.5))
                p.addLine(to: CGPoint(x: s*0.50, y: s*0.30))
                p.addLine(to: CGPoint(x: s*0.86, y: s*0.5))
                p.addLine(to: CGPoint(x: s*0.50, y: s*0.70))
                p.closeSubpath()
            }.fill(color.opacity(0.18))
        )
        .frame(width: size, height: size)
    }
}

struct StarNodeIcon: View {
    var size: CGFloat = 24
    var color: Color = Brand.amber
    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.25)).frame(width: size*0.8, height: size*0.8)
            Circle().fill(color).frame(width: size*0.4, height: size*0.4)
            ForEach(0..<4, id: \.self) { i in
                Rectangle().fill(color.opacity(0.7))
                    .frame(width: size*0.06, height: size*0.7)
                    .rotationEffect(.degrees(Double(i)*45))
            }
        }
        .frame(width: size, height: size)
    }
}

struct GearIcon: View {
    var size: CGFloat = 24
    var color: Color = Brand.textDim
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1).fill(color)
                    .frame(width: size*0.12, height: size*0.28)
                    .offset(y: -size*0.34)
                    .rotationEffect(.degrees(Double(i)*45))
            }
            Circle().stroke(color, lineWidth: size*0.09).frame(width: size*0.46, height: size*0.46)
        }
        .frame(width: size, height: size)
    }
}

struct FlaskIcon: View { // research
    var size: CGFloat = 24
    var color: Color = Brand.violet
    var body: some View {
        Path { p in
            let s = size
            p.move(to: CGPoint(x: s*0.40, y: s*0.16))
            p.addLine(to: CGPoint(x: s*0.40, y: s*0.42))
            p.addLine(to: CGPoint(x: s*0.20, y: s*0.80))
            p.addLine(to: CGPoint(x: s*0.80, y: s*0.80))
            p.addLine(to: CGPoint(x: s*0.60, y: s*0.42))
            p.addLine(to: CGPoint(x: s*0.60, y: s*0.16))
            p.move(to: CGPoint(x: s*0.34, y: s*0.16))
            p.addLine(to: CGPoint(x: s*0.66, y: s*0.16))
        }
        .stroke(color, style: StrokeStyle(lineWidth: size*0.06, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

struct MapIcon: View {
    var size: CGFloat = 24
    var color: Color = Brand.cyan
    var body: some View {
        ZStack {
            ForEach([CGPoint(x:0.25,y:0.30),CGPoint(x:0.72,y:0.25),CGPoint(x:0.55,y:0.66),CGPoint(x:0.30,y:0.78)], id: \.self) { pt in
                Circle().fill(color).frame(width: size*0.14, height: size*0.14)
                    .position(x: size*pt.x, y: size*pt.y)
            }
            Path { p in
                p.move(to: CGPoint(x: size*0.25, y: size*0.30))
                p.addLine(to: CGPoint(x: size*0.72, y: size*0.25))
                p.addLine(to: CGPoint(x: size*0.55, y: size*0.66))
                p.addLine(to: CGPoint(x: size*0.30, y: size*0.78))
                p.move(to: CGPoint(x: size*0.25, y: size*0.30))
                p.addLine(to: CGPoint(x: size*0.55, y: size*0.66))
            }.stroke(color.opacity(0.55), lineWidth: size*0.04)
        }
        .frame(width: size, height: size)
    }
}

struct ChartIcon: View {
    var size: CGFloat = 24
    var color: Color = Brand.teal
    var body: some View {
        Path { p in
            let s = size
            p.move(to: CGPoint(x: s*0.16, y: s*0.80))
            p.addLine(to: CGPoint(x: s*0.36, y: s*0.50))
            p.addLine(to: CGPoint(x: s*0.55, y: s*0.62))
            p.addLine(to: CGPoint(x: s*0.84, y: s*0.22))
        }
        .stroke(color, style: StrokeStyle(lineWidth: size*0.07, lineCap: .round, lineJoin: .round))
        .background(
            Path { p in
                let s = size
                p.move(to: CGPoint(x: s*0.14, y: s*0.86)); p.addLine(to: CGPoint(x: s*0.14, y: s*0.14))
                p.move(to: CGPoint(x: s*0.14, y: s*0.86)); p.addLine(to: CGPoint(x: s*0.86, y: s*0.86))
            }.stroke(color.opacity(0.4), lineWidth: size*0.04)
        )
        .frame(width: size, height: size)
    }
}

struct GridIcon: View {
    var size: CGFloat = 24
    var color: Color = Brand.amber
    var body: some View {
        ZStack {
            ForEach(0..<2, id:\.self){ r in
                ForEach(0..<2, id:\.self){ c in
                    RoundedRectangle(cornerRadius: size*0.06)
                        .stroke(color, lineWidth: size*0.06)
                        .frame(width: size*0.32, height: size*0.32)
                        .position(x: size*(0.32 + CGFloat(c)*0.36), y: size*(0.32 + CGFloat(r)*0.36))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

struct TrophyIcon: View {
    var size: CGFloat = 24
    var color: Color = Brand.amber
    var body: some View {
        ZStack {
            Path { p in
                let s = size
                p.move(to: CGPoint(x: s*0.30, y: s*0.18))
                p.addLine(to: CGPoint(x: s*0.70, y: s*0.18))
                p.addLine(to: CGPoint(x: s*0.66, y: s*0.50))
                p.addQuadCurve(to: CGPoint(x: s*0.34, y: s*0.50), control: CGPoint(x: s*0.5, y: s*0.62))
                p.closeSubpath()
            }.stroke(color, lineWidth: size*0.06)
            Rectangle().fill(color).frame(width: size*0.06, height: size*0.16).offset(y: size*0.06)
            Rectangle().fill(color).frame(width: size*0.26, height: size*0.06).offset(y: size*0.18)
        }
        .frame(width: size, height: size)
    }
}

struct BookIcon: View {
    var size: CGFloat = 24
    var color: Color = Brand.cyan
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size*0.06)
                .stroke(color, lineWidth: size*0.06)
                .frame(width: size*0.56, height: size*0.66)
            Rectangle().fill(color).frame(width: size*0.05, height: size*0.66)
            Path { p in
                p.move(to: CGPoint(x: size*0.30, y: size*0.38)); p.addLine(to: CGPoint(x: size*0.44, y: size*0.38))
                p.move(to: CGPoint(x: size*0.56, y: size*0.38)); p.addLine(to: CGPoint(x: size*0.70, y: size*0.38))
            }.stroke(color.opacity(0.6), lineWidth: size*0.04)
        }
        .frame(width: size, height: size)
    }
}

struct ShieldIcon: View {
    var size: CGFloat = 24
    var color: Color = Brand.red
    var body: some View {
        Path { p in
            let s = size
            p.move(to: CGPoint(x: s*0.5, y: s*0.14))
            p.addLine(to: CGPoint(x: s*0.82, y: s*0.26))
            p.addLine(to: CGPoint(x: s*0.82, y: s*0.54))
            p.addQuadCurve(to: CGPoint(x: s*0.5, y: s*0.88), control: CGPoint(x: s*0.7, y: s*0.80))
            p.addQuadCurve(to: CGPoint(x: s*0.18, y: s*0.54), control: CGPoint(x: s*0.3, y: s*0.80))
            p.addLine(to: CGPoint(x: s*0.18, y: s*0.26))
            p.closeSubpath()
        }
        .stroke(color, style: StrokeStyle(lineWidth: size*0.06, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

struct BoltIcon: View { // power
    var size: CGFloat = 24
    var color: Color = Brand.amber
    var body: some View {
        Path { p in
            let s = size
            p.move(to: CGPoint(x: s*0.56, y: s*0.10))
            p.addLine(to: CGPoint(x: s*0.30, y: s*0.54))
            p.addLine(to: CGPoint(x: s*0.48, y: s*0.54))
            p.addLine(to: CGPoint(x: s*0.40, y: s*0.90))
            p.addLine(to: CGPoint(x: s*0.70, y: s*0.42))
            p.addLine(to: CGPoint(x: s*0.50, y: s*0.42))
            p.closeSubpath()
        }
        .fill(color)
        .frame(width: size, height: size)
    }
}

struct PeopleIcon: View { // labor / population
    var size: CGFloat = 24
    var color: Color = Brand.teal
    var body: some View {
        ZStack {
            Circle().stroke(color, lineWidth: size*0.06).frame(width: size*0.26, height: size*0.26).offset(y: -size*0.18)
            Path { p in
                let s = size
                p.addArc(center: CGPoint(x: s*0.5, y: s*0.70), radius: s*0.26,
                         startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
            }.stroke(color, lineWidth: size*0.06)
        }
        .frame(width: size, height: size)
    }
}

// generic resource glyph router
struct ResourceGlyph: View {
    let kind: ResIconKind
    var size: CGFloat = 22
    var color: Color = Brand.cyan
    var body: some View {
        switch kind {
        case .ore: OreCrystalIcon(size: size, color: color)
        case .fuel: FuelCellIcon(size: size, color: color)
        case .power: BoltIcon(size: size, color: color)
        case .people: PeopleIcon(size: size, color: color)
        case .alloy: StationHexIcon(size: size, color: color)
        case .component: GridIcon(size: size, color: color)
        case .credit: CreditIcon(size: size, color: color)
        case .food: FoodIcon(size: size, color: color)
        case .isotope: IsotopeIcon(size: size, color: color)
        }
    }
}

enum ResIconKind { case ore, fuel, power, people, alloy, component, credit, food, isotope }

struct CreditIcon: View {
    var size: CGFloat = 24
    var color: Color = Brand.amber
    var body: some View {
        ZStack {
            Circle().stroke(color, lineWidth: size*0.07).frame(width: size*0.6, height: size*0.6)
            Path { p in
                let s = size
                p.move(to: CGPoint(x: s*0.62, y: s*0.36))
                p.addQuadCurve(to: CGPoint(x: s*0.40, y: s*0.5), control: CGPoint(x: s*0.36, y: s*0.34))
                p.addQuadCurve(to: CGPoint(x: s*0.62, y: s*0.64), control: CGPoint(x: s*0.36, y: s*0.66))
            }.stroke(color, lineWidth: size*0.06)
        }
        .frame(width: size, height: size)
    }
}

struct FoodIcon: View {
    var size: CGFloat = 24
    var color: Color = Brand.green
    var body: some View {
        ZStack {
            Circle().stroke(color, lineWidth: size*0.06).frame(width: size*0.5, height: size*0.5)
            Path { p in
                p.move(to: CGPoint(x: size*0.5, y: size*0.5))
                p.addLine(to: CGPoint(x: size*0.5, y: size*0.2))
                p.move(to: CGPoint(x: size*0.5, y: size*0.5))
                p.addLine(to: CGPoint(x: size*0.72, y: size*0.62))
            }.stroke(color, lineWidth: size*0.05)
        }
        .frame(width: size, height: size)
    }
}

struct IsotopeIcon: View {
    var size: CGFloat = 24
    var color: Color = Brand.violet
    var body: some View {
        ZStack {
            ForEach(0..<3, id:\.self){ i in
                Ellipse().stroke(color.opacity(0.8), lineWidth: size*0.045)
                    .frame(width: size*0.7, height: size*0.28)
                    .rotationEffect(.degrees(Double(i)*60))
            }
            Circle().fill(color).frame(width: size*0.16, height: size*0.16)
        }
        .frame(width: size, height: size)
    }
}

struct CheckIcon: View {
    var size: CGFloat = 16
    var color: Color = Brand.green
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: size*0.2, y: size*0.55))
            p.addLine(to: CGPoint(x: size*0.42, y: size*0.78))
            p.addLine(to: CGPoint(x: size*0.82, y: size*0.25))
        }
        .stroke(color, style: StrokeStyle(lineWidth: size*0.12, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

struct LockIcon: View {
    var size: CGFloat = 16
    var color: Color = Brand.textFaint
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size*0.1).fill(color)
                .frame(width: size*0.6, height: size*0.42).offset(y: size*0.14)
            Path { p in
                p.addArc(center: CGPoint(x: size*0.5, y: size*0.38), radius: size*0.18,
                         startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            }.stroke(color, lineWidth: size*0.1)
        }
        .frame(width: size, height: size)
    }
}

struct ChevronIcon: View {
    var size: CGFloat = 14
    var color: Color = Brand.textDim
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: size*0.4, y: size*0.25))
            p.addLine(to: CGPoint(x: size*0.65, y: size*0.5))
            p.addLine(to: CGPoint(x: size*0.4, y: size*0.75))
        }
        .stroke(color, style: StrokeStyle(lineWidth: size*0.12, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

struct XIcon: View {
    var size: CGFloat = 16
    var color: Color = Brand.textDim
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: size*0.25, y: size*0.25)); p.addLine(to: CGPoint(x: size*0.75, y: size*0.75))
            p.move(to: CGPoint(x: size*0.75, y: size*0.25)); p.addLine(to: CGPoint(x: size*0.25, y: size*0.75))
        }
        .stroke(color, style: StrokeStyle(lineWidth: size*0.12, lineCap: .round))
        .frame(width: size, height: size)
    }
}

struct AnomalyIcon: View {
    var size: CGFloat = 24
    var color: Color = Brand.violet
    var body: some View {
        ZStack {
            ForEach(0..<6, id:\.self){ i in
                Path { p in
                    p.move(to: CGPoint(x: size*0.5, y: size*0.5))
                    p.addLine(to: CGPoint(x: size*0.5, y: size*0.12))
                }.stroke(color.opacity(0.8), lineWidth: size*0.05)
                    .rotationEffect(.degrees(Double(i)*60))
            }
            Circle().fill(color).frame(width: size*0.22, height: size*0.22)
        }
        .frame(width: size, height: size)
    }
}
