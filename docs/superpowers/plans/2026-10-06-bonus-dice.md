# 加成骰 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** 公式在主骰之外可带最多 4 组加/减的加成骰（如 `1d20+1d4+5`、`1d8+2d6+3`），App 与扩展都能用二级菜单添加，消息用 `v=2` 携带。

**Architecture:** `DiceKit` 新增 `BonusDice`，`RollSpec.extras` 保存加成骰，`RollResult.bonusRolls` 保存其点数；主骰规则（优势、大成功）不变。`MessageCodec` 只在有加成骰时写 `v=2` 与字段 `x`，骰点续在 `d` 之后。面板新增"加成"行与原地切换的 `BonusPickerView`。

**Tech Stack:** Swift 5.9+、SwiftUI（iOS 17）、Messages、XCTest、XcodeGen。

**Spec:** `docs/superpowers/specs/2026-10-06-bonus-dice-design.md`

**状态（2026-10-06）：** 5 个任务全部完成，整体审查后修复 1 个重要问题；以 0.4.0 发布，已合并到 `main`（PR #10）。偏离见规格"实施记录"。

## Global Constraints

- 最低 iOS 17；`DiceKit` 只用标准库 + Foundation
- 代码与注释英文；界面文案英文为源，`Shared/Localizable.xcstrings` 提供 zh-Hans（手工插入条目，保持文件原有格式）
- `BonusDice.countRange = 1...10`；`BonusDice.allowedSides = [4, 6, 8, 10, 12, 20, 100]`；`RollSpec.maxExtras = 4`
- 无加成骰时网址与现在逐字节相同（`v=1`）；有加成骰时 `v=2`；`MessageCodec.currentVersion = 2`
- 优势/劣势、大成功/大失败只看主骰
- 草稿、`summaryText`、备用布局中永远不出现结果
- 新增源文件后运行 `xcodegen generate`
- `$SIM` = `-destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .build/DD`
- 扩展测试：`xcodebuild test -project Dice.xcodeproj -scheme DiceApp $SIM -only-testing:DiceMessagesTests -quiet`

## Review Focus

1. **主骰 1d20 优势 + 加成骰** → 只在两个 d20 里取高，加成骰全部计入、不参与取舍（Task 2 `test_advantageWithBonus_keepsHigherD20Only`）
2. **已有加成骰时把主骰从 d20 改成 d6** → 优势被重置，加成骰保留（Task 1 `test_normalized_keepsExtras`）
3. **0.3.x 存下的"上次公式"（JSON 无 `extras` 键）** → 照常读出，`extras == []`（Task 1 `test_decode_legacyJSONWithoutExtras`）
4. **被改过的 `v=2` 网址：`x` 有 5 组、重复的 `(sign, sides)`、`1d`、`0d6`、`1d7`** → 显示"数据无效"，不崩溃（Task 3 `test_decode_invalidExtrasRejected`）
5. **标签菜单打开期间该组已被删除，再点「多一个」** → 越界下标被忽略，不崩溃（Task 4 `test_panel_bonusIndexOutOfRangeIgnored`）

---

## File Structure

```
DiceKit/Sources/DiceKit/BonusDice.swift          新增
DiceKit/Sources/DiceKit/RollSpec.swift           extras、maxExtras、validate、addBonus、totalDiceCount、Codable
DiceKit/Sources/DiceKit/RollResult.swift         bonusRolls + 显式 init
DiceKit/Sources/DiceKit/DiceEngine.swift         roll / evaluate 计入加成骰
DiceKit/Sources/DiceKit/RollFormatter.swift      formula / detailMarkdown
DiceKit/Sources/DiceKit/MessageCodec.swift       v=2、x
DiceKit/Tests/DiceKitTests/BonusDiceTests.swift  新增
DiceKit/Tests/DiceKitTests/{RollSpec,DiceEngine,RollFormatter,MessageCodec}Tests.swift
Shared/PanelModel.swift          加成骰操作、isPickingBonus
Shared/RollPanelView.swift       加成行、切换到 BonusPickerView
Shared/BonusPickerView.swift     新增：二级菜单
Shared/Localizable.xcstrings     新文案
DiceMessagesTests/{PanelModel,Screen,MessageFactory}Tests.swift
README.md、docs/testflight/beta-info.md
```

---

### Task 1: 加成骰数据模型

**Files:**
- Create: `DiceKit/Sources/DiceKit/BonusDice.swift`、`DiceKit/Tests/DiceKitTests/BonusDiceTests.swift`
- Modify: `DiceKit/Sources/DiceKit/RollSpec.swift`
- Test: `DiceKit/Tests/DiceKitTests/RollSpecTests.swift`

**Interfaces:**
- Produces:
```swift
public struct BonusDice: Codable, Equatable, Hashable, Sendable {
    public enum Sign: String, Codable, Sendable { case plus, minus }
    public static let countRange = 1...10
    public static let allowedSides = [4, 6, 8, 10, 12, 20, 100]
    public var sign: Sign
    public var count: Int
    public var sides: Int
    public init(sign: Sign = .plus, count: Int = 1, sides: Int)
}
// RollSpec
public static let maxExtras = 4
public var extras: [BonusDice]                       // init 参数 extras: [BonusDice] = []，位于 modifier 之后、dc 之前
public var totalDiceCount: Int                       // diceToRoll + Σ extras.count
public mutating func addBonus(sign: BonusDice.Sign, sides: Int)
public func canAddBonus(sign: BonusDice.Sign, sides: Int) -> Bool   // 合并可行或还能新开一组
// RollSpecError
case invalidExtras
```

- [x] **Step 1: 写失败测试** `BonusDiceTests`
  - `test_addBonus_appendsNewGroup`：`RollSpec()` 加 `(.plus, 4)` → `extras == [BonusDice(sides: 4)]`
  - `test_addBonus_mergesSameKind`：再加 `(.plus, 4)` → `extras == [BonusDice(count: 2, sides: 4)]`；加 `(.minus, 4)` → 第二组 `BonusDice(sign: .minus, sides: 4)`
  - `test_addBonus_countCapsAt10`：同种加 11 次 → `count == 10`
  - `test_addBonus_maxFourGroups`：加 d4、d6、d8、d10 后再加 d12 → 仍 4 组；`canAddBonus(sign: .plus, sides: 12) == false`、`canAddBonus(sign: .plus, sides: 6) == true`
  - `test_totalDiceCount`：`RollSpec(mode: .advantage, extras: [BonusDice(count: 2, sides: 6)])` → `totalDiceCount == 4`
- [x] **Step 2: 写失败测试** `RollSpecTests`
  - `test_validate_rejectsBadExtras`：5 组、`count` 0、`count` 11、`sides` 7、重复 `(plus, 4)` 两组 → 均抛 `.invalidExtras`；合法 2 组通过
  - `test_validate_allowsAdvantageWithExtras`：`RollSpec(mode: .advantage, extras: [BonusDice(sides: 4)])` 通过
  - `test_normalized_keepsExtras`：`RollSpec(sides: 6, mode: .advantage, extras: [BonusDice(sides: 4)]).normalized()` → `mode == .normal`、`extras` 不变
  - `test_decode_legacyJSONWithoutExtras`：解码 `{"count":1,"sides":20,"mode":"advantage","modifier":5,"dc":15}` → `extras == []`，其余字段正确
  - `test_codable_roundTripsExtras`：带两组 extras 的 spec JSON 往返相等
- [x] **Step 3:** `swift test --package-path DiceKit`，预期编译失败
- [x] **Step 4:** 实现。`RollSpec.init(from:)` 用 `decodeIfPresent(…, forKey: .extras) ?? []`；`encode(to:)` 由编译器合成（声明 `CodingKeys`）；`addBonus` 在 `canAddBonus` 为假时不变
- [x] **Step 5:** `swift test --package-path DiceKit` 全部 PASS（XCTest 行 `Executed N tests, with 0 failures`）
- [x] **Step 6:** 提交 `feat(dicekit): bonus dice in the roll spec`

---

### Task 2: 投骰、计分与文字

**Files:**
- Modify: `DiceKit/Sources/DiceKit/RollResult.swift`、`DiceEngine.swift`、`RollFormatter.swift`
- Test: `DiceKit/Tests/DiceKitTests/DiceEngineTests.swift`、`RollFormatterTests.swift`

**Interfaces:**
- Consumes: Task 1
- Produces:
```swift
// RollResult
public let bonusRolls: [[Int]]           // aligned with spec.extras
init(dice: [Int], keptIndices: [Int], bonusRolls: [[Int]] = [], total: Int, critical: Critical, dcOutcome: DCOutcome?)
// DiceEngine
static func evaluate(_ spec: RollSpec, dice: [Int], bonusRolls: [[Int]] = []) -> RollResult
```

- [x] **Step 1: 写失败测试** `DiceEngineTests`
  - `test_bonusAddsAndSubtracts`：`RollSpec(modifier: 5, extras: [BonusDice(sides: 4), BonusDice(sign: .minus, count: 2, sides: 6)])`，`dice: [12]`，`bonusRolls: [[3], [2, 5]]` → `total == 12 + 3 - 7 + 5 == 13`
  - `test_negativeTotal`：`RollSpec(sides: 4, extras: [BonusDice(sign: .minus, count: 2, sides: 6)])`，`[1]`、`[[6, 6]]` → `total == -11`，`critical == .none`
  - `test_advantageWithBonus_keepsHigherD20Only`：`RollSpec(mode: .advantage, extras: [BonusDice(sides: 4)])`，`dice: [8, 17]`、`[[4]]` → `keptIndices == [1]`、`total == 21`
  - `test_bonusDoesNotChangeCritical`：主骰 `[20]` 加 `-1d4` `[[4]]`、DC 30 → `critical == .success`、`dcOutcome == .success`、`total == 16`；主骰 `[1]` 加 `+1d4` `[[4]]`、DC 2 → `.failure`、`.failure`
  - `test_bonusCountsTowardDC`：`RollSpec(modifier: 2, dc: 15, extras: [BonusDice(sides: 4)])`，`[11]`、`[[2]]` → `dcOutcome == .success`
  - `test_rollWithBonus_reproducibleAndInRange`：两个 `SplitMix64(seed: 3)` 投 `1d20+2d6-1d4` → 结果相等；`bonusRolls.map(\.count) == [2, 1]`；各点在面数范围内
- [x] **Step 2: 写失败测试** `RollFormatterTests`
  - `test_formula_withBonus`：`RollSpec(mode: .advantage, modifier: 5, dc: 15, extras: [BonusDice(sides: 4)])` → zh `"1d20+1d4+5 · 优势 · DC 15"`、en `"1d20+1d4+5 · Advantage · DC 15"`；`RollSpec(sides: 8, modifier: 3, extras: [BonusDice(count: 2, sides: 6)])` → `"1d8+2d6+3"`；`RollSpec(extras: [BonusDice(sign: .minus, sides: 4)])` → `"1d20-1d4"`
  - `test_detail_withBonus`：优势 `[17, 8]`、`+1d4` `[3]`、`+5` → `"[17, ~~8~~] + [3] + 5 = 25"`；`1d20-2d6` `[10]`、`[[2, 5]]` → `"[10] - [2, 5] = 3"`
- [x] **Step 3:** `swift test --package-path DiceKit`，预期编译失败
- [x] **Step 4:** 实现。`roll` 先投 `diceToRoll` 个主骰，再按 `extras` 每组投 `count` 个 `1...sides`；`evaluate` 的 `total` 加上 `plus` 组之和、减去 `minus` 组之和；`detailMarkdown` 在主骰之后、加值之前插入 ` + [..]` / ` - [..]`
- [x] **Step 5:** `swift test --package-path DiceKit` 全部 PASS
- [x] **Step 6:** 提交 `feat(dicekit): roll and describe bonus dice`

---

### Task 3: 消息格式 v2

**Files:**
- Modify: `DiceKit/Sources/DiceKit/MessageCodec.swift`
- Test: `DiceKit/Tests/DiceKitTests/MessageCodecTests.swift`

**Interfaces:**
- Consumes: Task 1、2
- Produces: `MessageCodec.currentVersion == 2`；`url(for:result:purpose:)`、`decode(_:)` 签名不变

- [x] **Step 1: 写失败测试** `MessageCodecTests`
  - 现有 `test_url_containsVersion` 不变（无加成骰仍是 `"1"`）；现有 `test_noPurposeURLUnchanged` 不变
  - `test_bonusURLUsesV2`：`RollSpec(modifier: 5, extras: [BonusDice(sides: 4), BonusDice(sign: .minus, count: 2, sides: 6)])`、`[12]`、`[[3], [2, 5]]` → `absoluteString == "https://dice.invalid/roll?v=2&n=1&s=20&m=n&k=5&x=1d4,-2d6&d=12,3,2,5"`
  - `test_bonusRoundTrips`：上例与"优势 + DC + 目的"组合各往返，`spec`、`result`、`purpose` 相等
  - `test_decode_invalidExtrasRejected`：在 `v=2&n=1&s=20&m=n&k=0` 后分别拼 `&x=1d4,1d6,1d8,1d10,1d12&d=1,1,1,1,1,1` → `invalidSpec(.invalidExtras)`；`&x=1d4,1d4&d=1,1,1` → `invalidSpec(.invalidExtras)`；`&x=1d&d=1,1` → `malformed("x")`；`&x=0d6&d=1` → `invalidSpec(.invalidExtras)`；`&x=1d7&d=1,1` → `invalidSpec(.invalidExtras)`
  - `test_decode_bonusDiceCountMismatch`：`x=2d6` 但 `d` 只有 2 个数 → `invalidDice`；`x=1d4`、加成点数 5 → `invalidDice`
  - `test_decode_v3NeedsUpdate`：`v=3` → `unsupportedVersion(3)`
  - `test_decode_v1IgnoresX`：`v=1&n=1&s=20&m=n&k=0&x=1d4&d=7` → 解码成功，`extras == []`
- [x] **Step 2:** `swift test --package-path DiceKit --filter MessageCodecTests`，预期新测试 FAIL
- [x] **Step 3:** 实现。编码：`extras` 为空写 `v=1`、不写 `x`；否则 `v=2`，`x` 放在 `k`/`dc` 之后、`d` 之前，每组 `"\(minus ? "-" : "")\(count)d\(sides)"`；`d` = 主骰 + 各组点数。解码：`v ∈ 1...2`；`v == 2` 时解析 `x`（逗号分隔，正则式 `-?\d+d\d+`，解析失败 → `malformed("x")`）；按 `diceToRoll` 与各组 `count` 切 `d`，总数不等 → `invalidDice`；每组点数在 `1...sides` 外 → `invalidDice`
- [x] **Step 4:** `swift test --package-path DiceKit` 全部 PASS
- [x] **Step 5:** 提交 `feat(dicekit): encode bonus dice as message version 2`

---

### Task 4: 面板模型与扩展数据流

**Files:**
- Modify: `Shared/PanelModel.swift`
- Test: `DiceMessagesTests/PanelModelTests.swift`、`ScreenTests.swift`、`MessageFactoryTests.swift`

**Interfaces:**
- Consumes: Task 1–3
- Produces（`PanelModel`）：
```swift
@Published var isPickingBonus: Bool
func addBonus(sign: BonusDice.Sign, sides: Int)     // 加入并把 isPickingBonus 设为 false
func incrementBonus(at index: Int)                  // count + 1（上限 10）
func decrementBonus(at index: Int)                  // count - 1；到 0 则删除该组
func removeBonus(at index: Int)
func canAddBonus(sign: BonusDice.Sign, sides: Int) -> Bool
```
所有修改走现有 `update`（保存时 `normalized()`）；越界下标直接返回。

- [x] **Step 1: 写失败测试** `PanelModelTests`
  - `test_panel_addBonusClosesPicker`：`isPickingBonus = true`，`addBonus(sign: .plus, sides: 4)` → `spec.extras == [BonusDice(sides: 4)]`、`isPickingBonus == false`
  - `test_panel_incrementDecrementRemove`：加 d6 → `incrementBonus(at: 0)` → count 2；`decrementBonus(at: 0)` 两次 → `extras.isEmpty`；再加 d4、d8，`removeBonus(at: 0)` → `[BonusDice(sides: 8)]`
  - `test_panel_incrementCapsAt10`：加 d6 后 `incrementBonus(at: 0)` 12 次 → count 10
  - `test_panel_bonusIndexOutOfRangeIgnored`：空列表上 `incrementBonus(at: 0)`、`decrementBonus(at: 3)`、`removeBonus(at: -1)` → 不崩溃，`extras.isEmpty`
  - `test_panel_bonusSavedWithSpec`：加 `(.minus, 4)` 后 `roll()` → `store.load().extras == [BonusDice(sign: .minus, sides: 4)]`
  - `test_panel_rollIncludesBonus`：加 2 组后 `roll().result.bonusRolls.map(\.count) == [1, 1]`
- [x] **Step 2: 写失败测试** `ScreenTests.test_resolve_bonusMessage`：带 `+1d4` 的网址 → `.revealedBubble(spec, result, purpose: nil)` 且 `spec.extras.count == 1`；`MessageFactoryTests.test_message_withBonus`：备用布局 `caption == RollFormatter.formula(spec)`（含 `+1d4`），`summaryText` 含 `"1d4"`，二者都不含 `String(result.total)`（用主骰 `[20]`、加成 `[3]`、`+5`，total 28）
- [x] **Step 3:** 扩展测试命令，预期编译失败
- [x] **Step 4:** 实现 `PanelModel` 的五个方法与 `isPickingBonus`
- [x] **Step 5:** 扩展测试命令全部 PASS；`swift test --package-path DiceKit` 全部 PASS
- [x] **Step 6:** 提交 `feat: bonus dice in the panel model`

---

### Task 5: 加成行、二级菜单、文案与文档

**Files:**
- Create: `Shared/BonusPickerView.swift`
- Modify: `Shared/RollPanelView.swift`、`Shared/Localizable.xcstrings`、`README.md`、`docs/testflight/beta-info.md`

**Interfaces:**
- Consumes: Task 4
- Produces: `struct BonusPickerView: View { @ObservedObject var model: PanelModel }`

- [x] **Step 1: `BonusPickerView`**：顶部 `Button("Back", systemImage: "chevron.left")` 置 `model.isPickingBonus = false`；标题 `Text("Bonus Dice")`；`Picker` 分段 `Add` / `Subtract`（`@State sign = .plus`，视图出现时为 `.plus`）；d4…d100 按钮（样式同主面板面数按钮），`.disabled(!model.canAddBonus(sign:sides:))`，点击 `model.addBonus(sign:sides:)`
- [x] **Step 2: `RollPanelView`**
  - `body` 内：`model.isPickingBonus` 为真时显示 `BonusPickerView`，否则显示原面板；切换用 `.transition(.move(edge: .trailing).combined(with: .opacity))` + `withAnimation`
  - "数量 / 加值"之后新增 `bonusRow`：`ScrollView(.horizontal)` 内依次为每组 `Menu`（标签文字 `"+1d4"` / `"−2d6"`，样式同面数按钮；菜单项 `One More`（count 为 10 时禁用）、`One Fewer`、`Remove`），末尾 `Button("Bonus", systemImage: "plus")` 置 `isPickingBonus = true`
  - 正在编辑目的或 DC 时打开二级菜单，先 `focus = nil`
- [x] **Step 3: 文案**：xcstrings 插入 `Bonus`→加成、`Bonus Dice`→加成骰、`Add`→加、`Subtract`→减、`One More`→多一个、`One Fewer`→少一个、`Remove`→删除、`Back`→返回（已存在的键不重复）
- [x] **Step 4:** `xcodegen generate`；`swift test --package-path DiceKit`、扩展测试命令全部 PASS
- [x] **Step 5: 模拟器手工验收**（规格第 5 节 1–5 项）：App 投 `1d20+1d4+5` 优势 DC 15、`1d20-1d4`、`1d8+2d6+3`；二级菜单自动返回与「返回」；标签菜单三项；4 组后新种类禁用；扩展中添加并插入草稿；iPhone 16e + accessibility-large + 深色
- [x] **Step 6: 文档**：README 功能列表加"加成骰：最多 4 组，每组 1–10 个 d4–d100，可加可减（如 1d20+1d4、1d8+2d6+3）"，并说明带加成骰的消息需要 0.4.0 及以上；`beta-info.md` 顶部新增 0.4.0「测试内容」（中英文：三种组合、二级菜单、标签菜单、旧版显示"请更新 App"）
- [x] **Step 7:** 提交 `feat: bonus dice row and picker`
