# 投骰目的 + DC 上限 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** 投掷前可填一句可选的目的，随骰子显示在 iMessage 气泡、结果详情与 App 记录里；DC 上限提到 999 并可直接输入数字。

**Architecture:** 目的是独立于 `RollSpec` 的可选字符串：`DiceKit` 的 `RollPurpose` 负责整理，`MessageCodec` 用可选查询字段 `p` 携带（版本仍为 1），`RollHistory` 记录它。`PanelModel` 持有输入框文字，`roll()` 返回整理后的目的并清空。扩展在输入框获得焦点时切到展开样式，`RevealState` 忽略这次展开，避免跳到结果详情。

**Tech Stack:** Swift 5.9+、SwiftUI（iOS 17）、Messages、XCTest、XcodeGen。

**Spec:** `docs/superpowers/specs/2026-10-06-roll-purpose-design.md`

**状态（2026-10-06）：** 4 个任务全部完成，整体审查后修复 3 个重要问题；以 0.3.0 发布，0.3.1、0.3.2 跟进修复，已合并到 `main`（PR #9）。偏离见规格"实施记录"。

## Global Constraints

- 最低 iOS 17；`DiceKit` 只用标准库 + Foundation
- 代码与注释用英文；界面文案英文为源，`Shared/Localizable.xcstrings` 提供 zh-Hans
- `RollPurpose.maxLength = 40`（按 `Character` 计）；`RollSpec.dcRange = 1...999`
- `MessageCodec.currentVersion` 保持 `1`；没有目的时网址与现在逐字节相同
- 草稿、`summaryText`、备用布局中永远不出现结果
- 新增源文件后运行 `xcodegen generate`
- 下文 `$SIM` = `-destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .build/DD`
- 扩展测试命令：`xcodebuild test -project Dice.xcodeproj -scheme DiceApp $SIM -only-testing:DiceMessagesTests -quiet`

## Review Focus

1. **之前点开过某条已发送消息，之后在紧凑面板点目的输入框** → 扩展展开后仍是面板并弹出键盘，不跳到那条消息的结果（Task 3 `test_expandForInput_doesNotReveal`）
2. **目的里有 `%`、`&`、`=`、`+`、`#`、中文和 emoji** → 对方看到的目的与输入一致（Task 2 `test_purpose_specialCharactersRoundTrip`）
3. **在 DC 输入框粘贴非数字、`-5`、`007`、空字符串** → 非数字和空保持原 DC；`-5` 变 1；`007` 变 7（Task 3 `test_panel_setDCText`）
4. **粘贴一段超过 40 字的目的** → 输入框里立即截到 40 字，投掷时不会带出更长的内容（Task 3 `test_panel_purposeTruncatesWhileTyping`）
5. **键盘还开着就点「投掷」** → 键盘收起、输入框清空、目的随这次投骰发出（Task 4 手工验收第 3 项；`PanelModel` 部分由 `test_panel_rollReturnsPurposeAndClears` 覆盖）

---

## File Structure

```
DiceKit/Sources/DiceKit/RollSpec.swift          dcRange → 1...999
DiceKit/Sources/DiceKit/RollPurpose.swift       新增：normalize
DiceKit/Sources/DiceKit/MessageCodec.swift      p 字段；decode 返回 purpose
DiceKit/Sources/DiceKit/RollHistory.swift       Entry.purpose
DiceKit/Sources/DiceKit/RollFormatter.swift     summary(_:purpose:_:)
DiceKit/Tests/DiceKitTests/RollPurposeTests.swift  新增
DiceKit/Tests/DiceKitTests/{RollSpec,MessageCodec,RollHistory,RollFormatter}Tests.swift
Shared/PanelModel.swift        purpose、setDC(text:)、roll 返回三元组
Shared/RollPanelView.swift     目的输入框、DC 数字输入、onKeyboardFocus
Shared/ResultCard.swift        purpose 参数
Shared/Localizable.xcstrings   新文案
DiceMessages/Screen.swift              三个 case 携带 purpose
DiceMessages/RevealState.swift         expandForInput()
DiceMessages/MessageFactory.swift      purpose 参数
DiceMessages/BubbleView.swift          显示目的
DiceMessages/MessagesViewController.swift  传目的；键盘时展开
DiceApp/RollerView.swift       结果区与记录显示目的
DiceMessagesTests/{PanelModel,MessageFactory,Screen,RevealState}Tests.swift
README.md、docs/testflight/beta-info.md
```

---

### Task 1: DC 上限 999（DiceKit）

**Files:**
- Modify: `DiceKit/Sources/DiceKit/RollSpec.swift:18`
- Test: `DiceKit/Tests/DiceKitTests/RollSpecTests.swift`、`MessageCodecTests.swift`、`DiceMessagesTests/PanelModelTests.swift:39-47`

**Interfaces:**
- Produces: `RollSpec.dcRange == 1...999`

- [x] **Step 1: 改测试**
  - `RollSpecTests.test_validate_rejectsDCBounds`：上界改为 `RollSpec(dc: 1000)` 抛 `.invalidDC(1000)`；新增断言 `RollSpec(dc: 999)` 校验通过
  - `MessageCodecTests` 新增 `test_dc999RoundTrips`：`RollSpec(sides: 100, dc: 999)`、骰子 `[42]` 编码后解码，`spec.dc == 999`
  - `PanelModelTests.test_panel_clampsDC`：`setDC(1500)` → `999`（原 `setDC(99)` → `40` 删除），`setDC(0)` → `1` 保留
- [x] **Step 2:** `cd DiceKit && swift test`，预期 `test_validate_rejectsDCBounds`、`test_dc999RoundTrips` FAIL
- [x] **Step 3:** `dcRange = 1...999`
- [x] **Step 4:** `swift test` 全部 PASS；扩展测试命令全部 PASS
- [x] **Step 5:** README 第 7 行 `可选 DC（1–40）` → `可选 DC（1–999）`
- [x] **Step 6:** 提交 `fix: allow DCs up to 999`

---

### Task 2: 目的的数据与编解码（DiceKit）

**Files:**
- Create: `DiceKit/Sources/DiceKit/RollPurpose.swift`、`DiceKit/Tests/DiceKitTests/RollPurposeTests.swift`
- Modify: `MessageCodec.swift`、`RollHistory.swift`、`RollFormatter.swift:36-38`
- Test: `MessageCodecTests.swift`、`RollHistoryTests.swift`、`RollFormatterTests.swift`

**Interfaces:**
- Produces:
```swift
public enum RollPurpose {
    public static let maxLength = 40
    public static func normalize(_ raw: String) -> String?
}
MessageCodec.url(for spec: RollSpec, result: RollResult, purpose: String? = nil) -> URL
MessageCodec.decode(_ url: URL) throws -> (spec: RollSpec, result: RollResult, purpose: String?)
RollHistory.Entry.purpose: String?
RollHistory.add(spec: RollSpec, result: RollResult, purpose: String? = nil, date: Date = Date())
RollFormatter.summary(_ spec: RollSpec, purpose: String? = nil, _ language: RollLanguage = .current) -> String
```

- [x] **Step 1: 写失败测试** `RollPurposeTests`
  - `test_trimsWhitespace`：`normalize("  察觉检定 ") == "察觉检定"`
  - `test_newlinesBecomeSpaces`：`normalize("攻击\n哥布林\r\n两次") == "攻击 哥布林 两次"`（`"\r\n"` 是一个 `Character`，换成一个空格）
  - `test_blankIsNil`：`normalize("")`、`normalize("   \n ")` 均为 `nil`
  - `test_keeps40`：40 个 `"a"` 原样返回
  - `test_truncatesTo40`：41 个 `"a"` → 40 个；`String(repeating: "a", count: 39) + " b"`（41 字）→ 39 个 `"a"`（截断后去尾空白）
  - `test_emojiCountsAsOne`：`String(repeating: "👨‍👩‍👧", count: 41)` → `count == 40` 且每个字符仍为 `"👨‍👩‍👧"`
- [x] **Step 2:** `swift test --filter RollPurposeTests`，预期编译失败
- [x] **Step 3:** 实现 `RollPurpose.normalize`：`isNewline` 字符换空格 → `trimmingCharacters(in: .whitespacesAndNewlines)` → `prefix(maxLength)` → 再 trim → 空则 `nil`
- [x] **Step 4: 写失败测试** `MessageCodecTests`
  - `test_purposeRoundTrips`：`url(for:result:purpose: "察觉检定：门后有没有人")` 解码 `purpose` 相同
  - `test_purpose_specialCharactersRoundTrip`：`"100% & a=b + c #1 🎲"` 往返不变
  - `test_noPurposeURLUnchanged`：`url(for: spec, result: r)` 与 `url(for: spec, result: r, purpose: "  ")` 的 `absoluteString` 都等于字面量 `"https://dice.invalid/roll?v=1&n=1&s=20&m=a&k=5&dc=15&d=17,8"`（spec `RollSpec(mode: .advantage, modifier: 5, dc: 15)`，骰子 `[17, 8]`），且不含 `p=`
  - `test_decode_legacyURLHasNoPurpose`：上述字面量网址解码 `purpose == nil`
  - `test_decode_normalizesPurpose`：在上述网址后手工拼 `&p=` + 50 个 `a` → 解码 `purpose` 为 40 个 `a`；拼 `&p=%20%20` → `nil`；均不抛错
  - 现有用到 `decode` 的测试改为取 `.spec`/`.result`（三元组不能再解构为二元组）
- [x] **Step 5: 写失败测试** `RollHistoryTests.test_add_keepsPurpose`（加入 `purpose: "攻击"` 后 `entries[0].purpose == "攻击"`；不传时为 `nil`）；`RollFormatterTests.test_summary_withPurpose`：`summary(RollSpec(mode: .advantage, modifier: 5), purpose: "察觉检定", zh) == "🎲 察觉检定 · 1d20+5 · 优势"`，英文 `"🎲 Perception · 1d20+5 · Advantage"`（purpose `"Perception"`）；`purpose: nil` 同现有
- [x] **Step 6:** `swift test`，预期上述新测试 FAIL
- [x] **Step 7:** 实现：`url` 在 `d` 之后 `normalize(purpose)` 非空才追加 `URLQueryItem(name: "p", ...)`；`decode` 用 `value("p").flatMap(RollPurpose.normalize)`；`RollHistory.Entry` 加字段；`summary` 有目的时为 `"🎲 \(purpose) · \(formula)"`
- [x] **Step 8:** `swift test` 全部 PASS
- [x] **Step 9:** 提交 `feat(dicekit): carry an optional roll purpose`

---

### Task 3: 扩展与面板的数据流

**Files:**
- Modify: `Shared/PanelModel.swift`、`DiceMessages/{Screen,RevealState,MessageFactory,MessagesViewController,BubbleView}.swift`、`Shared/ResultCard.swift`、`DiceApp/RollerView.swift`
- Test: `DiceMessagesTests/{PanelModel,MessageFactory,Screen,RevealState}Tests.swift`

**Interfaces:**
- Consumes: Task 2 全部
- Produces:
```swift
// PanelModel
@Published var purpose: String            // truncated to RollPurpose.maxLength on every set
func setDC(text: String)                  // digits → setDC(clamped); empty / non-numeric → unchanged
func roll<G: RandomNumberGenerator>(using rng: inout G) -> (spec: RollSpec, result: RollResult, purpose: String?)
func roll() -> (spec: RollSpec, result: RollResult, purpose: String?)
// Screen
case pendingBubble(RollSpec, purpose: String?)
case revealedBubble(RollSpec, RollResult, purpose: String?)
case detail(RollSpec, RollResult, purpose: String?)
// RevealState
mutating func expandForInput()            // the next didExpand does not reveal
// MessageFactory
static func makeMessage(spec: RollSpec, result: RollResult, purpose: String?, session: MSSession?) -> MSMessage
// ResultCard
var purpose: String? = nil                // memberwise init: ResultCard(spec:result:purpose:onRollAgain:totalFontSize:)
```

- [x] **Step 1: 写失败测试** `PanelModelTests`
  - `test_panel_rollReturnsPurposeAndClears`：`model.purpose = "  攻击哥布林 "`，`roll()` 的 `.purpose == "攻击哥布林"`，之后 `model.purpose == ""`
  - `test_panel_blankPurposeIsNil`：`purpose = "  "` → `roll().purpose == nil`
  - `test_panel_purposeTruncatesWhileTyping`：赋 50 个 `"a"` → `model.purpose.count == 40`
  - `test_panel_purposeNotSaved`：设目的后 `roll()`，新的 `PanelModel(store: store).purpose == ""`
  - `test_panel_setDCText`：DC 先 `setDC(15)`；`setDC(text: "120")` → 120；`"5000"` → 999；`"007"` → 7；`"-5"` → 1；`""` → 仍为 1；`"abc"` → 仍为 1
  - 现有 `test_panel_rollIsReproducibleWithSeed` 照常（三元组可比较：分别比较 `.spec`、`.result`、`.purpose`）
- [x] **Step 2: 写失败测试** `RevealStateTests.test_expandForInput_doesNotReveal`：`activate()`，`expandForInput()`，`didExpand(selected: sentURL, isPending: false)` → `revealing == false`；随后再 `didExpand(selected: sentURL, isPending: false)` → `true`（只忽略一次）
- [x] **Step 3: 写失败测试** `MessageFactoryTests`
  - 现有 `message` 改为 `purpose: nil`，现有断言不变
  - `test_message_withPurpose`：`purpose: "察觉检定"` → 解码 `purpose == "察觉检定"`；`summaryText == RollFormatter.summary(spec, purpose: "察觉检定")`；`alternateLayout.caption == "察觉检定"`；`subcaption == RollFormatter.formula(spec) + " · " + RollFormatter.installToRevealCaption()`；`caption`、`subcaption`、`summaryText` 都不含 `String(result.total)`
- [x] **Step 4: 写失败测试** `ScreenTests`
  - 现有 case 断言补 `purpose: nil`
  - `test_resolve_transcriptCarriesPurpose`：带 `p` 的已发送网址 → `.revealedBubble(spec, result, purpose: "攻击")`；pending → `.pendingBubble(spec, purpose: "攻击")`
  - `test_resolve_detailCarriesPurpose`：展开且 `revealing` → `.detail(spec, result, purpose: "攻击")`
- [x] **Step 5:** 扩展测试命令，预期编译失败
- [x] **Step 6:** 实现
  - `PanelModel`：`purpose` 的 `didSet` 超长时截到 `prefix(RollPurpose.maxLength)`；`roll(using:)` 读 `RollPurpose.normalize(purpose)` 后置空 `purpose`；`setDC(text:)` 用 `Int(text.trimmingCharacters(in: .whitespaces))`
  - `RevealState`：私有 `ignoreNextExpand`，`expandForInput()` 置真，`didExpand` 遇到时清掉并直接返回；`activate()` 已重置整个结构
  - `Screen.resolve` 从 `decode` 取 `purpose` 填入三个 case
  - `MessageFactory`：`url(for:result:purpose:)`、`summary(spec, purpose:)`；备用布局有目的时 `caption = purpose`、`subcaption = formula + " · " + installToRevealCaption()`，无目的时同现在
  - `MessagesViewController.roll()` 传 `purpose`；`RootView` 的 `.detail` 传 `purpose` 给 `ResultCard`
  - `BubbleView`：模式匹配跟上新 case（显示留到 Task 4，此处只需编译）
  - `RollerView.roll()`：`history.add(spec:result:purpose: rolled.purpose)`
- [x] **Step 7:** 扩展测试命令全部 PASS；`xcodebuild build -project Dice.xcodeproj -scheme DiceApp $SIM -quiet` 成功
- [x] **Step 8:** 提交 `feat: pass the roll purpose through the panel and messages`

---

### Task 4: 界面、文案与文档

**Files:**
- Modify: `Shared/RollPanelView.swift`、`Shared/ResultCard.swift`、`DiceMessages/BubbleView.swift`、`DiceMessages/MessagesViewController.swift`、`DiceApp/RollerView.swift`、`Shared/Localizable.xcstrings`、`README.md`、`docs/testflight/beta-info.md`

**Interfaces:**
- Consumes: Task 3 全部
- Produces: `RollPanelView(model:onRoll:onKeyboardFocus:)`，`var onKeyboardFocus: (() -> Void)? = nil`

- [x] **Step 1: `RollPanelView`**
  - 私有 `enum Field { case purpose, dc }`，`@FocusState private var focus: Field?`；`.onChange(of: focus)` 变为非 nil 时调用 `onKeyboardFocus?()`
  - 最上方 `TextField("Purpose (optional), e.g. Perception check", text: $model.purpose)`，`.submitLabel(.done)`、`.focused($focus, equals: .purpose)`、`.textFieldStyle(.roundedBorder)`
  - DC 行：`Stepper` 的标签由 `Text("\(dc)")` 改为：未聚焦时是显示数字的按钮（点击 → `dcText = String(dc)`，`focus = .dc`）；聚焦时是 `TextField` 绑定 `@State dcText`，`.keyboardType(.numberPad)`、`.focused($focus, equals: .dc)`；`focus` 离开 `.dc` 时 `model.setDC(text: dcText)`
  - `.toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { focus = nil } } }`（`"Done"` 已在 xcstrings 中）
  - 点「投掷」时先 `focus = nil` 再 `onRoll()`
- [x] **Step 2: 扩展展开**：`MessagesViewController.makeRoot` 传 `onKeyboardFocus`：若 `presentationStyle == .compact`，先 `reveal.expandForInput()` 再 `requestPresentationStyle(.expanded)`
- [x] **Step 3: 显示**
  - `BubbleView` pending 与 revealed：有目的时最上方 `Text(purpose).font(.headline).lineLimit(1)`
  - `ResultCard`：有目的时在公式 `Label` 上方 `Text(purpose).font(.headline).lineLimit(2).multilineTextAlignment(.center)`
  - `RollerView.resultArea` 传 `purpose: latest.purpose`；`HistoryRow` 改为 `VStack(alignment: .leading, spacing: 2)`：原 `HStack` + 有目的时 `Text(purpose).font(.caption).foregroundStyle(.secondary).lineLimit(1)`
  - `BubbleView` 增加预览 `#Preview("purpose")`，目的为 40 字的长句
- [x] **Step 4: 文案**：`Localizable.xcstrings` 新增 `"Purpose (optional), e.g. Perception check"` → zh-Hans `"目的（可选），如：察觉检定"`（编译后确认 xcstrings 中没有被标为 stale 的新键）
- [x] **Step 5:** `swift test`、扩展测试命令全部 PASS；`xcodebuild build ... $SIM` 成功
- [x] **Step 6: 模拟器手工验收**（App）
  1. 填「察觉检定」→ 投掷 → 输入框清空；结果区与「最近」显示目的
  2. 不填目的投掷，显示与改动前相同
  3. 键盘开着时直接点「投掷」：键盘收起，目的随这次投骰显示
  4. 粘贴 50 字目的 → 输入框只剩 40 字
  5. 点 DC 数字输入 120 → 120；输入 5000 → 999；清空后点「完成」→ 原值
  6. iPhone SE（或最小屏模拟器）、大字号 accessibility2、深色模式：面板可用，「投掷」可达
- [x] **Step 7: 文档**
  - README：删除第 43 行"用输入框的「添加注释」说明投骰目的"那段，改为：面板最上方可填目的（可选，最多 40 字），会和骰子一起显示在气泡里，投完自动清空；旧版 App 收到时看不到目的
  - `beta-info.md` 顶部新增 0.3.0「测试内容」（中英文）：投骰目的、DC 上限 999 与直接输入、提醒大家更新（旧版收到 DC > 40 显示"数据无效"）、需真机确认的三项（规格第 5 节）
- [x] **Step 8:** 提交 `feat: roll purpose field and typed DC input`
