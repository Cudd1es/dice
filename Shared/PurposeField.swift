import SwiftUI
import DiceKit

/// Optional purpose line at the top of the panel, filled like the panel's buttons rather than the system's bordered
/// style. Shows a clear button once there is text and a counter near the limit.
struct PurposeField: View {
    @ObservedObject var model: PanelModel
    var focus: FocusState<PanelField?>.Binding

    /// The counter appears only near the limit, so the field stays clean otherwise.
    private static let counterFrom = 30

    private var isOverLimit: Bool { model.purpose.count > RollPurpose.maxLength }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "pencil")
                .foregroundStyle(.secondary)
            // Not cut while typing: rewriting the text mid-composition broke pinyin input. The counter turns red past
            // the limit and rolling cuts the purpose to it (RollPurpose.normalize).
            TextField("Purpose (optional), e.g. Perception check", text: $model.purpose)
                .submitLabel(.done)
                .focused(focus, equals: .purpose)
            if model.purpose.count > Self.counterFrom {
                Text(verbatim: "\(model.purpose.count)/\(RollPurpose.maxLength)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(isOverLimit ? .red : .secondary)
            }
            if !model.purpose.isEmpty {
                Button {
                    model.purpose = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear purpose")
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 40)
        .background(Color(.tertiarySystemFill), in: Capsule())
        .overlay {
            Capsule().strokeBorder(Color.accentColor.opacity(focus.wrappedValue == .purpose ? 0.6 : 0), lineWidth: 1.5)
        }
        .contentShape(Capsule())
        .onTapGesture { focus.wrappedValue = .purpose }
        .animation(.easeOut(duration: 0.15), value: focus.wrappedValue)
    }
}
