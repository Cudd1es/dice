import SwiftUI
import DiceKit

/// Renders every non-panel screen: draft bubble, revealed bubble, result detail and errors.
struct BubbleView: View {
    let screen: Screen

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var content: some View {
        switch screen {
        case .pendingBubble(let spec):
            VStack(alignment: .leading, spacing: 4) {
                FormulaLabel(spec: spec)
                    .font(.headline)
                Text(RollFormatter.pendingCaption)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        case .revealedBubble(let spec, let result):
            ResultView(spec: spec, result: result)
        case .detail(let spec, let result):
            ResultCard(spec: spec, result: result)
        case .invalid(let reason):
            Label(reason == .needsUpdate ? RollFormatter.needsUpdateText : RollFormatter.corruptText,
                  systemImage: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
        case .panel:
            EmptyView()
        }
    }
}

/// Uses an SF Symbol rather than 🎲: the emoji renders as a missing-glyph box inside the extension.
private struct FormulaLabel: View {
    let spec: RollSpec

    var body: some View {
        Label(RollFormatter.formula(spec), systemImage: "dice")
    }
}

private struct ResultView: View {
    let spec: RollSpec
    let result: RollResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormulaLabel(spec: spec)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(verbatim: String(result.total))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(result.totalColor)
            Text(detail)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            if let outcome = RollFormatter.outcome(result) {
                Text(outcome)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(result.outcomeColor)
            }
        }
    }

    private var detail: AttributedString {
        let markdown = RollFormatter.detailMarkdown(spec, result)
        return (try? AttributedString(markdown: markdown)) ?? AttributedString(markdown)
    }
}

private func revealed(_ spec: RollSpec, _ dice: [Int]) -> Screen {
    .revealedBubble(spec, DiceEngine.evaluate(spec, dice: dice))
}

#Preview("pending") { BubbleView(screen: .pendingBubble(RollSpec(mode: .advantage, modifier: 5, dc: 15))) }
#Preview("normal") { BubbleView(screen: revealed(RollSpec(count: 2, sides: 6, modifier: 3), [2, 5])) }
#Preview("critSuccess") { BubbleView(screen: revealed(RollSpec(mode: .advantage, modifier: 5), [20, 8])) }
#Preview("critFailure") { BubbleView(screen: revealed(RollSpec(mode: .disadvantage), [1, 14])) }
#Preview("dcSuccess") { BubbleView(screen: revealed(RollSpec(modifier: 3, dc: 15), [13])) }
#Preview("dcFailure") { BubbleView(screen: revealed(RollSpec(modifier: 3, dc: 15), [9])) }
#Preview("twentyD100") { BubbleView(screen: revealed(RollSpec(count: 20, sides: 100, modifier: -4), Array(81...100))) }
#Preview("needsUpdate") { BubbleView(screen: .invalid(.needsUpdate)) }
#Preview("corrupt") { BubbleView(screen: .invalid(.corrupt)) }
#Preview("twentyD100 dark") {
    BubbleView(screen: revealed(RollSpec(count: 20, sides: 100), Array(81...100))).preferredColorScheme(.dark)
}
#Preview("critSuccess dark") {
    BubbleView(screen: revealed(RollSpec(), [20])).preferredColorScheme(.dark)
}
