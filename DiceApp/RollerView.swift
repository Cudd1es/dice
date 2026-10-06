import SwiftUI
import DiceKit

/// Home screen: roll with the shared panel and see the result, like a physical die at the table.
struct RollerView: View {
    @StateObject private var model = PanelModel(store: SpecStore())
    @State private var history = RollHistory()
    @State private var showingGuide = false

    /// The result area takes up to 220pt but at most ~30% of the screen, so short screens keep room for history.
    private static let maxResultHeight: CGFloat = 220
    private static let resultShare: CGFloat = 0.3
    /// Below this result height (iPhone SE gets ~180pt) the total uses a smaller font so the card still fits.
    private static let compactBelowHeight: CGFloat = 200
    private static let compactTotalFontSize: CGFloat = 52

    private var latest: RollHistory.Entry? { history.entries.first }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let height = min(Self.maxResultHeight, geometry.size.height * Self.resultShare)
                VStack(spacing: 0) {
                    resultArea(compact: height < Self.compactBelowHeight)
                        .frame(height: height)
                    Divider()
                    historyList
                    Divider()
                    RollPanelView(model: model, onRoll: roll)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .navigationTitle("骰子")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("使用说明", systemImage: "questionmark.circle") { showingGuide = true }
                }
            }
            .sheet(isPresented: $showingGuide) { GuideView() }
            .sensoryFeedback(trigger: latest?.id) { _, _ in feedback(for: latest?.result) }
        }
    }

    @ViewBuilder
    private func resultArea(compact: Bool) -> some View {
        if let latest {
            ResultCard(spec: latest.spec, result: latest.result,
                       totalFontSize: compact ? Self.compactTotalFontSize : 72)
                // Keyed by the roll, not the total, so rolling the same number again still visibly reacts.
                .keyframeAnimator(initialValue: 1.0, trigger: latest.id) { card, scale in
                    card.scaleEffect(scale)
                } keyframes: { _ in
                    CubicKeyframe(1.06, duration: 0.08)
                    CubicKeyframe(1.0, duration: 0.18)
                }
        } else {
            Text("选好骰子，点「投掷」")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var historyList: some View {
        List {
            Section("最近") {
                ForEach(history.entries) { entry in
                    HistoryRow(entry: entry)
                }
            }
        }
        .listStyle(.plain)
    }

    private func roll() {
        let rolled = model.roll()
        withAnimation {
            history.add(spec: rolled.spec, result: rolled.result)
        }
    }

    private func feedback(for result: RollResult?) -> SensoryFeedback? {
        guard let result else { return nil }
        switch result.critical {
        case .success: return .success
        case .failure: return .error
        case .none: return .impact(weight: .light)
        }
    }
}

private struct HistoryRow: View {
    let entry: RollHistory.Entry

    var body: some View {
        HStack(spacing: 8) {
            Text(entry.date, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            Text(RollFormatter.formula(entry.spec))
                .lineLimit(1)
            Spacer()
            Text(verbatim: String(entry.result.total))
                .font(.headline.monospacedDigit())
                .foregroundStyle(entry.result.totalColor)
            if let outcome = RollFormatter.outcome(entry.result) {
                Text(outcome)
                    .font(.caption)
                    .foregroundStyle(entry.result.outcomeColor)
            }
        }
    }
}

#Preview { RollerView() }
