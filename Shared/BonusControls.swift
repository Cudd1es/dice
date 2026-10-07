import SwiftUI
import DiceKit

/// Tags for the bonus dice already added, each with a menu to change or remove it. Shown only when there are any.
struct BonusTags: View {
    @ObservedObject var model: PanelModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Keyed by the group itself: sign and sides are unique, so a removed tag's identity is not reused.
                ForEach(Array(model.spec.extras.enumerated()), id: \.element) { index, group in
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
            }
        }
    }
}

/// Opens the bonus dice picker in place of the panel.
struct BonusButton: View {
    @ObservedObject var model: PanelModel
    var focus: FocusState<PanelField?>.Binding

    var body: some View {
        Button("Bonus", systemImage: "plus") {
            focus.wrappedValue = nil
            withAnimation(BonusPickerView.animation) { model.isPickingBonus = true }
        }
        .buttonStyle(.bordered)
        .tint(.secondary)
        .fixedSize()
    }
}
