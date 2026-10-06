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
    @State private var contentHeight: CGFloat?

    private static let defaultDC = 10
    /// The purpose counter appears only near the limit, so the field stays clean otherwise.
    private static let purposeCounterFrom = 30

    var body: some View {
        // Full height when it fits; scrolls when space is short (landscape-sized sheets, large text),
        // so the roll button is always reachable.
        // One ScrollView capped at the content's height rather than ViewThatFits: switching between two copies
        // when the keyboard shrinks the space recreated the text field and dropped its focus.
        // Roll sits below the scrolling part so it is always fully visible, even in the compact Messages drawer
        // where the bonus row made the panel taller than the space.
        VStack(spacing: 0) {
            ScrollView {
                content
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: contentHeight)
            if !model.isPickingBonus {
                rollButton
                    .padding([.horizontal, .bottom])
            }
        }
        .onChange(of: focus) { old, new in
            if new != nil { onKeyboardFocus?() }
            if old == .dc, new != .dc { model.commitDCDraft() }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.isPickingBonus {
            BonusPickerView(model: model)
                .transition(.move(edge: .trailing).combined(with: .opacity))
        } else {
            panel
                .transition(.move(edge: .leading).combined(with: .opacity))
        }
    }

    private var panel: some View {
        VStack(spacing: 12) {
                purposeField
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
                bonusRow
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
        }
        .padding()
    }

    private var rollButton: some View {
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

    /// Bonus dice tags, each with a menu to change or remove it, then the button that opens the picker.
    private var bonusRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(model.spec.extras.enumerated()), id: \.offset) { index, group in
                    Menu {
                        Button("One More", systemImage: "plus") { model.incrementBonus(at: index) }
                            .disabled(group.count >= BonusDice.countRange.upperBound)
                        Button("One Fewer", systemImage: "minus") { model.decrementBonus(at: index) }
                        Button("Remove", systemImage: "trash", role: .destructive) { model.removeBonus(at: index) }
                    } label: {
                        Text(verbatim: (group.sign == .plus ? "+" : "−") + "\(group.count)d\(group.sides)")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
                }
                Button("Bonus", systemImage: "plus") {
                    focus = nil
                    withAnimation(BonusPickerView.animation) { model.isPickingBonus = true }
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            }
        }
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

    /// Filled like the panel's buttons rather than the system's bordered style. Shows a clear button once there is
    /// text and a counter near the limit.
    private var purposeField: some View {
        HStack(spacing: 8) {
            Image(systemName: "pencil")
                .foregroundStyle(.secondary)
            TextField("Purpose (optional), e.g. Perception check", text: $model.purpose)
                .submitLabel(.done)
                .focused($focus, equals: .purpose)
                // Cut here, not in the model: when a didSet put back the previous value, SwiftUI saw no change
                // and the field kept showing the extra characters.
                .onChange(of: model.purpose) { _, text in
                    if text.count > RollPurpose.maxLength { model.purpose = String(text.prefix(RollPurpose.maxLength)) }
                }
            if model.purpose.count > Self.purposeCounterFrom {
                Text(verbatim: "\(model.purpose.count)/\(RollPurpose.maxLength)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if !model.purpose.isEmpty {
                Button {
                    model.purpose = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear purpose")
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 40)
        .background(Color(.tertiarySystemFill), in: Capsule())
        .overlay {
            Capsule().strokeBorder(Color.accentColor.opacity(focus == .purpose ? 0.6 : 0), lineWidth: 1.5)
        }
        .contentShape(Capsule())
        .onTapGesture { focus = .purpose }
        .animation(.easeOut(duration: 0.15), value: focus)
    }

    /// Tap the number to type a DC; the stepper is slow for large ones.
    @ViewBuilder
    private func dcValue(_ dc: Int) -> some View {
        // The field must exist before it can take focus, so editing is the model's dcDraft, not the focus state.
        if let draft = model.dcDraft {
            // Starts empty with the current DC as the placeholder, so typing replaces it; leaving it empty keeps it.
            TextField(String(dc), text: Binding(get: { draft }, set: { model.dcDraft = $0 }))
                .keyboardType(.numberPad)
                .focused($focus, equals: .dc)
                .font(.body.monospacedDigit())
                .multilineTextAlignment(.center)
                .frame(width: 56, height: 32)
                .background(Color(.tertiarySystemFill), in: Capsule())
                .overlay { Capsule().strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 1.5) }
                .onAppear { focus = .dc }
        } else {
            Button {
                model.beginEditingDC()
            } label: {
                Text("\(dc)").font(.body.monospacedDigit())
            }
        }
    }

    private var dcRow: some View {
        HStack {
            Toggle("DC", isOn: Binding(
                get: { model.spec.dc != nil },
                set: { on in
                    // Turning DC off drops any typed draft (setDC(nil)); also close the number pad.
                    if !on, focus == .dc { focus = nil }
                    model.setDC(on ? Self.defaultDC : nil)
                }
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
