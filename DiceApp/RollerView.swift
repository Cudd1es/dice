import SwiftUI
import DiceKit

/// Home screen: roll with the shared panel and see the result, like a physical die at the table.
struct RollerView: View {
    @StateObject private var model = PanelModel(store: SpecStore())
    @State private var history = RollHistory()
    @State private var showingGuide = false
    @State private var showingSettings = false

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
                    // Laid out first so it gets its full height; history takes what is left.
                    RollPanelView(model: model, onRoll: roll)
                        .layoutPriority(1)
                }
            }
            .navigationTitle("Dicide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") { showingSettings = true }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("How to Use", systemImage: "questionmark.circle") { showingGuide = true }
                }
            }
            .sheet(isPresented: $showingGuide) { GuideView() }
            // The formula line and the next roll follow the setting as soon as the page closes.
            .sheet(isPresented: $showingSettings, onDismiss: model.refreshSettings) { SettingsView() }
            // Beyond this the result card and panel no longer fit an iPhone screen.
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .sensoryFeedback(trigger: latest?.id) { _, _ in feedback(for: latest?.result) }
        }
    }

    @ViewBuilder
    private func resultArea(compact: Bool) -> some View {
        if let latest {
            ResultCard(spec: latest.spec, result: latest.result, purpose: latest.purpose,
                       totalFontSize: compact ? Self.compactTotalFontSize : 72)
                // Keyed by the roll, not the total, so rolling the same number again still visibly reacts.
                .keyframeAnimator(initialValue: 1.0, trigger: latest.id) { card, scale in
                    card.scaleEffect(scale)
                } keyframes: { _ in
                    CubicKeyframe(1.06, duration: 0.08)
                    CubicKeyframe(1.0, duration: 0.18)
                }
        } else {
            Text("Pick your dice, then tap Roll")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var historyList: some View {
        List {
            Section("Recent") {
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
            history.add(spec: rolled.spec, result: rolled.result, purpose: rolled.purpose)
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
        VStack(alignment: .leading, spacing: 2) {
            row
            if let purpose = entry.purpose {
                Text(purpose)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(RollFormatter.clockTime(entry.date) + ". "
                            + RollFormatter.spokenResult(entry.spec, entry.result, purpose: entry.purpose))
    }

    private var row: some View {
        HStack(spacing: 8) {
            Text(RollFormatter.clockTime(entry.date))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            // Wraps rather than truncating: with advantage, a DC and "No crits" one line is too short.
            Text(RollFormatter.formula(entry.spec))
                .lineLimit(2)
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
