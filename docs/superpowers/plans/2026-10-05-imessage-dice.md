# iMessage 骰子扩展 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 一个 iMessage 扩展：按钮面板投 DnD 骰子，结果在插入草稿时锁定但不显示，发送后双方气泡直接显示结果。

**Architecture:** 所有规则、编解码、文案放在纯 Swift 包 `DiceKit`（可在任何 Swift 工具链上 `swift test`）；iMessage 扩展只做 UI 与 Messages 框架胶水。气泡用 `MSMessageLiveLayout`，依据 `MSMessage.isPending` 决定显示公式还是结果；spike 失败时降级为 template layout + 点开查看（变体 B）。

**Tech Stack:** Swift 5.9+、SwiftUI、Messages framework、XCTest、XcodeGen（生成 `.xcodeproj`）、iOS 17+ 模拟器。

**Spec:** `docs/superpowers/specs/2026-10-05-imessage-dice-design.md`

## Global Constraints

- 最低系统：iOS 17；`DiceKit` 同时声明 macOS 14，并且只能用 Swift 标准库 + Foundation（保证 Linux 上也能 `swift test`）
- 代码和注释用英文；面向用户的文案用中文，文案以本计划 Task 5 为准
- 面数 `[4, 6, 8, 10, 12, 20, 100]`；数量 `1...20`；加值 `-20...20`；DC `1...40`
- 优势/劣势、大成功/大失败只在 `count == 1 && sides == 20` 时生效
- DC：`total >= dc` 成功；天然 20 必定成功，天然 1 必定失败
- 面板、草稿、`summaryText`、`alternateLayout` 中**绝不出现结果**
- 消息 URL 带版本号 `v=1`
- 仅模拟器测试；群聊验收推迟到有真机
- Bundle ID 前缀：`dev.ansel.dice`

## Review Focus

1. **草稿还在时重新打开面板** → 面板只显示上次的公式，不能出现上次的结果（Task 8 `test_specStore_persistsSpecOnly`、Task 6 `test_resolve_expandedPendingShowsPanel`）
2. **选了优势后把 d20 改成 d6 或数量改成 2** → 模式自动回到普通，不能投出非法组合（Task 2 `test_normalized_resetsModeWhenNotSingleD20`、Task 8 `test_panel_changingSidesResetsMode`）
3. **点开草稿里（pending）的气泡** → 显示面板，不显示结果详情（Task 6 `test_resolve_expandedPendingShowsPanel`）
4. **20d100 这种很长的明细** → 气泡自动换行、不截断（Task 5 `test_detail_twentyDice`、Task 7 预览 `twentyD100`）
5. **加值为 0 或负数** → 公式写成 `2d6`、`1d8-2`，明细写成 `= 7`、`- 2 = 5`，不出现 `+0` 或 `+-2`（Task 5 测试）

---

## File Structure

```
dice/
├─ .gitignore                         spike/, *.xcodeproj, DerivedData, .build
├─ project.yml                        XcodeGen 定义（Task 6）
├─ DiceKit/
│  ├─ Package.swift
│  ├─ Sources/DiceKit/
│  │  ├─ RollSpec.swift               RollSpec, RollMode, RollSpecError
│  │  ├─ RollResult.swift             RollResult, Critical, DCOutcome
│  │  ├─ DiceEngine.swift             roll / evaluate
│  │  ├─ SplitMix64.swift             可种子化 RNG
│  │  ├─ MessageCodec.swift           URL 编解码, CodecError
│  │  └─ RollFormatter.swift          中文文案
│  └─ Tests/DiceKitTests/             每个源文件一个 *Tests.swift
├─ DiceApp/                           宿主 App（Task 9）
├─ DiceMessages/
│  ├─ Info.plist
│  ├─ MessagesViewController.swift    生命周期 + 托管 SwiftUI
│  ├─ Screen.swift                    纯函数路由 Screen.resolve
│  ├─ MessageFactory.swift            组装 MSMessage
│  ├─ BubbleView.swift                pending / revealed / detail / invalid
│  ├─ RollPanelView.swift             面板 UI
│  ├─ PanelModel.swift                面板状态与规则
│  └─ SpecStore.swift                 UserDefaults 保存上次公式
└─ DiceMessagesTests/                 Screen / MessageFactory / PanelModel / SpecStore 测试
```

**运行环境说明：** Task 2–5 只需 Swift 工具链（Mac 或 Linux 均可）。Task 1、6–9 需要在 Mac 上用 Xcode 16+ 与 iOS 17+ 模拟器；XcodeGen 用 `brew install xcodegen` 安装。下文 `$SIM` 指 `-destination 'platform=iOS Simulator,name=iPhone 16'`（按本机已有模拟器调整）。

---

### Task 1: Spike — 验证 Live Layout 的 pending/sent 行为（代码不保留）

**Files:**
- Create（不提交）：`spike/`（XcodeGen 最小工程：一个 App + 一个 iMessage 扩展）
- Create（提交）：`docs/superpowers/spikes/2026-10-05-live-layout.md`
- Modify：`.gitignore`（加入 `spike/`）

**Interfaces:** 无。产出是一个结论：**A 成立** 或 **切换到变体 B**。

- [ ] **Step 1:** 在 `spike/` 建最小扩展。`MessagesViewController`：compact 时一个按钮，点击后 `activeConversation?.insert(msg)`，其中 `msg.url = "dice://roll?t=<当前时间戳>"`，`msg.layout = MSMessageLiveLayout(alternateLayout: MSMessageTemplateLayout(caption: "ALT"))`；transcript 时显示一个 `UILabel`，文字为 `activeConversation?.selectedMessage?.isPending == true ? "PENDING" : "SENT"`，并 `os_log` 打印每次 `willBecomeActive`/`didTransition`/`viewWillAppear` 时的 `isPending` 和 VC 实例地址；覆盖 `contentSizeThatFits(_:)` 返回 `CGSize(width: size.width, height: 80)`
- [ ] **Step 2:** 用 Xcode 运行扩展 scheme，宿主选 Messages，在模拟器「信息」里逐项观察并记录：
  1. 插入后草稿气泡是否由扩展渲染、显示 `PENDING`（而不是 `ALT`）
  2. 点发送后，发送方气泡是否**无需任何操作**变为 `SENT`（日志里是否出现新的 VC 实例或新的生命周期回调）
  3. 切换到模拟器中另一方的会话，接收方气泡是否显示 `SENT`
  4. 点开已发送气泡时，expanded 模式下 `selectedMessage` 是否就是该消息
- [ ] **Step 3:** 把观察结果、Xcode 版本、模拟器 iOS 版本写入 `docs/superpowers/spikes/2026-10-05-live-layout.md`，结论一行：`Decision: A` 或 `Decision: B`（1–3 任一不成立即为 B）
- [ ] **Step 4:** 提交

```bash
git add .gitignore docs/superpowers/spikes/2026-10-05-live-layout.md
git commit -m "docs: record live layout spike results"
```

---

### Task 2: DiceKit 包 + RollSpec

**Files:**
- Create：`DiceKit/Package.swift`、`DiceKit/Sources/DiceKit/RollSpec.swift`、`DiceKit/Tests/DiceKitTests/RollSpecTests.swift`、`.gitignore`（若 Task 1 尚未创建）

**Interfaces:**
- Produces:
```swift
public enum RollMode: String, Codable, CaseIterable, Sendable { case normal, advantage, disadvantage }
public enum RollSpecError: Error, Equatable { case invalidSides(Int), invalidCount(Int), invalidModifier(Int), invalidDC(Int), modeRequiresSingleD20 }
public struct RollSpec: Codable, Equatable, Sendable {
    public static let allowedSides: [Int]      // [4, 6, 8, 10, 12, 20, 100]
    public static let countRange: ClosedRange<Int>     // 1...20
    public static let modifierRange: ClosedRange<Int>  // -20...20
    public static let dcRange: ClosedRange<Int>        // 1...40
    public var count: Int, sides: Int, mode: RollMode, modifier: Int, dc: Int?
    public init(count: Int = 1, sides: Int = 20, mode: RollMode = .normal, modifier: Int = 0, dc: Int? = nil)
    public var isSingleD20: Bool { get }         // count == 1 && sides == 20
    public var diceToRoll: Int { get }           // mode == .normal ? count : 2
    public func validate() throws                // throws RollSpecError, checks in field order above
    public func normalized() -> RollSpec         // mode = .normal when !isSingleD20
}
```

- [ ] **Step 1:** `Package.swift`：`swift-tools-version:5.9`，库 `DiceKit`，platforms `.iOS(.v17), .macOS(.v14)`，测试目标 `DiceKitTests`
- [ ] **Step 2: 写失败测试** `RollSpecTests`：
  - `test_validate_acceptsDefault`：`RollSpec()` 不抛错
  - `test_validate_rejectsBadSides`：`sides: 7` → `.invalidSides(7)`
  - `test_validate_rejectsCountBounds`：`count: 0` → `.invalidCount(0)`，`count: 21` → `.invalidCount(21)`
  - `test_validate_rejectsModifierBounds`：`-21`、`21`
  - `test_validate_rejectsDCBounds`：`0`、`41`；`dc: nil` 合法
  - `test_validate_rejectsAdvantageOnNonD20`：`RollSpec(count: 2, sides: 20, mode: .advantage)` → `.modeRequiresSingleD20`
  - `test_normalized_resetsModeWhenNotSingleD20`：`RollSpec(sides: 6, mode: .advantage).normalized().mode == .normal`；1d20 优势保持不变
  - `test_diceToRoll`：普通 `3d6` → 3；1d20 劣势 → 2
- [ ] **Step 3:** 运行 `cd DiceKit && swift test --filter RollSpecTests`，预期编译失败
- [ ] **Step 4:** 实现 `RollSpec.swift`
- [ ] **Step 5:** 再次运行，预期 PASS
- [ ] **Step 6:** 提交 `feat(dicekit): add RollSpec with validation`

---

### Task 3: DiceEngine + RollResult + SplitMix64

**Files:**
- Create：`DiceKit/Sources/DiceKit/{RollResult,DiceEngine,SplitMix64}.swift`、`DiceKit/Tests/DiceKitTests/DiceEngineTests.swift`

**Interfaces:**
- Consumes：Task 2 的 `RollSpec`
- Produces:
```swift
public enum Critical: String, Codable, Sendable { case none, success, failure }
public enum DCOutcome: String, Codable, Sendable { case success, failure }
public struct RollResult: Codable, Equatable, Sendable {
    public let dice: [Int]          // every die rolled, in roll order
    public let keptIndices: [Int]   // indices into `dice` that count toward total
    public let total: Int
    public let critical: Critical
    public let dcOutcome: DCOutcome?
}
public struct SplitMix64: RandomNumberGenerator { public init(seed: UInt64) }
public enum DiceEngine {
    public static func roll<G: RandomNumberGenerator>(_ spec: RollSpec, using rng: inout G) -> RollResult
    public static func evaluate(_ spec: RollSpec, dice: [Int]) -> RollResult
}
```
`roll` 前置条件：`spec` 已通过 `validate()`（`precondition`）。`roll` 只负责用 `Int.random(in: 1...spec.sides, using: &rng)` 掷出 `spec.diceToRoll` 颗，再交给 `evaluate`。`evaluate` 是纯函数，Task 4 解码时复用它重算结果。

`evaluate` 规则：普通 → 全部保留；优势 → 保留最大值的下标，劣势 → 最小值的下标，**相等时保留下标 0**。`total` = 保留骰子之和 + `modifier`。`critical` 仅在 `isSingleD20` 时看保留的那颗（20 → `.success`，1 → `.failure`）。`dcOutcome`：`dc == nil` → `nil`；`critical == .success` → `.success`；`.failure` → `.failure`；否则 `total >= dc`。

- [ ] **Step 1: 写失败测试** `DiceEngineTests`：
  - `test_roll_isDeterministicWithSeed`：同一 `SplitMix64(seed: 42)` 掷 `4d6` 两次结果相等
  - `test_roll_rangeAndUniformity`：对每个允许面数，用 `SplitMix64(seed: 1)` 掷 100,000 次 `1dN`，所有值在 `1...N`，每个点数出现次数在期望值 ±10% 内
  - `test_evaluate_normalSum`：`2d6+3`，dice `[2, 5]` → kept `[0, 1]`、total 10、critical `.none`
  - `test_evaluate_advantageKeepsHigher`：1d20+5 优势，`[8, 17]` → kept `[1]`、total 22
  - `test_evaluate_disadvantageKeepsLower`：`[8, 17]` → kept `[0]`、total 8+mod
  - `test_evaluate_tieKeepsFirst`：优势 `[9, 9]` → kept `[0]`
  - `test_evaluate_criticalOnlyForSingleD20`：1d20 `[20]` → `.success`；`[1]` → `.failure`；优势 `[1, 20]` → `.success`；劣势 `[1, 20]` → `.failure`；`3d20` `[20, 20, 20]` → `.none`
  - `test_evaluate_dcBoundaryAndNaturals`：1d20+0 DC 10 `[10]` → `.success`；`[9]` → `.failure`；1d20+0 DC 25 `[20]` → `.success`；1d20+10 DC 5 `[1]` → `.failure`；`2d6` DC 7 `[3, 4]` → `.success`；无 DC → `nil`
- [ ] **Step 2:** `swift test --filter DiceEngineTests`，预期失败
- [ ] **Step 3:** 实现 `SplitMix64`（标准算法：`state &+= 0x9E3779B97F4A7C15`，再做两轮 xor-shift 乘法 `0xBF58476D1CE4E5B9`、`0x94D049BB133111EB`）、`RollResult`、`DiceEngine`
- [ ] **Step 4:** 再次运行，预期 PASS
- [ ] **Step 5:** 提交 `feat(dicekit): add dice engine`

---

### Task 4: MessageCodec

**Files:**
- Create：`DiceKit/Sources/DiceKit/MessageCodec.swift`、`DiceKit/Tests/DiceKitTests/MessageCodecTests.swift`

**Interfaces:**
- Consumes：`RollSpec`、`RollResult`、`DiceEngine.evaluate`
- Produces:
```swift
public enum CodecError: Error, Equatable {
    case missingField(String)
    case unsupportedVersion(Int)
    case malformed(String)          // field name whose value failed to parse
    case invalidSpec(RollSpecError)
    case invalidDice
}
public enum MessageCodec {
    public static let currentVersion: Int   // 1
    public static func url(for spec: RollSpec, result: RollResult) -> URL
    public static func decode(_ url: URL) throws -> (spec: RollSpec, result: RollResult)
}
```
URL 形如 `dice://roll?v=1&n=1&s=20&m=a&k=5&dc=15&d=8,17`。键：`v` 版本、`n` 数量、`s` 面数、`m` 模式（`n`/`a`/`d`）、`k` 加值、`dc` 可选、`d` 逗号分隔的全部骰子。**不存 total**：解码时用 `evaluate` 重算，这样"total 与明细不一致"在结构上不可能发生（实现规格第 8 节的同等保证）。

解码顺序：`v` 缺失 → `missingField("v")`；`v != 1` → `unsupportedVersion(v)`；其余字段缺失/无法解析 → `missingField`/`malformed`；`spec.validate()` 失败 → `invalidSpec`；骰子数量 `!= spec.diceToRoll` 或任一值不在 `1...sides` → `invalidDice`。

- [ ] **Step 1: 写失败测试** `MessageCodecTests`：
  - `test_roundTrip`：至少 3 组（`1d20+5 优势 DC15`、`2d6-2`、`20d100`）编码后解码，spec 与 result 都相等
  - `test_url_containsVersion`：`URLComponents` 里 `v == "1"`
  - `test_decode_missingVersion` / `test_decode_futureVersion`（`v=2` → `.unsupportedVersion(2)`）
  - `test_decode_malformedNumber`：`n=abc` → `.malformed("n")`
  - `test_decode_outOfRangeSpec`：`s=7` → `.invalidSpec(.invalidSides(7))`
  - `test_decode_wrongDiceCount`：1d20 优势但 `d=12` → `.invalidDice`
  - `test_decode_dieOutOfRange`：`s=6&d=7` → `.invalidDice`
- [ ] **Step 2:** `swift test --filter MessageCodecTests`，预期失败
- [ ] **Step 3:** 用 `URLComponents`/`URLQueryItem` 实现
- [ ] **Step 4:** 再次运行，预期 PASS
- [ ] **Step 5:** 提交 `feat(dicekit): add message codec`

---

### Task 5: RollFormatter（中文文案）

**Files:**
- Create：`DiceKit/Sources/DiceKit/RollFormatter.swift`、`DiceKit/Tests/DiceKitTests/RollFormatterTests.swift`

**Interfaces:**
- Produces:
```swift
public enum RollFormatter {
    public static let pendingCaption: String     // "发送后揭晓"
    public static let tapToRevealCaption: String // "点开查看结果"
    public static let needsUpdateText: String    // "无法读取这次投骰，请更新 App"
    public static let corruptText: String        // "数据无效"
    public static func formula(_ spec: RollSpec) -> String
    public static func summary(_ spec: RollSpec) -> String          // "🎲 " + formula
    public static func detailMarkdown(_ spec: RollSpec, _ result: RollResult) -> String
    public static func outcome(_ result: RollResult) -> String?
}
```
- `formula`：`"{count}d{sides}"` + 加值（`+5` / `-2`，0 时省略）+ 优势 `" · 优势"` / 劣势 `" · 劣势"` + DC `" · DC 15"`
- `detailMarkdown`：`"[" + 骰子用 ", " 连接，未保留的写成 ~~v~~ + "]"` + 加值（`" + 5"` / `" - 2"`，0 时省略）+ `" = {total}"`。供 SwiftUI `AttributedString(markdown:)` 渲染删除线
- `outcome`：`critical == .success` → `"大成功"`；`.failure` → `"大失败"`；否则 `dcOutcome` → `"成功"` / `"失败"`；都没有 → `nil`

- [ ] **Step 1: 写失败测试** `RollFormatterTests`：
  - `test_formula`：`1d20+5 · 优势 · DC 15`、`2d6`、`1d8-2`、`1d20 · 劣势`
  - `test_summary`：`"🎲 1d20+5 · 优势 · DC 15"`
  - `test_detail`：优势 `[17, 8]` 保留下标 0、+5 → `"[17, ~~8~~] + 5 = 22"`；`2d6-2` `[3, 4]` → `"[3, 4] - 2 = 5"`；`1d6` `[7]`… 改为 `[6]` → `"[6] = 6"`
  - `test_detail_twentyDice`：20d100 输出包含 20 个数字、以 `" = {total}"` 结尾
  - `test_outcome`：大成功 / 大失败 / 成功 / 失败 / `nil`；大成功且有 DC 时返回 `"大成功"`
  - `test_summary_neverContainsResult`：对任意 result，`summary(spec)` 与 result 无关（只接收 spec，编译期即保证；此测试断言 `summary` 不包含 `"="`）
- [ ] **Step 2:** `swift test --filter RollFormatterTests`，预期失败
- [ ] **Step 3:** 实现
- [ ] **Step 4:** `swift test`（全部），预期 PASS
- [ ] **Step 5:** 提交 `feat(dicekit): add Chinese formatter`

---

### Task 6: Xcode 工程 + Screen 路由 + MessageFactory

**Files:**
- Create：`project.yml`、`DiceApp/DiceApp.swift`（占位 `ContentView`，Task 9 完善）、`DiceMessages/Info.plist`、`DiceMessages/MessagesViewController.swift`（空壳，Task 7 填充）、`DiceMessages/Screen.swift`、`DiceMessages/MessageFactory.swift`、`DiceMessagesTests/ScreenTests.swift`、`DiceMessagesTests/MessageFactoryTests.swift`

**Interfaces:**
- Consumes：`DiceKit` 全部公开 API
- Produces:
```swift
enum InvalidReason: Equatable { case needsUpdate, corrupt }
enum Screen: Equatable {
    case panel
    case pendingBubble(RollSpec)
    case revealedBubble(RollSpec, RollResult)
    case detail(RollSpec, RollResult)
    case invalid(InvalidReason)
    static func resolve(style: MSMessagesAppPresentationStyle, messageURL: URL?, isPending: Bool) -> Screen
}
enum MessageFactory {
    static func makeMessage(spec: RollSpec, result: RollResult, session: MSSession?) -> MSMessage
}
```

`project.yml` 要点：`DiceApp`（application，iOS 17，嵌入 `DiceMessages`）；`DiceMessages`（app-extension，`NSExtensionPointIdentifier = com.apple.message-payload-provider`，`NSExtensionPrincipalClass = $(PRODUCT_MODULE_NAME).MessagesViewController`）；`DiceMessagesTests`（bundle.unit-test，host 为 `DiceApp`，sources 包含 `DiceMessages/Screen.swift`、`DiceMessages/MessageFactory.swift` 与后续 Task 8 的 `PanelModel.swift`、`SpecStore.swift`）；三者都依赖本地包 `DiceKit`。`.xcodeproj` 不提交，用 `xcodegen generate` 生成。

`Screen.resolve` 规则：
- `.transcript`：URL 为空或解码失败 → `.invalid`（`unsupportedVersion(v)` 且 `v > currentVersion` → `.needsUpdate`，其余 → `.corrupt`）；`isPending` → `.pendingBubble`；否则 `.revealedBubble`
- `.compact` / `.expanded`：URL 为空或 `isPending` → `.panel`；解码失败 → `.invalid`；否则 `.detail`

`MessageFactory`：`url = MessageCodec.url(...)`；`summaryText = RollFormatter.summary(spec)`；template = caption `formula(spec)`、subcaption `tapToRevealCaption`；**变体 A** `layout = MSMessageLiveLayout(alternateLayout: template)`，**变体 B** `layout = template`。

- [ ] **Step 1:** 写 `project.yml` 和空壳文件，运行 `xcodegen generate && xcodebuild build -project Dice.xcodeproj -scheme DiceApp $SIM`，预期 `BUILD SUCCEEDED`
- [ ] **Step 2: 写失败测试** `ScreenTests`：`test_resolve_transcriptPending`、`test_resolve_transcriptSent`、`test_resolve_transcriptFutureVersionNeedsUpdate`、`test_resolve_transcriptGarbageIsCorrupt`、`test_resolve_compactNoMessageShowsPanel`、`test_resolve_expandedPendingShowsPanel`、`test_resolve_expandedSentShowsDetail`；`MessageFactoryTests`：`test_message_urlDecodesBack`、`test_message_summaryHasNoResult`（等于 `summary(spec)`）、`test_message_alternateLayoutHasNoResult`（caption/subcaption 不含 `String(result.total)` 以外…直接断言等于 `formula` 与 `tapToRevealCaption`）、`test_message_layoutMatchesSpikeDecision`
- [ ] **Step 3:** `xcodebuild test -project Dice.xcodeproj -scheme DiceApp $SIM -only-testing:DiceMessagesTests`，预期失败
- [ ] **Step 4:** 实现 `Screen.swift`、`MessageFactory.swift`（按 Task 1 的 Decision 选 A/B）
- [ ] **Step 5:** 再次运行，预期 PASS
- [ ] **Step 6:** 提交 `feat(messages): add project, screen routing, message factory`

---

### Task 7: BubbleView + MessagesViewController 托管

**Files:**
- Create：`DiceMessages/BubbleView.swift`
- Modify：`DiceMessages/MessagesViewController.swift`

**Interfaces:**
- Consumes：`Screen`、`RollFormatter`
- Produces：
```swift
struct BubbleView: View { let screen: Screen }   // renders .pendingBubble / .revealedBubble / .detail / .invalid
final class MessagesViewController: MSMessagesAppViewController  // hosts RootView(screen:)
```

- `BubbleView`：pending → 🎲 + `formula` + `pendingCaption`；revealed → 大字 `total`、`detailMarkdown`（`Text(AttributedString(markdown:))`，允许多行换行）、`outcome`；大成功用 `.yellow`/金色，大失败用 `.red`；detail 与 revealed 同内容但字号更大、额外显示 `formula`；invalid → 对应文案。颜色用系统语义色，深色模式可读
- `MessagesViewController`：一个 `UIHostingController<RootView>` 子控制器；在 `willBecomeActive(with:)`、`didTransition(to:)`、`didSelect(_:conversation:)`、`didReceive(_:conversation:)` 中调用私有 `refresh()`：取 `activeConversation?.selectedMessage`，算 `Screen.resolve(style: presentationStyle, messageURL: msg?.url, isPending: msg?.isPending ?? false)`，更新 `RootView`。`RootView` 在 `.panel` 时显示 `RollPanelView`（Task 8 前用 `Text("panel")` 占位），其余显示 `BubbleView`
- 覆盖 `contentSizeThatFits(_ size: CGSize) -> CGSize`：用 hosting controller 的 `sizeThatFits(in: CGSize(width: size.width, height: .greatestFiniteMagnitude))`
- 若 Task 1 观察到发送后需要特定回调才刷新，在对应回调里调用 `refresh()`（以 spike 文档为准）

- [ ] **Step 1:** 实现 `BubbleView`，附 `#Preview`：`pending`、`normal`（2d6+3）、`critSuccess`、`critFailure`、`dcSuccess`、`dcFailure`、`twentyD100`、`needsUpdate`、`corrupt`，各一份浅色与深色
- [ ] **Step 2:** 在 Xcode Canvas 逐个检查预览：20d100 换行不截断、深色模式文字可读
- [ ] **Step 3:** 实现 `MessagesViewController` 托管与 `refresh()`，`xcodebuild build ... -scheme DiceApp $SIM` 预期成功
- [ ] **Step 4:** 提交 `feat(messages): add bubble view and controller hosting`

---

### Task 8: 投骰面板 + 插入草稿

**Files:**
- Create：`DiceMessages/PanelModel.swift`、`DiceMessages/SpecStore.swift`、`DiceMessages/RollPanelView.swift`、`DiceMessagesTests/PanelModelTests.swift`、`DiceMessagesTests/SpecStoreTests.swift`
- Modify：`DiceMessages/MessagesViewController.swift`（`.panel` 换成 `RollPanelView`，注入 roll 回调）

**Interfaces:**
- Consumes：`RollSpec`、`DiceEngine`、`MessageFactory`
- Produces：
```swift
struct SpecStore {
    init(defaults: UserDefaults = .standard)
    func load() -> RollSpec            // falls back to RollSpec() on missing/invalid data
    func save(_ spec: RollSpec)        // key "lastRollSpec", JSON-encoded RollSpec only
}
@MainActor final class PanelModel: ObservableObject {
    @Published private(set) var spec: RollSpec
    @Published var errorMessage: String?
    init(store: SpecStore)
    var isModeEnabled: Bool { get }    // spec.isSingleD20
    func selectSides(_ sides: Int)
    func changeCount(by delta: Int)    // clamps to countRange
    func changeModifier(by delta: Int) // clamps to modifierRange
    func setMode(_ mode: RollMode)     // ignored when !isModeEnabled
    func setDC(_ dc: Int?)             // clamps to dcRange
    func makeRoll() -> MSMessage       // rolls with SystemRandomNumberGenerator, saves spec, returns MessageFactory.makeMessage(session: nil)
}
```
每个修改方法结束时 `spec = spec.normalized()`。`RollPanelView` 只读 `model.spec` 与 `formula`，**不持有、不显示任何 `RollResult`**。插入：`activeConversation?.insert(model.makeRoll()) { error in ... }`，成功 → `dismiss()`；失败 → `errorMessage = "插入失败，请重试"`。

- [ ] **Step 1: 写失败测试** `SpecStoreTests`：`test_specStore_roundTrip`、`test_specStore_fallsBackToDefault`（写入垃圾数据）、`test_specStore_persistsSpecOnly`（读出原始 JSON，键集合 ⊆ `{count, sides, mode, modifier, dc}`）；测试用 `UserDefaults(suiteName: UUID().uuidString)`
- [ ] **Step 2: 写失败测试** `PanelModelTests`：`test_panel_loadsLastSpec`、`test_panel_clampsCount`（从 20 再 +1 仍是 20；从 1 再 -1 仍是 1）、`test_panel_clampsModifier`、`test_panel_changingSidesResetsMode`（1d20 优势 → 选 d6 → `.normal`）、`test_panel_modeIgnoredWhenDisabled`、`test_panel_makeRollSavesSpec`、`test_panel_makeRollMessageDecodes`（`MessageCodec.decode(msg.url!)` 的 spec 等于 `model.spec`）
- [ ] **Step 3:** `xcodebuild test ... -only-testing:DiceMessagesTests`，预期失败
- [ ] **Step 4:** 实现 `SpecStore`、`PanelModel`
- [ ] **Step 5:** 再次运行，预期 PASS
- [ ] **Step 6:** 实现 `RollPanelView`：行 1 面数按钮横向滚动；行 2 数量与加值 `− 值 +`；行 3 `劣势 | 普通 | 优势` 分段（`!isModeEnabled` 时 `.disabled`）与 DC `Toggle` + `Stepper`；公式预览；「投掷」按钮；`errorMessage` 非空时显示。接入 `MessagesViewController`
- [ ] **Step 7:** 构建并在模拟器「信息」里点一次投掷，草稿出现且面板收起
- [ ] **Step 8:** 提交 `feat(messages): add roll panel and draft insertion`

---

### Task 9: 宿主 App 说明页 + 模拟器验收

**Files:**
- Modify：`DiceApp/DiceApp.swift`（一页说明：打开「信息」→ App 抽屉 → 骰子）
- Create：`docs/superpowers/acceptance/2026-10-05-simulator.md`

**Interfaces:** 无新增。

- [ ] **Step 1:** 完成说明页，构建通过
- [ ] **Step 2:** 运行 `cd DiceKit && swift test` 与 `xcodebuild test ... -only-testing:DiceMessagesTests`，全部 PASS
- [ ] **Step 3:** 在模拟器「信息」逐项验收并在验收文档中打勾（记录 iOS 版本）：
  1. 1d20+5 优势 DC 15 → 面板与草稿中都看不到任何点数或成败
  2. 发送 → 发送方气泡自动显示总值、明细、成败
  3. 切换到另一方会话 → 接收方气泡显示同一结果
  4. 点已发送气泡 → 展开详情，与气泡一致
  5. 草稿未发送时再打开 App → 面板显示上次公式，无结果
  6. 草稿未发送时再投一次 → 仍看不到任何结果
  7. 1d20 优势后切到 d6 → 优势开关置灰并回到普通
  8. 20d100 → 气泡完整换行
  9. 深色模式下气泡可读
  10. 群聊：标记"待真机"
- [ ] **Step 4:** 提交 `docs: add simulator acceptance results`
