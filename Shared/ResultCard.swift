import SwiftUI
import DiceKit

/// The revealed result, centered in the space it is given: the extension's full-screen sheet or the app's result area.
struct ResultCard: View {
    let spec: RollSpec
    let result: RollResult
    var onRollAgain: (() -> Void)?
    /// Smaller in the app's result area on short screens such as iPhone SE.
    var totalFontSize: CGFloat = 72

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 6) {
                    Label(RollFormatter.formula(spec), systemImage: "dice")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(verbatim: String(result.total))
                        .font(.system(size: totalFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(result.totalColor)
                        .contentTransition(.numericText())
                    Text(detail)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    if let outcome = RollFormatter.outcome(result) {
                        Text(outcome)
                            .font(.headline)
                            .foregroundStyle(result.outcomeColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                            .background(result.outcomeColor.opacity(0.15), in: Capsule())
                    }
                    if let onRollAgain {
                        Button("Roll Again", systemImage: "arrow.counterclockwise", action: onRollAgain)
                            .buttonStyle(.bordered)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
        // In the extension, the expanded sheet reports a large bottom inset (~335pt on iPhone 17 Pro) over empty space,
        // which pushed the card into the upper half; ignoring only .container was not enough.
        .ignoresSafeArea(.all, edges: .bottom)
    }

    private var detail: AttributedString {
        let markdown = RollFormatter.detailMarkdown(spec, result)
        return (try? AttributedString(markdown: markdown)) ?? AttributedString(markdown)
    }
}

extension RollResult {
    var totalColor: Color {
        switch critical {
        case .success: return .orange
        case .failure: return .red
        case .none: return .primary
        }
    }

    var outcomeColor: Color {
        switch (critical, dcOutcome) {
        case (.success, _): return .orange
        case (.failure, _): return .red
        case (.none, .success): return .green
        default: return .secondary
        }
    }
}

private func card(_ spec: RollSpec, _ dice: [Int]) -> ResultCard {
    ResultCard(spec: spec, result: DiceEngine.evaluate(spec, dice: dice), onRollAgain: {})
}

#Preview("dcSuccess") { card(RollSpec(mode: .advantage, modifier: 5, dc: 15), [17, 8]).frame(height: 330) }
#Preview("critSuccess") { card(RollSpec(), [20]).frame(height: 330) }
#Preview("critFailure") { card(RollSpec(mode: .disadvantage), [1, 14]).frame(height: 330) }
#Preview("plain") { card(RollSpec(count: 2, sides: 6, modifier: 3), [2, 5]).frame(height: 330) }
#Preview("twentyD100") { card(RollSpec(count: 20, sides: 100, modifier: -4), Array(81...100)).frame(height: 330) }
#Preview("dark") { card(RollSpec(modifier: 3, dc: 15), [9]).frame(height: 330).preferredColorScheme(.dark) }
