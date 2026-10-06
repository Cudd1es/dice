# Spike：Live Layout 的 pending/sent 行为

日期：2026-10-05
环境：Xcode 26.2 (17C52, iOS 26.2 SDK)，iPhone 17 Pro 模拟器，运行时 iOS 26.3.1 (23D8133)；最低部署目标 iOS 17

## 做法

最小扩展（代码在 `spike/`，未提交）：compact 时一个 INSERT 按钮，插入
`MSMessageLiveLayout(alternateLayout: template "ALT")`；transcript 时显示
`selectedMessage?.isPending == true ? "PENDING" : "SENT"`，并在所有生命周期回调里
用 `os_log` 记录 `activeConversation` 是否为空、`selectedMessage`、`isPending` 与 VC 地址。
随后又做了两轮变体：改用 `MSMessageTemplateLayout`，以及把 URL 从 `dice://` 改成 `https://`。

## 观察

1. **草稿气泡由扩展渲染**（显示的是扩展的 UILabel，不是 "ALT"）。但该 transcript 实例
   只收到 `viewWillAppear` / `viewDidAppear`，**从不收到 `willBecomeActive(with:)`**，
   `activeConversation` 始终为 `nil`（1 秒后再查也是）。扩展无法得知自己渲染的是哪条消息，
   既拿不到 `url` 也拿不到 `isPending`，所以显示了 "SENT"。→ **不成立**
2. 点发送后，Messages **新建了一个 transcript VC 实例**来重绘发送方气泡（日志里出现新地址），
   但新实例同样 `activeConversation == nil`，同样无法读取消息。→ **不成立**
3. 模拟器「信息」里 KB 与 JA 是**两个互相独立的会话**：发给 KB 的消息不会出现在 JA 中；
   重启「信息」后历史也不保留。**模拟器无法验证接收方视角。** → **无法验证（按不成立处理）**
4. Template layout 下点开**已发送**气泡：触发 `didSelect`，`selectedMessage` 就是该消息，
   `isPending == false`，随后 `didTransition` 到 `.expanded`。→ **成立**（变体 B 的前提）
   - 点**草稿中**的气泡：没有任何回调，扩展不会展开。
   - **自定义 scheme 会被丢弃**：`url = dice://roll?...` 时，`didSelect` 拿到的消息 `url == nil`；
     改为 `https://dice.invalid/roll?...` 后 url 完整保留。

## 对计划的影响

- 第 1–3 项不成立 → 按计划切换到变体 B：气泡固定为 template layout
  （caption = 公式，subcaption = 「点开查看结果」），结果只在点开已发送消息后的 expanded 视图中显示。
- 消息 URL 必须用 `https`：`MessageCodec` 生成 `https://dice.invalid/roll?v=1&...`
  （`.invalid` 是保留顶级域，永远不会解析到真实主机）。
- 规格第 1 节成功标准 2（"发送后双方气泡自动显示结果，无需点击"）在变体 B 下变为"点开即见"；
  接收方视角与群聊均推迟到有真机后验证。

Decision: B
