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
                    // Small, so the row is barely taller than the formula row it shares (TagsAndFormulaLayout).
                    .controlSize(.small)
                    // "−1d6" uses a minus sign that VoiceOver may read oddly; say the action instead.
                    .accessibilityLabel(group.sign == .plus ? Text("Add \(group.count)d\(group.sides)")
                                                            : Text("Subtract \(group.count)d\(group.sides)"))
                    .accessibilityHint("Change or remove this bonus")
                }
            }
        }
    }
}

/// Bonus tags on the left and the formula on the right in one row, split by `RowSplit`. A separate tags row pushed
/// the formula below the fold of the compact Messages drawer. Expects exactly two subviews: tags, then formula.
struct TagsAndFormulaLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let split = widths(width, subviews)
        let height = max(subviews[0].sizeThatFits(ProposedViewSize(width: split.leading, height: nil)).height,
                         subviews[1].sizeThatFits(ProposedViewSize(width: split.trailing, height: nil)).height)
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let split = widths(bounds.width, subviews)
        subviews[0].place(at: CGPoint(x: bounds.minX, y: bounds.midY), anchor: .leading,
                          proposal: ProposedViewSize(width: split.leading, height: bounds.height))
        subviews[1].place(at: CGPoint(x: bounds.maxX, y: bounds.midY), anchor: .trailing,
                          proposal: ProposedViewSize(width: split.trailing, height: nil))
    }

    private func widths(_ available: CGFloat, _ subviews: Subviews) -> (leading: CGFloat, trailing: CGFloat) {
        RowSplit.widths(available: available,
                        leading: subviews[0].sizeThatFits(.unspecified).width,
                        trailing: subviews[1].sizeThatFits(.unspecified).width,
                        spacing: spacing)
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
