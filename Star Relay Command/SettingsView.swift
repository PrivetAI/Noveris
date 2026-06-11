import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: GameStore
    @EnvironmentObject var settings: AppSettings
    @State private var showReset = false
    @State private var showPrivacy = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Preferences", accent: Brand.cyan)
                ConsoleCard(accent: Brand.cyan) {
                    VStack(spacing: 12) {
                        toggleRow("Sound", isOn: $settings.sound, icon: AnyView(BoltIcon(size: 16, color: Brand.amber)))
                        Divider().background(Brand.stroke)
                        toggleRow("Haptics", isOn: $settings.haptics, icon: AnyView(GearIcon(size: 16, color: Brand.teal)))
                    }
                }

                SectionHeader(title: "About", accent: Brand.teal)
                ConsoleCard(accent: Brand.teal) {
                    VStack(spacing: 10) {
                        Button(action: { showPrivacy = true }) {
                            HStack {
                                BookIcon(size: 16, color: Brand.cyan)
                                Text("Privacy Policy").font(.console(13, weight: .semibold)).foregroundColor(Brand.text)
                                Spacer()
                                ChevronIcon(size: 14, color: Brand.textDim)
                            }
                        }.buttonStyle(.plain)
                        Divider().background(Brand.stroke)
                        HStack {
                            Text("Version").font(.console(12)).foregroundColor(Brand.textDim)
                            Spacer()
                            Text("1.0").font(.console(12, weight: .semibold)).foregroundColor(Brand.text)
                        }
                    }
                }

                SectionHeader(title: "Data", accent: Brand.red)
                Button(action: { showReset = true }) {
                    HStack {
                        XIcon(size: 16, color: Brand.red)
                        Text("Reset Progress").font(.console(13, weight: .bold)).foregroundColor(Brand.red)
                        Spacer()
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Brand.red.opacity(0.5), lineWidth: 1))
                }.buttonStyle(.plain)

                Text("Resetting wipes your entire command network and starts a new game.")
                    .font(.console(10)).foregroundColor(Brand.textFaint)
            }
            .padding(16)
            .clampedContent()
        }
        .background(Brand.background())
        .navigationBarTitle("Settings", displayMode: .inline)
        .alert(isPresented: $showReset) {
            Alert(
                title: Text("Reset Progress?"),
                message: Text("This permanently erases your network. This cannot be undone."),
                primaryButton: .destructive(Text("Reset")) { store.resetProgress() },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showPrivacy) {
            StarRelayWebPanel(urlString: "https://example.com")
                .edgesIgnoringSafeArea(.bottom)
                .background(Color.black.ignoresSafeArea())
        }
    }

    private func toggleRow(_ label: String, isOn: Binding<Bool>, icon: AnyView) -> some View {
        HStack {
            icon.frame(width: 22)
            Text(label).font(.console(13, weight: .semibold)).foregroundColor(Brand.text)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(Brand.cyan)
        }
    }
}
