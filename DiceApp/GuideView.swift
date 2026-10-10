import SwiftUI

/// How to use the app and the iMessage extension; opened from the roller's toolbar.
struct GuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Set your dice on this screen and tap Roll. The result shows at the top; the last 10 rolls are kept until you close the app.", systemImage: "dice")
                } header: {
                    Text("Roll in the App")
                }
                Section("Decide with a Check") {
                    Label("Write the question as the purpose, like “Buy the shoes?”", systemImage: "questionmark.bubble")
                    Label("Set a DC for how much it deserves to happen: low if it's sensible, high if it's doubtful", systemImage: "scalemass")
                    Label("Add a modifier or advantage for how much you want it", systemImage: "heart")
                    Label("Roll a d20: success means do it", systemImage: "checkmark.circle")
                }
                Section("Panel Tips") {
                    Label("Advantage and disadvantage need exactly one d20 as the main die", systemImage: "arrow.up.arrow.down")
                    Label("Tap the DC number to type a value up to 999", systemImage: "number")
                    Label("Tap + Bonus to add dice such as +1d4 for Bless or −1d4 for Bane; tap a bonus tag to change or remove it", systemImage: "plus.square.on.square")
                    Label("Turn critical success and failure on or off in Settings", systemImage: "gearshape")
                }
                Section("Use in Messages") {
                    Label("Open Messages and go to a conversation", systemImage: "message")
                    Label("Tap + next to the text field and choose Dicide", systemImage: "plus.circle")
                    Label("Set your dice and tap Roll; the roll goes into the text field", systemImage: "dice")
                    Label("To say what the roll is for (like “attack the goblin”), type it at the top of the panel; it shows in the bubble", systemImage: "text.bubble")
                    Label("Once sent, the bubble shows the result, the same for everyone", systemImage: "paperplane")
                    Label("Tap a sent roll to see the full result and purpose", systemImage: "hand.tap")
                }
                Section {
                    Text("The result is fixed when you tap Roll and nobody sees it before it's sent, so deleting and rolling again doesn't help.")
                        .foregroundStyle(.secondary)
                    Text("Everyone in the chat needs Dicide to see the result; others only see the formula and an install prompt.")
                        .foregroundStyle(.secondary)
                }
                Section("About") {
                    Link("Privacy Policy", destination: Self.privacyURL)
                    Link("Support", destination: Self.supportURL)
                    LabeledContent("Version", value: Self.version)
                    // CC-BY-4.0 requires this attribution wherever the preset names are used.
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Bonus presets for spells and class features come from the System Reference Document 5.2.1.")
                        Text(verbatim: Self.srdAttribution)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("How to Use")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

extension GuideView {
    static let privacyURL = URL(string: "https://github.com/Cudd1es/dice/blob/main/docs/privacy.md")!
    static let supportURL = URL(string: "https://github.com/Cudd1es/dice/blob/main/docs/support.md")!

    static var version: String {
        let info = Bundle.main.infoDictionary
        let marketing = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(marketing) (\(build))"
    }

    static let srdAttribution = """
        This work includes material from the System Reference Document 5.2.1 ("SRD 5.2.1") by Wizards of the Coast \
        LLC, available at https://www.dndbeyond.com/srd. The SRD 5.2.1 is licensed under the Creative Commons \
        Attribution 4.0 International License, available at https://creativecommons.org/licenses/by/4.0/legalcode.
        """
}

#Preview { GuideView() }
