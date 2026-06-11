import SwiftUI

struct ConvoyPlannerView: View {
    @EnvironmentObject var store: GameStore
    @State private var showNewRoute = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !store.canBuildConvoyAnywhere() {
                    ConsoleCard(accent: Brand.amber) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("No Shipyard").font(.console(14, weight: .bold)).foregroundColor(Brand.text)
                            Text("Research Shipwright Doctrine and build a Shipyard in a claimed system to commission convoys.")
                                .font(.console(11)).foregroundColor(Brand.textDim)
                        }
                    }
                }

                SectionHeader(title: "Convoy Fleet (\(store.state.convoys.count))", accent: Brand.green)
                buildConvoyButtons()
                if store.state.convoys.isEmpty {
                    Text("No convoys commissioned yet.")
                        .font(.console(12)).foregroundColor(Brand.textDim).padding(.vertical, 8)
                } else {
                    ForEach(store.state.convoys) { conv in
                        convoyCard(conv)
                    }
                }

                HStack {
                    SectionHeader(title: "Cargo Routes (\(store.state.routes.count))", accent: Brand.cyan)
                    Button(action: { showNewRoute = true }) {
                        Text("+ NEW").font(.console(12, weight: .bold)).foregroundColor(Brand.space)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Brand.cyan))
                    }.buttonStyle(.plain)
                    .disabled(store.state.claimedCount < 2)
                    .opacity(store.state.claimedCount < 2 ? 0.5 : 1)
                }
                if store.state.routes.isEmpty {
                    Text("No routes defined. Create a route between two claimed systems.")
                        .font(.console(12)).foregroundColor(Brand.textDim).padding(.vertical, 8)
                } else {
                    ForEach(store.state.routes) { route in
                        routeCard(route)
                    }
                }
            }
            .padding(16)
            .clampedContent()
        }
        .background(Brand.background())
        .navigationBarTitle("Convoys & Routes", displayMode: .inline)
        .sheet(isPresented: $showNewRoute) {
            NewRouteSheet(close: { showNewRoute = false }).environmentObject(store)
        }
    }

    private func buildConvoyButtons() -> some View {
        let yards = store.shipyardSystems()
        return VStack(spacing: 8) {
            ForEach(yards, id: \.self) { sid in
                Button(action: { store.buildConvoy(at: sid) }) {
                    HStack {
                        ConvoyShipIcon(size: 18, color: Brand.space)
                        Text("Build Convoy at \(Galaxy.system(sid).name)").font(.console(13, weight: .bold))
                        Spacer()
                        Text("50 ALY · 20 CMP · 20 FUL · 120 CR").font(.console(9))
                    }
                    .foregroundColor(Brand.space)
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 9).fill(Brand.green))
                    .opacity(store.canAfford([.alloy:50,.components:20,.fuel:20,.credits:120]) ? 1 : 0.5)
                }.buttonStyle(.plain)
            }
        }
    }

    private func convoyCard(_ conv: Convoy) -> some View {
        let route = store.state.routes.first { $0.id == conv.routeId }
        return ConsoleCard(accent: conv.idle ? Brand.textFaint : Brand.green) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ConvoyShipIcon(size: 20, color: conv.idle ? Brand.textFaint : Brand.green)
                    Text(conv.name).font(.console(14, weight: .bold)).foregroundColor(Brand.text)
                    Spacer()
                    Text(conv.idle ? "IDLE" : "ACTIVE")
                        .font(.console(10, weight: .bold))
                        .foregroundColor(conv.idle ? Brand.textFaint : Brand.green)
                }
                if let route = route {
                    HStack(spacing: 6) {
                        ResourceGlyph(kind: (ResourceID(rawValue: route.resource) ?? .alloy).icon, size: 13,
                                      color: (ResourceID(rawValue: route.resource) ?? .alloy).color)
                        Text("\(Galaxy.system(route.origin).name) → \(Galaxy.system(route.destination).name)")
                            .font(.console(10)).foregroundColor(Brand.textDim).lineLimit(1)
                    }
                    HStack(spacing: 6) {
                        Text("At: \(Galaxy.system(conv.currentSystem).name)").font(.console(9)).foregroundColor(Brand.textFaint)
                        if conv.carrying > 0 {
                            Text("· carrying \(Fmt.compact(conv.carrying))").font(.console(9)).foregroundColor(Brand.teal)
                        }
                    }
                    Button(action: { store.unassignConvoy(conv.id) }) {
                        Text("UNASSIGN").font(.console(11, weight: .bold)).foregroundColor(Brand.red)
                            .frame(maxWidth: .infinity).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).stroke(Brand.red.opacity(0.5), lineWidth: 1))
                    }.buttonStyle(.plain)
                } else {
                    if store.state.routes.isEmpty {
                        Text("Create a route, then assign this convoy.").font(.console(10)).foregroundColor(Brand.textFaint)
                    } else {
                        Menu {
                            ForEach(store.state.routes) { r in
                                Button("\(Galaxy.system(r.origin).name) → \(Galaxy.system(r.destination).name) (\((ResourceID(rawValue: r.resource) ?? .alloy).short))") {
                                    store.assignConvoy(conv.id, to: r.id)
                                }
                            }
                        } label: {
                            Text("ASSIGN ROUTE").font(.console(11, weight: .bold)).foregroundColor(Brand.space)
                                .frame(maxWidth: .infinity).padding(.vertical, 7)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Brand.cyan))
                        }
                    }
                }
            }
        }
    }

    private func routeCard(_ route: CargoRoute) -> some View {
        let res = ResourceID(rawValue: route.resource) ?? .alloy
        let assignedCount = store.state.convoys.filter { $0.routeId == route.id }.count
        return ConsoleCard(accent: res.color) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    ResourceGlyph(kind: res.icon, size: 16, color: res.color)
                    Text(res.name).font(.console(13, weight: .bold)).foregroundColor(Brand.text)
                    Spacer()
                    Text(route.loop ? "LOOP" : "ONE-WAY").font(.console(9, weight: .bold)).foregroundColor(Brand.textDim)
                }
                Text("\(Galaxy.system(route.origin).name) → \(Galaxy.system(route.destination).name)")
                    .font(.console(11)).foregroundColor(Brand.textDim)
                HStack {
                    Text("Up to \(Fmt.compact(route.amountPerRun)) / run · \(assignedCount) convoy(s)")
                        .font(.console(9)).foregroundColor(Brand.textFaint)
                    Spacer()
                    Button(action: { store.deleteRoute(route.id) }) {
                        XIcon(size: 14, color: Brand.red)
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - New route sheet
struct NewRouteSheet: View {
    @EnvironmentObject var store: GameStore
    var close: () -> Void
    @State private var origin: Int = 0
    @State private var destination: Int = -1
    @State private var resource: ResourceID = .alloy
    @State private var amount: Double = 100
    @State private var loop: Bool = true

    private var claimed: [Int] { store.state.systems.filter { $0.claimed }.map { $0.id } }
    private let resources: [ResourceID] = [.ferrite, .cuprite, .silicate, .isotope, .alloy, .fuel, .components, .food]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    pickerCard(title: "Origin", accent: Brand.teal) {
                        systemPicker(selection: $origin)
                    }
                    pickerCard(title: "Destination", accent: Brand.cyan) {
                        systemPicker(selection: $destination, exclude: origin)
                    }
                    pickerCard(title: "Cargo", accent: resource.color) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(resources, id: \.self) { r in
                                    Button(action: { resource = r }) {
                                        HStack(spacing: 4) {
                                            ResourceGlyph(kind: r.icon, size: 14, color: r.color)
                                            Text(r.short).font(.console(11, weight: .bold))
                                        }
                                        .foregroundColor(resource == r ? Brand.space : Brand.text)
                                        .padding(.horizontal, 10).padding(.vertical, 7)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(resource == r ? r.color : Brand.panelHi))
                                    }.buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    pickerCard(title: "Amount per run: \(Int(amount))", accent: Brand.amber) {
                        Slider(value: $amount, in: 20...400, step: 20).accentColor(Brand.amber)
                    }
                    pickerCard(title: "Mode", accent: Brand.green) {
                        HStack(spacing: 10) {
                            modeButton("Loop", true)
                            modeButton("One-Way", false)
                        }
                    }

                    let valid = destination >= 0 && destination != origin && claimed.contains(origin) && claimed.contains(destination)
                    let pathOK = valid && Galaxy.path(from: origin, to: destination, unlockedTech: store.state.unlockedTech) != nil
                    Button(action: {
                        if pathOK {
                            store.addRoute(origin: origin, destination: destination, resource: resource, amount: amount, loop: loop)
                            close()
                        }
                    }) {
                        Text(pathOK ? "CREATE ROUTE" : (valid ? "No relay path available" : "Select origin & destination"))
                    }
                    .buttonStyle(ConsoleButton(accent: pathOK ? Brand.cyan : Brand.textFaint))
                    .disabled(!pathOK)
                }
                .padding(16)
                .clampedContent()
            }
            .background(Brand.background())
            .navigationBarTitle("New Route", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close", action: close).foregroundColor(Brand.cyan))
            .onAppear { if let first = claimed.first { origin = first } }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func modeButton(_ label: String, _ value: Bool) -> some View {
        Button(action: { loop = value }) {
            Text(label).font(.console(12, weight: .bold))
                .foregroundColor(loop == value ? Brand.space : Brand.text)
                .frame(maxWidth: .infinity).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(loop == value ? Brand.green : Brand.panelHi))
        }.buttonStyle(.plain)
    }

    private func pickerCard<C: View>(title: String, accent: Color, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: title, accent: accent)
            content()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Brand.panel))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Brand.stroke, lineWidth: 1))
    }

    private func systemPicker(selection: Binding<Int>, exclude: Int = -99) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(claimed.filter { $0 != exclude }, id: \.self) { sid in
                    Button(action: { selection.wrappedValue = sid }) {
                        Text(Galaxy.system(sid).name).font(.console(11, weight: .bold))
                            .foregroundColor(selection.wrappedValue == sid ? Brand.space : Brand.text)
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 8).fill(selection.wrappedValue == sid ? Brand.cyan : Brand.panelHi))
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}
