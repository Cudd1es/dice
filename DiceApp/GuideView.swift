import SwiftUI

/// How to use the app and the iMessage extension; opened from the roller's toolbar.
struct GuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("在本页设好骰子，点「投掷」，结果显示在上方；最近 10 次记录关掉 App 后清空", systemImage: "dice")
                } header: {
                    Text("在 App 里投骰")
                }
                Section("在「信息」里使用") {
                    Label("打开「信息」，进入一个对话", systemImage: "message")
                    Label("点输入框左侧的 +，在 App 列表里选「骰子」", systemImage: "plus.circle")
                    Label("设置骰子后点「投掷」，消息会放进输入框", systemImage: "dice")
                    Label("想说明这次投的是什么（比如「攻击哥布林」），在输入框里写上再发送", systemImage: "text.bubble")
                    Label("点发送后，气泡上直接显示结果，大家看到的都一样", systemImage: "paperplane")
                }
                Section {
                    Text("结果在点「投掷」时就已确定，发送前谁都看不到，删掉重投也不会更好。")
                        .foregroundStyle(.secondary)
                    Text("群里每个人都要安装「骰子」才能看到结果；没装的人只会看到公式和安装提示。")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("使用说明")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

#Preview { GuideView() }
