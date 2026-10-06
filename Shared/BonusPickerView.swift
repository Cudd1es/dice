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
                        .frame(maxWidth: .infinity)
                        .disabled(!model.canAddBonus(sign: sign, sides: sides))
                }
            }
        }
        .padding()
    }
}
