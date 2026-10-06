# App 内投骰 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 宿主 App 主页变成投骰界面：与 iMessage 扩展同一套面板，结果大字显示，下面保留最近 10 次记录。

**Architecture:** 面板相关代码（`PanelModel`、`SpecStore`、`RollPanelView`、`ResultCard`）移到 `Shared/`，App、扩展、扩展测试三个 target 共同编译；`PanelModel` 去掉 Messages 依赖，只返回 `(spec, result)`，消息由扩展自己组装。最近记录是 `DiceKit` 里的纯逻辑 `RollHistory`。

**Tech Stack:** Swift 5.9+、SwiftUI（iOS 17）、XCTest、XcodeGen。

**Spec:** `docs/superpowers/specs/2026-10-06-in-app-roller-design.md`

**状态（2026-10-06）：** 3 个任务完成，整体审查后修复 3 个问题，均提交在本地 `dev`（未推送）。偏离与取舍见规格"实施记录"和 `docs/superpowers/autorun/2026-10-06-log.md`。

## Global Constraints

- 最低系统 iOS 17；`DiceKit` 只能用标准库 + Foundation
- 代码和注释用英文；面向用户的文案用中文，文案以规格为准
- `RollHistory.capacity = 10`，新的在前，只存在内存
- iMessage 扩展行为不变：消息仍由 `MessageFactory.makeMessage(spec:result:session:)` 生成，面板与草稿中不出现结果
- 文件移动用 `git mv`；新增/移动源文件后运行 `xcodegen generate`
- 下文 `$SIM` = `-destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .build/DD`

## Review Focus

1. **完全相同的两次投骰**（同公式同结果）→ 记录里是两条独立的行，不会被当成同一条合并或刷新错行（Task 1 `test_add_identicalRollsGetDistinctIDs`）
2. **连续投出相同总值** → 仍有数字动画与震动，看得出又投了一次（Task 3 手工验收第 4 项；动画/震动的触发键用每次投骰的记录 ID，而不是总值）
3. **iPhone SE 小屏** → 结果区与面板完整显示，记录区可滚动（Task 3 手工验收第 7 项）
4. **扩展移走 `PanelModel` 后** → 插入草稿与面板收起照常，草稿不含结果（Task 2 保留 `MessageFactoryTests`；手工在模拟器扩展里投一次）
5. **App 与扩展的公式互不覆盖** → 两边各自记住上次公式（Task 3 手工验收第 5 项；`SpecStore()` 用各自沙盒的 `UserDefaults.standard`，不加 App Group）

---

## File Structure

```
DiceKit/Sources/DiceKit/RollHistory.swift        新增
DiceKit/Tests/DiceKitTests/RollHistoryTests.swift 新增
Shared/PanelModel.swift      ← git mv DiceMessages/PanelModel.swift（改接口）
Shared/SpecStore.swift       ← git mv DiceMessages/SpecStore.swift
Shared/RollPanelView.swift   ← git mv DiceMessages/RollPanelView.swift
Shared/ResultCard.swift      ← git mv DiceMessages/ResultCard.swift
DiceMessages/MessagesViewController.swift   改 roll()
DiceMessagesTests/PanelModelTests.swift     改两个测试
DiceApp/DiceApp.swift        入口改为 RollerView
DiceApp/RollerView.swift     新增
DiceApp/GuideView.swift      新增（原 ContentView）
project.yml                  三个 target 加入 Shared
README.md                    提到 App 内投骰
```

---

### Task 1: RollHistory

**Files:**
- Create: `DiceKit/Sources/DiceKit/RollHistory.swift`
- Test: `DiceKit/Tests/DiceKitTests/RollHistoryTests.swift`

**Interfaces:**
- Produces:
```swift
public struct RollHistory: Equatable, Sendable {
    public struct Entry: Equatable, Identifiable, Sendable {
        public let id: UUID
        public let spec: RollSpec
        public let result: RollResult
        public let date: Date
    }
    public static let capacity: Int            // 10
    public private(set) var entries: [Entry]   // newest first
    public init()
    public mutating func add(spec: RollSpec, result: RollResult, date: Date = Date())
}
```

- [x] **Step 1: 写失败测试** `RollHistoryTests`
  - `test_init_isEmpty`：`RollHistory().entries.isEmpty`
  - `test_add_newestFirst`：先加 1d6 `[2]`、再加 1d8 `[5]` → `entries.map(\.spec.sides) == [8, 6]`
  - `test_add_dropsOldestBeyondCapacity`：加 11 条（第 i 条用 `RollSpec(modifier: i)`，i = 0…10）→ `entries.count == 10`，`entries.first?.spec.modifier == 10`，`entries.last?.spec.modifier == 1`
  - `test_add_keepsSpecResultAndDate`：`date = Date(timeIntervalSince1970: 1000)`，加入后 `entries[0]` 的 spec、result、date 与传入相同
  - `test_add_identicalRollsGetDistinctIDs`：同一 spec/result 加两次 → `entries.count == 2`，`entries[0].id != entries[1].id`
- [x] **Step 2:** `cd DiceKit && swift test --filter RollHistoryTests`，预期编译失败（`RollHistory` 未定义）
- [x] **Step 3:** 实现 `RollHistory`（每次 `add` 用新的 `UUID()`，插入下标 0，超出 `capacity` 时 `removeLast`）
- [x] **Step 4:** `cd DiceKit && swift test`，预期全部 PASS（原 33 个 + 新 5 个）
- [x] **Step 5:** 提交 `feat(dicekit): add in-memory roll history`

---

### Task 2: 共享面板代码 + PanelModel.roll()

**Files:**
- Move: `DiceMessages/{PanelModel,SpecStore,RollPanelView,ResultCard}.swift` → `Shared/`
- Modify: `Shared/PanelModel.swift`、`DiceMessages/MessagesViewController.swift`（`roll()`）、`DiceMessagesTests/PanelModelTests.swift`、`project.yml`

**Interfaces:**
- Consumes: `MessageFactory.makeMessage(spec:result:session:)`（已存在）
- Produces（`PanelModel`，`@MainActor`，不再 `import Messages`）：
```swift
func roll<G: RandomNumberGenerator>(using rng: inout G) -> (spec: RollSpec, result: RollResult)
func roll() -> (spec: RollSpec, result: RollResult)   // SystemRandomNumberGenerator
```
  两者都先 `store.save(spec)`；`makeRoll()` 删除。

- [x] **Step 1:** `git mv` 四个文件到 `Shared/`；`project.yml`：
  - `DiceApp.sources` 改为 `[DiceApp, Shared]`
  - `DiceMessages.sources` 增加 `- Shared`
  - `DiceMessagesTests.sources` 中 `DiceMessages/PanelModel.swift`、`DiceMessages/SpecStore.swift` 换成 `Shared/PanelModel.swift`、`Shared/SpecStore.swift`
  
  `xcodegen generate`，运行 `xcodebuild build -project Dice.xcodeproj -scheme DiceApp $SIM`，预期 `BUILD SUCCEEDED`（此时接口未改）
- [x] **Step 2: 改测试** `PanelModelTests`
  - `test_panel_makeRollSavesSpec` → `test_panel_rollSavesSpec`：选 d12、加值 +2，`_ = model.roll()`，`store.load() == model.spec`
  - `test_panel_makeRollMessageDecodes` → `test_panel_rollIsReproducibleWithSeed`：设优势与 DC 15；两个 `SplitMix64(seed: 7)` 分别 `roll(using:)` → 两次返回值相等，且 `.spec == model.spec`
- [x] **Step 3:** `xcodebuild test -project Dice.xcodeproj -scheme DiceApp $SIM -only-testing:DiceMessagesTests`，预期编译失败（`roll` 未定义）
- [x] **Step 4:** 实现两个 `roll` 并删除 `makeRoll()`；`MessagesViewController.roll()` 改为 `let (spec, result) = model.roll()` 后 `conversation.insert(MessageFactory.makeMessage(spec: spec, result: result, session: nil))`，其余（错误提示、`dismiss()`）不变
- [x] **Step 5:** 再次运行 Step 3 的命令，预期 35/35 PASS
- [x] **Step 6:** 构建运行到模拟器，在「信息」扩展里投一次：草稿出现、面板收起（气泡在模拟器上为空属已知现象）
- [x] **Step 7:** 提交 `refactor: share the roll panel between app and extension`

---

### Task 3: App 主页 RollerView

**Files:**
- Create: `DiceApp/RollerView.swift`、`DiceApp/GuideView.swift`
- Modify: `DiceApp/DiceApp.swift`、`README.md`

**Interfaces:**
- Consumes: `PanelModel(store:)`、`roll()`（Task 2）；`RollPanelView(model:onRoll:)`；`ResultCard(spec:result:onRollAgain:)`；`RollResult.outcomeColor`；`RollHistory`（Task 1）；`RollFormatter.formula/outcome`
- Produces: `struct RollerView: View`、`struct GuideView: View`

- [x] **Step 1:** `GuideView`：原 `ContentView` 的 `List` 内容原样移入（标题「使用说明」，sheet 内放「完成」按钮关闭）；删除 `ContentView`；`DiceApp` 的 `WindowGroup` 改为 `RollerView()`
- [x] **Step 2:** `RollerView`，按规格第 4 节布局（`NavigationStack`，标题「骰子」，工具栏「?」→ `GuideView` sheet）：
  - 状态：`@StateObject model = PanelModel(store: SpecStore())`、`@State history = RollHistory()`
  - 结果区固定高度 220：`history.entries.first` 为 nil 时显示灰字「选好骰子，点「投掷」」，否则 `ResultCard(spec:result:onRollAgain: nil)`
  - 「最近」列表：每行 `时间(HH:mm) · formula · total · outcome`，outcome 用 `outcomeColor`；不可点击
  - 底部 `RollPanelView(model: model) { let r = model.roll(); history.add(spec: r.spec, result: r.result) }`
  - 反馈以 `history.entries.first?.id` 为触发键：总值 `.contentTransition(.numericText())` + `withAnimation`；`.sensoryFeedback`，大成功 `.success`、大失败 `.error`、其余 `.impact(weight: .light)`
- [x] **Step 3:** `xcodebuild build ... $SIM` 成功；`cd DiceKit && swift test` 与 `-only-testing:DiceMessagesTests` 全部 PASS
- [x] **Step 4:** 模拟器手工验收（规格第 7 节 1–8 项），重点 Review Focus 第 2、3、5 项；SE 用 `iPhone 16e` 或可用的最小屏模拟器
- [x] **Step 5:** README「构建与运行」后加一段：打开 App 本身即可投骰，适合线下跑团；最近 10 次记录关掉即清空
- [x] **Step 6:** 提交 `feat(app): roll dice in the app with recent history`
