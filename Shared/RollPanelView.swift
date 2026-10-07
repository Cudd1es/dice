import SwiftUI
import DiceKit

/// The panel's text fields, for focus.
enum PanelField { case purpose, dc }

/// Button panel for building a roll. Reads only the formula, never a result.
struct RollPanelView: View {
    @ObservedObject var model: PanelModel
    let onRoll: () -> Void
    /// Called when a text field takes focus. The extension expands here: Messages shows no keyboard in the compact drawer.
    var onKeyboardFocus: (() -> Void)? = nil
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @FocusState private var focus: PanelField?
    @State private var contentHeight: CGFloat?

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
        // 8pt rather than 12pt between rows, so the panel fits the compact Messages drawer.
        VStack(spacing: 8) {
                PurposeField(model: model, focus: $focus)
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
                if !model.spec.extras.isEmpty {
                    BonusTags(model: model)
                }
                modeRow
                dcAndBonusRow
                Text(RollFormatter.formula(model.spec))
                    .font(.headline.monospacedDigit())
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(RollFormatter.spokenFormula(model.spec))
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

    /// "+ Bonus" lives at the end of the DC row instead of a row of its own, so an unused feature costs no height.
    /// At accessibility text sizes the row is too narrow for both, so the button drops below.
    @ViewBuilder
    private var dcAndBonusRow: some View {
        if dynamicTypeSize.isAccessibilitySize {
            HStack { DCControls(model: model, focus: $focus) }
            HStack {
                BonusButton(model: model, focus: $focus)
                Spacer()
            }
        } else {
            HStack {
                DCControls(model: model, focus: $focus)
                BonusButton(model: model, focus: $focus)
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
                        .accessibilityAddTraits(selected ? .isSelected : [])
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
        // One adjustable element ("Dice, 1", swipe up or down) instead of unlabeled minus and plus buttons.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: change(1)
            case .decrement: change(-1)
            @unknown default: break
            }
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


}
