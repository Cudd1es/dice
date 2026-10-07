import SwiftUI
import DiceKit

/// DC toggle, stepper and tap-to-type value. Lays out left to right; the caller puts anything else after it.
struct DCControls: View {
    @ObservedObject var model: PanelModel
    var focus: FocusState<PanelField?>.Binding

    private static let defaultDC = 10

    var body: some View {
        Toggle("DC", isOn: Binding(
            get: { model.spec.dc != nil },
            set: { on in
                // Turning DC off drops any typed draft (setDC(nil)); also close the number pad.
                if !on, focus.wrappedValue == .dc { focus.wrappedValue = nil }
                model.setDC(on ? Self.defaultDC : nil)
            }
        ))
        .fixedSize()
        if let dc = model.spec.dc {
            Stepper(value: Binding(get: { dc }, set: { model.setDC($0) }), in: RollSpec.dcRange) {
                value(dc)
            }
        } else {
            Spacer()
        }
    }

    /// Tap the number to type a DC; the stepper is slow for large ones.
    @ViewBuilder
    private func value(_ dc: Int) -> some View {
        // The field must exist before it can take focus, so editing is the model's dcDraft, not the focus state.
        if let draft = model.dcDraft {
            // Starts empty with the current DC as the placeholder, so typing replaces it; leaving it empty keeps it.
            TextField(String(dc), text: Binding(get: { draft }, set: { model.dcDraft = $0 }))
                .keyboardType(.numberPad)
                .focused(focus, equals: .dc)
                .font(.body.monospacedDigit())
                .multilineTextAlignment(.center)
                .frame(width: 56, height: 32)
                .background(Color(.tertiarySystemFill), in: Capsule())
                .overlay { Capsule().strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 1.5) }
                .onAppear { focus.wrappedValue = .dc }
        } else {
            Button {
                model.beginEditingDC()
            } label: {
                Text("\(dc)").font(.body.monospacedDigit())
            }
        }
    }
}
