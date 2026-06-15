import SwiftUI

struct CodexView: View {
    @State private var category: CodexCategory = .modules

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CodexCategory.allCases) { cat in
                            Button(action: { category = cat }) {
                                Text(cat.title).font(.console(12, weight: .bold))
                                    .foregroundColor(category == cat ? Brand.space : Brand.text)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 9).fill(category == cat ? Brand.cyan : Brand.panelHi))
                            }.buttonStyle(.plain)
                        }
                    }
                }
                ForEach(Codex.entries(for: category)) { entry in
                    ConsoleCard(accent: entry.accent) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Circle().fill(entry.accent).frame(width: 8, height: 8)
                                Text(entry.title).font(.console(14, weight: .bold)).foregroundColor(Brand.text)
                                Spacer()
                            }
                            Text(entry.body).font(.console(11)).foregroundColor(Brand.textDim).lineSpacing(3)
                        }
                    }
                }
            }
            .padding(16)
            .clampedContent()
        }
        .background(Brand.background())
        .navigationBarTitle("Codex", displayMode: .inline)
    }
}
