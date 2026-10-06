import SwiftUI

@main
struct DiceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// The host app only explains where the iMessage extension lives.
struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("使用方法") {
                    Label("打开「信息」，进入一个对话", systemImage: "message")
                    Label("点输入框左侧的 +，在 App 列表里选「骰子」", systemImage: "plus.circle")
                    Label("设置骰子后点「投掷」，消息会放进输入框", systemImage: "dice")
                    Label("点发送；大家点开消息即可看到结果", systemImage: "paperplane")
                }
                Section {
                    Text("结果在点「投掷」时就已确定，发送前谁都看不到，删掉重投也不会更好。")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("骰子")
        }
    }
}

#Preview { ContentView() }
