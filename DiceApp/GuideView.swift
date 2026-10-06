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
                Section("Use in Messages") {
                    Label("Open Messages and go to a conversation", systemImage: "message")
                    Label("Tap + next to the text field and choose DND Dice", systemImage: "plus.circle")
                    Label("Set your dice and tap Roll; the roll goes into the text field", systemImage: "dice")
                    Label("To say what the roll is for (like “attack the goblin”), type it in the text field before sending", systemImage: "text.bubble")
                    Label("Once sent, the bubble shows the result, the same for everyone", systemImage: "paperplane")
                }
                Section {
                    Text("The result is fixed when you tap Roll and nobody sees it before it's sent, so deleting and rolling again doesn't help.")
                        .foregroundStyle(.secondary)
                    Text("Everyone in the chat needs DND Dice to see the result; others only see the formula and an install prompt.")
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

#Preview { GuideView() }
