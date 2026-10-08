import SwiftUI
import DiceKit

/// The revealed result, centered in the space it is given: the extension's full-screen sheet or the app's result area.
struct ResultCard: View {
    let spec: RollSpec
    let result: RollResult
    var purpose: String?
    var onRollAgain: (() -> Void)?
    /// Smaller in the app's result area on short screens such as iPhone SE.
    var totalFontSize: CGFloat = 72
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 6) {
                    summary
                        // One VoiceOver element that also says which die was kept; Roll Again stays separate.
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(RollFormatter.spokenResult(spec, result, purpose: purpose))
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

    /// Accessibility text sizes: the purpose keeps one line and the total shrinks, so the outcome stays on screen.
    private var isLargeText: Bool { dynamicTypeSize.isAccessibilitySize }

    private var summary: some View {
        VStack(spacing: 6) {
            if let purpose {
                Text(purpose)
                    .font(.headline)
                    .lineLimit(isLargeText ? 1 : 2)
                    .multilineTextAlignment(.center)
            }
            Label(RollFormatter.formula(spec), systemImage: "dice")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            // The outcome sits beside the total, not below the breakdown: at large text sizes the breakdown is
            // below the fold, and the color alone would be the only sign of a critical.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 12) { total; outcomeBadge }
                VStack(spacing: 6) { total; outcomeBadge }
            }
            Text(detail)
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var total: some View {
        Text(verbatim: String(result.total))
            .font(.system(size: isLargeText ? totalFontSize * 0.7 : totalFontSize, weight: .bold, design: .rounded))
            .foregroundStyle(result.totalColor)
            .contentTransition(.numericText())
    }

    @ViewBuilder
    private var outcomeBadge: some View {
        if let outcome = RollFormatter.outcome(result) {
            Text(outcome)
                .font(.headline)
                .foregroundStyle(result.outcomeColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(result.outcomeTint.opacity(0.15), in: Capsule())
                .fixedSize()
        }
    }

    private var detail: AttributedString {
        let markdown = RollFormatter.detailMarkdown(spec, result)
        return (try? AttributedString(markdown: markdown)) ?? AttributedString(markdown)
    }
}

extension RollResult {
    /// Text colors: in light mode darker than the system colors, which are about 2.2:1 on white (orange, green),
    /// below WCAG AA's 4.5:1; these are 4.6:1 or more on white and on the outcome badge. Dark mode keeps the system
    /// colors, which already pass.
    var totalColor: Color {
        switch critical {
        case .success: return .readableOrange
        case .failure: return .readableRed
        case .none: return .primary
        }
    }

    var outcomeColor: Color {
        switch (critical, dcOutcome) {
        case (.success, _): return .readableOrange
        case (.failure, _): return .readableRed
        case (.none, .success): return .readableGreen
        default: return .secondary
        }
    }

    /// The badge's light fill keeps the system hue, so it looks the same as before.
    var outcomeTint: Color {
        switch (critical, dcOutcome) {
        case (.success, _): return .orange
        case (.failure, _): return .red
        case (.none, .success): return .green
        default: return .secondary
        }
    }
}

private extension Color {
    static let readableOrange = adaptive(light: 0xB25000, dark: .systemOrange)
    static let readableRed = adaptive(light: 0xC4261D, dark: .systemRed)
    static let readableGreen = adaptive(light: 0x1E7B34, dark: .systemGreen)

    static func adaptive(light hex: Int, dark: UIColor) -> Color {
        let light = UIColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
                            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        return Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
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
