import SwiftUI

/// House rules, opened from the roller's toolbar. Stored in the App Group so the Messages extension uses them too.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var criticalsEnabled = SettingsStore().criticalsEnabled

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Critical Success & Failure", isOn: $criticalsEnabled)
                } header: {
                    Text("Rules")
                } footer: {
                    Text("On: a natural 20 or 1 is a critical success or failure and decides the DC. Off: only the total is compared with the DC. Rolls you send in Messages use your setting, and the formula shows it.")
                }
            }
            .onChange(of: criticalsEnabled) { _, enabled in SettingsStore().criticalsEnabled = enabled }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview { SettingsView() }
