import SwiftUI
import DiceKit

/// Button panel for building a roll. Reads only the formula, never a result.
struct RollPanelView: View {
    @ObservedObject var model: PanelModel
    let onRoll: () -> Void
    /// Called when a text field takes focus. The extension expands here: Messages shows no keyboard in the compact drawer.
    var onKeyboardFocus: (() -> Void)? = nil
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private enum Field { case purpose, dc }
    @FocusState private var focus: Field?
    @State private var dcText = ""
    /// The DC field must exist before it can take focus, so editing is its own state.
    @State private var editingDC = false
    @State private var contentHeight: CGFloat?

    private static let defaultDC = 10

    var body: some View {
        // Full height when it fits; scrolls when space is short (landscape-sized sheets, large text),
        // so the roll button is always reachable.
        // One ScrollView capped at the content's height rather than ViewThatFits: switching between two copies
        // when the keyboard shrinks the space recreated the text field and dropped its focus.
        ScrollView {
            content
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxHeight: contentHeight)
        .onChange(of: focus) { old, new in
            if new != nil { onKeyboardFocus?() }
            if old == .dc, new != .dc {
                model.setDC(text: dcText)
                editingDC = false
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
    }

    private var content: some View {
        VStack(spacing: 12) {
                TextField("Purpose (optional), e.g. Perception check", text: $model.purpose)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .focused($focus, equals: .purpose)
                    // Cut here, not in the model: when a didSet put back the previous value, SwiftUI saw no change
                    // and the field kept showing the extra characters.
                    .onChange(of: model.purpose) { _, text in
                        if text.count > RollPurpose.maxLength { model.purpose = String(text.prefix(RollPurpose.maxLength)) }
                    }
                sidesRow
                // Count and modifier stack vertically at accessibility text sizes, where one row is too wide.
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 8) {
                        countStepper
                        modifierStepper
                    }
                } else {
                    HStack {
                        countStepper
                        Spacer()
                        modifierStepper
                    }
                }
                modeRow
                dcRow
                Text(RollFormatter.formula(model.spec))
                    .font(.headline.monospacedDigit())
                    .frame(maxWidth: .infinity)
                if let error = model.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                Button {
                    focus = nil
                    onRoll()
                } label: {
                    Text("Roll")
                        .font(.title3.weight(.bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding()
    }

    private var countStepper: some View {
        stepper(title: "Dice", value: "\(model.spec.count)") { model.changeCount(by: $0) }
    }

    private var modifierStepper: some View {
        stepper(title: "Modifier", value: modifierText) { model.changeModifier(by: $0) }
    }

    private var modifierText: String {
        model.spec.modifier > 0 ? "+\(model.spec.modifier)" : "\(model.spec.modifier)"
    }

    private var sidesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RollSpec.allowedSides, id: \.self) { sides in
                    let selected = model.spec.sides == sides
                    Button("d\(sides)") { model.selectSides(sides) }
                        .buttonStyle(.bordered)
                        .tint(selected ? .accentColor : .secondary)
                        .fontWeight(selected ? .bold : .regular)
                }
            }
        }
    }

    private func stepper(title: LocalizedStringKey, value: String, change: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .foregroundStyle(.secondary)
                .fixedSize()
            Button { change(-1) } label: { Image(systemName: "minus") }
                .buttonStyle(.bordered)
            Text(value)
                .font(.body.monospacedDigit())
                .frame(minWidth: 32)
            Button { change(1) } label: { Image(systemName: "plus") }
                .buttonStyle(.bordered)
        }
    }

    private var modeRow: some View {
        Picker("Mode", selection: Binding(get: { model.spec.mode }, set: { model.setMode($0) })) {
            Text("Disadvantage").tag(RollMode.disadvantage)
            Text("Normal").tag(RollMode.normal)
            Text("Advantage").tag(RollMode.advantage)
        }
        .pickerStyle(.segmented)
        .disabled(!model.isModeEnabled)
    }

    /// Tap the number to type a DC; the stepper is slow for large ones.
    @ViewBuilder
    private func dcValue(_ dc: Int) -> some View {
        if editingDC {
            // Starts empty with the current DC as the placeholder, so typing replaces it; leaving it empty keeps it.
            TextField(String(dc), text: $dcText)
                .keyboardType(.numberPad)
                .focused($focus, equals: .dc)
                .font(.body.monospacedDigit())
                .frame(maxWidth: 64)
                .onAppear { focus = .dc }
        } else {
            Button {
                dcText = ""
                editingDC = true
            } label: {
                Text("\(dc)").font(.body.monospacedDigit())
            }
        }
    }

    private var dcRow: some View {
        HStack {
            Toggle("DC", isOn: Binding(
                get: { model.spec.dc != nil },
                set: { model.setDC($0 ? Self.defaultDC : nil) }
            ))
            .fixedSize()
            if let dc = model.spec.dc {
                Stepper(value: Binding(get: { dc }, set: { model.setDC($0) }), in: RollSpec.dcRange) {
                    dcValue(dc)
                }
            }
            Spacer()
        }
    }
}
