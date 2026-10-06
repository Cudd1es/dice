import SwiftUI
import DiceKit

/// Button panel for building a roll. Reads only the formula, never a result.
struct RollPanelView: View {
    @ObservedObject var model: PanelModel
    let onRoll: () -> Void

    private static let defaultDC = 10

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                sidesRow
                HStack {
                    stepper(title: "数量", value: "\(model.spec.count)") { model.changeCount(by: $0) }
                    Spacer()
                    stepper(title: "加值", value: modifierText) { model.changeModifier(by: $0) }
                }
                modeRow
                dcRow
                Text(RollFormatter.formula(model.spec))
                    .font(.headline.monospacedDigit())
                    .frame(maxWidth: .infinity)
                if let error = model.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                Button(action: onRoll) {
                    Text("投掷")
                        .font(.title3.weight(.bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
    }

    private var modifierText: String {
        model.spec.modifier > 0 ? "+\(model.spec.modifier)" : "\(model.spec.modifier)"
    }

    private var sidesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RollSpec.allowedSides, id: \.self) { sides in
                    let selected = model.spec.sides == sides
                    Button("d\(sides)") { model.selectSides(sides) }
                        .buttonStyle(.bordered)
                        .tint(selected ? .accentColor : .secondary)
                        .fontWeight(selected ? .bold : .regular)
                }
            }
        }
    }

    private func stepper(title: String, value: String, change: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 6) {
            Text(title).foregroundStyle(.secondary)
            Button { change(-1) } label: { Image(systemName: "minus") }
                .buttonStyle(.bordered)
            Text(value)
                .font(.body.monospacedDigit())
                .frame(minWidth: 32)
            Button { change(1) } label: { Image(systemName: "plus") }
                .buttonStyle(.bordered)
        }
    }

    private var modeRow: some View {
        Picker("模式", selection: Binding(get: { model.spec.mode }, set: { model.setMode($0) })) {
            Text("劣势").tag(RollMode.disadvantage)
            Text("普通").tag(RollMode.normal)
            Text("优势").tag(RollMode.advantage)
        }
        .pickerStyle(.segmented)
        .disabled(!model.isModeEnabled)
    }

    private var dcRow: some View {
        HStack {
            Toggle("DC", isOn: Binding(
                get: { model.spec.dc != nil },
                set: { model.setDC($0 ? Self.defaultDC : nil) }
            ))
            .fixedSize()
            if let dc = model.spec.dc {
                Stepper(value: Binding(get: { dc }, set: { model.setDC($0) }), in: RollSpec.dcRange) {
                    Text("\(dc)").font(.body.monospacedDigit())
                }
            }
            Spacer()
        }
    }
}
