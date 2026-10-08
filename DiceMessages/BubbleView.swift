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
        case .pendingBubble(let spec, let purpose):
            VStack(alignment: .leading, spacing: 4) {
                PurposeLine(purpose: purpose)
                FormulaLabel(spec: spec)
                    .font(.headline)
                    .clearsAppIcon(purpose == nil)
                Text(RollFormatter.pendingCaption())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel([purpose, RollFormatter.spokenFormula(spec), RollFormatter.pendingCaption()]
                .compactMap { $0 }.joined(separator: RollLanguage.current == .english ? ". " : "。"))
        case .revealedBubble(let spec, let result, let purpose):
            VStack(alignment: .leading, spacing: 4) {
                PurposeLine(purpose: purpose)
                ResultView(spec: spec, result: result, clearsAppIcon: purpose == nil)
            }
            // One element that also says which die was kept (the struck-through one is not read aloud).
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(RollFormatter.spokenResult(spec, result, purpose: purpose))
        case .detail(let spec, let result, let purpose):
            ResultCard(spec: spec, result: result, purpose: purpose)
        case .invalid(let reason):
            Label(reason == .needsUpdate ? RollFormatter.needsUpdateText() : RollFormatter.corruptText(),
                  systemImage: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
                .clearsAppIcon()
        case .panel:
            EmptyView()
        }
    }
}

private extension View {
    /// Messages draws the app's small icon (about 32x24pt) over the bubble's top-left corner, so the first line
    /// starts to its right. Seen on device: without this the icon hid the start of the purpose or formula.
    func clearsAppIcon(_ clears: Bool = true) -> some View {
        padding(.leading, clears ? 30 : 0)
    }
}

/// One line so a long purpose cannot grow the bubble.
private struct PurposeLine: View {
    let purpose: String?

    var body: some View {
        if let purpose {
            Text(purpose)
                .font(.headline)
                .lineLimit(1)
                .clearsAppIcon()
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
    let clearsAppIcon: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormulaLabel(spec: spec)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .clearsAppIcon(clearsAppIcon)
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
    .revealedBubble(spec, DiceEngine.evaluate(spec, dice: dice), purpose: nil)
}

#Preview("pending") { BubbleView(screen: .pendingBubble(RollSpec(mode: .advantage, modifier: 5, dc: 15), purpose: nil)) }
#Preview("normal") { BubbleView(screen: revealed(RollSpec(count: 2, sides: 6, modifier: 3), [2, 5])) }
#Preview("critSuccess") { BubbleView(screen: revealed(RollSpec(mode: .advantage, modifier: 5), [20, 8])) }
#Preview("critFailure") { BubbleView(screen: revealed(RollSpec(mode: .disadvantage), [1, 14])) }
#Preview("dcSuccess") { BubbleView(screen: revealed(RollSpec(modifier: 3, dc: 15), [13])) }
#Preview("dcFailure") { BubbleView(screen: revealed(RollSpec(modifier: 3, dc: 15), [9])) }
#Preview("twentyD100") { BubbleView(screen: revealed(RollSpec(count: 20, sides: 100, modifier: -4), Array(81...100))) }
#Preview("purpose") {
    BubbleView(screen: .revealedBubble(RollSpec(mode: .advantage, modifier: 5, dc: 15),
                                       DiceEngine.evaluate(RollSpec(mode: .advantage, modifier: 5, dc: 15), dice: [17, 8]),
                                       purpose: "察觉检定：门后有没有人，还是只是风声在作怪呢？"))
}
#Preview("needsUpdate") { BubbleView(screen: .invalid(.needsUpdate)) }
#Preview("corrupt") { BubbleView(screen: .invalid(.corrupt)) }
#Preview("twentyD100 dark") {
    BubbleView(screen: revealed(RollSpec(count: 20, sides: 100), Array(81...100))).preferredColorScheme(.dark)
}
#Preview("critSuccess dark") {
    BubbleView(screen: revealed(RollSpec(), [20])).preferredColorScheme(.dark)
}
