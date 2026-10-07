# 大成功 / 大失败判定开关 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** App 设置页可关闭大成功 / 大失败判定；App 与「信息」扩展按该设置投骰，关闭时消息以 `v=3&c=0` 携带，所有人看到同一个结果。

**Architecture:** `RollSpec.criticalsEnabled` 决定 `DiceEngine` 是否判定天然 20 / 1，`RollFormatter` 在公式里标出。`MessageCodec` 只在判定关且主骰为单个 d20 时写 `v=3` 与 `c=0`。设置存在 App Group 共享的 `SettingsStore`，`PanelModel.refreshSettings()` 在创建、激活、关闭设置页和投掷前同步到 `spec`。

**Tech Stack:** Swift 5.9+、SwiftUI（iOS 17）、Messages、XCTest、XcodeGen。

**Spec:** `docs/superpowers/specs/2026-10-07-critical-toggle-design.md`

## Global Constraints

- 最低 iOS 17；`DiceKit` 只用标准库 + Foundation
- 代码与注释英文；界面文案英文为源，`Shared/Localizable.xcstrings` 手工插入 zh-Hans 条目，保持原格式
- App Group：`group.dev.ansel.dice`；设置键：`criticalsEnabled`，缺省 `true`
- 判定开时网址与现在逐字节相同（`v=1` / `v=2`）；`MessageCodec.currentVersion = 3`
- 公式标注：中文 ` · 不判定大成功`，英文 ` · No crits`，仅在 `!criticalsEnabled && isSingleD20` 时出现
- `$SIM` = `-destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .build/DD`
- 扩展测试：`xcodebuild test -project Dice.xcodeproj -scheme DiceApp $SIM -only-testing:DiceMessagesTests -quiet`

## Review Focus

1. **判定关 + 优势，较高的 d20 是天然 20，总值低于 DC** → 失败、不显示大成功（Task 1 `test_criticalsOff_advantageUsesTotal`）
2. **先在 App 里关掉判定，再切到已经开着的「信息」扩展** → 扩展激活时读到新设置，公式立即带标注（Task 3 `test_panel_didActivateRefreshesSettings`）
3. **收到别人判定关闭的消息，而自己的设置是开** → 按发送者的设置显示，不受自己设置影响（Task 3 `test_resolve_criticalsOffIgnoresReceiverSetting`）
4. **`SpecStore` 里存着 `criticalsEnabled == false` 的旧公式，而设置已改回开** → 以设置为准（Task 3 `test_panel_settingOverridesStoredFlag`）
5. **判定关但主骰是 2d20 或 d6** → 公式不带标注，网址不写 `c`、不升版本（Task 1 `test_formula_noCritsOnlyForSingleD20`、Task 2 `test_criticalsOffNonD20StaysV1`）

---

## File Structure

```
DiceKit/Sources/DiceKit/RollSpec.swift        criticalsEnabled + Codable
DiceKit/Sources/DiceKit/DiceEngine.swift      判定条件
DiceKit/Sources/DiceKit/RollFormatter.swift   公式标注
DiceKit/Sources/DiceKit/MessageCodec.swift    v=3、c
DiceKit/Tests/DiceKitTests/{RollSpec,DiceEngine,RollFormatter,MessageCodec}Tests.swift
Shared/SettingsStore.swift       新增：App Group 设置
Shared/PanelModel.swift          settings 注入、refreshSettings()
DiceApp/SettingsView.swift       新增：设置页
DiceApp/RollerView.swift         齿轮按钮、sheet
DiceApp/GuideView.swift          使用说明新增一条
Shared/Localizable.xcstrings     新文案
project.yml                      两个 target 的 entitlements；测试 target 加入 SettingsStore.swift
DiceMessagesTests/{SettingsStore,PanelModel,Screen,SpecStore}Tests.swift
README.md、README.zh-CN.md、docs/user-guide*.md、docs/roadmap.md、docs/testflight/beta-info.md
```

---

### Task 1: 规则与公式（DiceKit）

**Files:**
- Modify: `DiceKit/Sources/DiceKit/RollSpec.swift`、`DiceEngine.swift:32`、`RollFormatter.swift:35`
- Test: `DiceKit/Tests/DiceKitTests/{RollSpec,DiceEngine,RollFormatter}Tests.swift`

**Interfaces:**
- Produces:
```swift
// RollSpec
public var criticalsEnabled: Bool          // default true
public init(count:sides:mode:modifier:dc:extras:criticalsEnabled: Bool = true)
```

- [ ] **Step 1: 写失败测试**
  - `DiceEngineTests.test_criticalsOff_noCriticalAndTotalDecides`：`RollSpec(dc: 30, criticalsEnabled: false)`、`[20]` → `critical == .none`、`dcOutcome == .failure`；`RollSpec(dc: 1, criticalsEnabled: false)`、`[1]` → `.none`、`.success`
  - `DiceEngineTests.test_criticalsOff_advantageUsesTotal`：`RollSpec(mode: .advantage, modifier: 2, dc: 25, criticalsEnabled: false)`、`[20, 7]` → `keptIndices == [0]`、`total == 22`、`critical == .none`、`dcOutcome == .failure`
  - `RollSpecTests.test_decode_legacyJSONCriticalsEnabled`：旧 JSON `{"count":1,"sides":20,"mode":"normal","modifier":0}` → `criticalsEnabled == true`；`criticalsEnabled: false` 的 spec JSON 往返相等
  - `RollFormatterTests.test_formula_noCrits`：`RollSpec(mode: .advantage, modifier: 5, dc: 15, criticalsEnabled: false)` → zh `"1d20+5 · 优势 · DC 15 · 不判定大成功"`，en `"1d20+5 · Advantage · DC 15 · No crits"`
  - `RollFormatterTests.test_formula_noCritsOnlyForSingleD20`：`RollSpec(count: 2, criticalsEnabled: false)` → `"2d20"`；`RollSpec(sides: 6, criticalsEnabled: false)` → `"1d6"`
- [ ] **Step 2:** `swift test --package-path DiceKit`，预期编译失败
- [ ] **Step 3:** 实现：`RollSpec` 加字段（`CodingKeys` 加 `criticalsEnabled`，`init(from:)` 用 `decodeIfPresent ?? true`）；`DiceEngine` 条件改为 `spec.isSingleD20 && spec.criticalsEnabled`；`formula` 在 DC 之后追加标注
- [ ] **Step 4:** `swift test --package-path DiceKit` 全部 PASS
- [ ] **Step 5:** 提交 `feat(dicekit): optional critical success and failure`

---

### Task 2: 消息格式 v3

**Files:**
- Modify: `DiceKit/Sources/DiceKit/MessageCodec.swift`
- Test: `DiceKit/Tests/DiceKitTests/MessageCodecTests.swift`

**Interfaces:**
- Consumes: Task 1
- Produces: `MessageCodec.currentVersion == 3`；签名不变

- [ ] **Step 1: 写失败测试** `MessageCodecTests`
  - `test_criticalsOffUsesV3`：`RollSpec(modifier: 5, dc: 15, criticalsEnabled: false)`、`[20]` → `absoluteString == "https://dice.invalid/roll?v=3&n=1&s=20&m=n&k=5&dc=15&c=0&d=20"`
  - `test_criticalsOffRoundTrips`：上例、"加 `+1d4`（`[3]`）"、"带目的 `攻击`" 各往返，`spec.criticalsEnabled == false`、`result.critical == .none`、`result` 与编码前相等
  - `test_criticalsOffNonD20StaysV1`：`RollSpec(sides: 6, criticalsEnabled: false)`、`[4]` → `absoluteString == "https://dice.invalid/roll?v=1&n=1&s=6&m=n&k=0&d=4"`，解码得 `criticalsEnabled == true`（主骰非 d20 时二者等价）
  - `test_decode_badCriticalsField`：`v=3&n=1&s=20&m=n&k=0&c=x&d=7` → `malformed("c")`
  - `test_decode_v3WithoutCIsEnabled`：`v=3&n=1&s=20&m=n&k=0&d=20` → `criticalsEnabled == true`、`critical == .success`
  - `test_decode_v2IgnoresC`：`v=2&n=1&s=20&m=n&k=0&x=1d4&c=0&d=20,3` → `criticalsEnabled == true`
  - 现有 `test_decode_futureVersion` 改为 `v=4` → `unsupportedVersion(4)`；现有 `test_noPurposeURLUnchanged`、`test_bonusURLUsesV2` 保持不变
- [ ] **Step 2:** `swift test --package-path DiceKit --filter MessageCodecTests`，预期新测试 FAIL
- [ ] **Step 3:** 实现：版本 = `!criticalsEnabled && isSingleD20 ? 3 : (extras.isEmpty ? 1 : 2)`；`c=0` 放在 `x` 之后、`d` 之前；解码 `v ∈ 1...3`，`v >= 3` 时读 `c`（`"0"` → false，缺失 → true，其他 → `malformed("c")`）
- [ ] **Step 4:** `swift test --package-path DiceKit` 全部 PASS
- [ ] **Step 5:** 提交 `feat(dicekit): carry the critical setting as message version 3`

---

### Task 3: 共享设置与面板同步

**Files:**
- Create: `Shared/SettingsStore.swift`、`DiceMessagesTests/SettingsStoreTests.swift`
- Modify: `Shared/PanelModel.swift`、`project.yml`（测试 target `sources` 加 `Shared/SettingsStore.swift`；`DiceApp` 与 `DiceMessages` 加 `entitlements`）
- Test: `DiceMessagesTests/{PanelModel,Screen,SpecStore}Tests.swift`

**Interfaces:**
- Consumes: Task 1、2
- Produces:
```swift
struct SettingsStore {
    static let appGroup = "group.dev.ansel.dice"
    static var shared: UserDefaults            // UserDefaults(suiteName: appGroup) ?? .standard
    init(defaults: UserDefaults = SettingsStore.shared)
    var criticalsEnabled: Bool { get nonmutating set }   // key "criticalsEnabled", default true
}
// PanelModel
init(store: SpecStore, settings: SettingsStore = SettingsStore())
func refreshSettings()                          // spec.criticalsEnabled = settings.criticalsEnabled
```
`didActivate()` 与 `roll(using:)` 内调用 `refreshSettings()`。

- [ ] **Step 1: 写失败测试**
  - `SettingsStoreTests.test_defaultsToEnabled`、`test_persists`：独立 suite，缺省 `true`；设为 `false` 后新建的 `SettingsStore(defaults:)` 读到 `false`
  - `PanelModelTests`（新测试都注入 `SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)`）：
    - `test_panel_rollUsesSettings`：设置为 `false` → `roll().spec.criticalsEnabled == false`
    - `test_panel_refreshSettingsUpdatesFormula`：设置改为 `false` 后 `refreshSettings()` → `RollFormatter.formula(model.spec)` 以 `"不判定大成功"` 或 `"No crits"` 结尾（按 `RollLanguage.current`，断言用 `RollFormatter.formula(RollSpec(criticalsEnabled: false))` 的后缀）
    - `test_panel_didActivateRefreshesSettings`：创建后把设置改为 `false`，`didActivate()` → `spec.criticalsEnabled == false`
    - `test_panel_settingOverridesStoredFlag`：`store.save(RollSpec(criticalsEnabled: false))`，设置为 `true` → 新 `PanelModel` 的 `spec.criticalsEnabled == true`
  - `ScreenTests.test_resolve_criticalsOffIgnoresReceiverSetting`：`v=3&c=0` 且 `[20]`、DC 25 的网址 → `.revealedBubble`，其 `result.critical == .none`、`dcOutcome == .failure`（`Screen` 不读设置）
  - `SpecStoreTests.test_specStore_persistsSpecOnly`：允许键加入 `"criticalsEnabled"`
- [ ] **Step 2:** `xcodegen generate`，扩展测试命令，预期编译失败
- [ ] **Step 3:** 实现 `SettingsStore`；`PanelModel` 注入并实现 `refreshSettings()`；`project.yml` 两个 target 加：
```yaml
    entitlements:
      path: DiceApp/DiceApp.entitlements        # DiceMessages: DiceMessages/DiceMessages.entitlements
      properties:
        com.apple.security.application-groups: [group.dev.ansel.dice]
```
- [ ] **Step 4:** `xcodegen generate`；扩展测试命令全部 PASS；`swift test --package-path DiceKit` 全部 PASS
- [ ] **Step 5:** 提交 `feat: shared critical setting through an App Group`

---

### Task 4: 设置页、使用说明与文档

**Files:**
- Create: `DiceApp/SettingsView.swift`
- Modify: `DiceApp/RollerView.swift`、`DiceApp/GuideView.swift`、`Shared/Localizable.xcstrings`、`README.md`、`README.zh-CN.md`、`docs/user-guide.md`、`docs/user-guide.zh-CN.md`、`docs/roadmap.md`、`docs/testflight/beta-info.md`

**Interfaces:**
- Consumes: Task 3（`SettingsStore`、`PanelModel.refreshSettings()`）

- [ ] **Step 1: `SettingsView`**：`NavigationStack` + `Form`；`Section("Rules")` 内 `Toggle("Critical Success & Failure", isOn:)` 绑定 `SettingsStore().criticalsEnabled`（`@State` 初值读取，`onChange` 写回）；`footer` 文案见 Step 4；标题 `Settings`，右上 `Done` 关闭
- [ ] **Step 2: `RollerView`**：工具栏在「?」旁加 `Button("Settings", systemImage: "gearshape")`；`.sheet(isPresented:onDismiss: { model.refreshSettings() })`
- [ ] **Step 3: `GuideView`**「Panel Tips」加一条 `Label("Turn critical success and failure on or off in Settings", systemImage: "gearshape")`
- [ ] **Step 4: 文案**（xcstrings，英文 → 中文）：`Settings` → 设置；`Rules` → 规则；`Critical Success & Failure` → 大成功 / 大失败判定；`On: a natural 20 or 1 is a critical success or failure and decides the DC. Off: only the total is compared with the DC. Rolls you send in Messages use your setting, and the formula shows it.` → `开：天然 20 / 1 为大成功 / 大失败，并决定 DC 成败。关：只用总值和 DC 比较。在「信息」里发出的投骰按你的设置判定，公式会标出。`；`Turn critical success and failure on or off in Settings` → `可在设置里开关大成功 / 大失败判定`
- [ ] **Step 5:** `xcodegen generate`；`swift test --package-path DiceKit`、扩展测试命令全部 PASS；`xcodebuild build ... $SIM` 成功
- [ ] **Step 6: 模拟器手工验收**（规格第 5 节 1–4 项）：设置页关 → App 投 `1d20 DC` 公式带标注、天然 20 不变色；「信息」扩展面板公式同样带标注并插入草稿；重新开启后两边恢复；深色、大字号下设置页正常
- [ ] **Step 7: 文档**：
  - README（中英）"消息格式"一节补版本选择规则：发送时选能表达消息的最低版本；凡会让旧版算出不同结果的改动都必须升版本；当前 `v=3`（判定关闭）
  - 使用指南（中英）：功能表加"设置"一行；"怎么看结果"与"谁能看到什么"补充判定关闭时的表现；版本说明加"判定关闭的投骰需要 0.6.0 及以上"
  - roadmap：已发布表加 0.6.0（构建号待定）；真机待验加"App Group 在 TestFlight 版中生效""0.5.x 收到判定关闭的消息提示更新"
  - `beta-info.md` 顶部新增 0.6.0「测试内容」（中英）
- [ ] **Step 8:** 提交 `feat(app): settings page with the critical toggle`
