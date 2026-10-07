import SwiftUI
import DiceKit

/// Second level of the panel: pick one bonus die to add or subtract. Choosing one adds it and returns at once.
/// Shown in place of the panel rather than pushed, so the app and the Messages drawer behave the same.
struct BonusPickerView: View {
    @ObservedObject var model: PanelModel
    @State private var sign = BonusDice.Sign.plus

    static let animation = Animation.easeOut(duration: 0.2)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button("Back", systemImage: "chevron.left") { withAnimation(Self.animation) { model.isPickingBonus = false } }
                Spacer()
                Text("Bonus Dice").font(.headline)
                Spacer()
                // Balances the back button so the title stays centered.
                Button("Back", systemImage: "chevron.left") {}.hidden()
            }
            Picker("Bonus Dice", selection: $sign) {
                Text("Add").tag(BonusDice.Sign.plus)
                Text("Subtract").tag(BonusDice.Sign.minus)
            }
            .pickerStyle(.segmented)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 8)], spacing: 8) {
                ForEach(BonusDice.allowedSides, id: \.self) { sides in
                    Button("d\(sides)") { withAnimation(Self.animation) { model.addBonus(sign: sign, sides: sides) } }
                        .buttonStyle(.bordered)
                        .tint(.accentColor)
                        .frame(maxWidth: .infinity)
                        .disabled(!model.canAddBonus(sign: sign, sides: sides))
                }
            }
            presets
        }
        .padding()
    }

    // Buttons are tinted, not the default bordered grey: that grey vanished against the Messages drawer background.

    /// Common bonuses from the rules, one tap each. They ignore the Add/Subtract switch: each carries its own sign.
    private var presets: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Checks").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
            presetGrid(BonusPreset.checks)
            HStack(spacing: 8) {
                Text(BonusPreset.bardicInspiration[0].name)
                    .font(.subheadline)
                    .fixedSize()
                Spacer(minLength: 0)
                ForEach(BonusPreset.bardicInspiration) { preset in
                    Button("d\(preset.sides)") { add(preset) }
                        .buttonStyle(.bordered)
                        .tint(.accentColor)
                        .disabled(!model.canAddPreset(preset))
                }
            }
            Text("Damage").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                .padding(.top, 4)
            presetGrid(BonusPreset.damage)
        }
    }

    private func presetGrid(_ presets: [BonusPreset]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
            ForEach(presets) { preset in
                Button { add(preset) } label: {
                    HStack(spacing: 4) {
                        Text(preset.name).lineLimit(1)
                        Text(verbatim: preset.diceText).fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.accentColor)
                .disabled(!model.canAddPreset(preset))
            }
        }
    }

    private func add(_ preset: BonusPreset) {
        withAnimation(Self.animation) { model.addPreset(preset) }
    }
}
