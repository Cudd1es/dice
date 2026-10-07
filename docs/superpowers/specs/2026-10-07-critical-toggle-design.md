# 大成功 / 大失败判定开关 — 设计文档

日期：2026-10-07
状态：待评审
前置：`2026-10-05-imessage-dice-design.md`、`2026-10-06-bonus-dice-design.md`（均已实施）

## 1. 目标与约束

**用户明确的需求**
- 不同用户（或跑团）有不同的规则，需要一个开关开启 / 关闭大成功、大失败的判定
- 这是个人房规设置，设好后很少改；不是每次投骰临时决定

**设计决策（经确认）**
- 两档：开（现在的行为，默认）/ 关（不判定大成功、大失败，DC 只按总值比较）。否决三档和按投骰类型分别设置
- 开关放在 App 的设置页，「信息」扩展读同一个设置（App Group）；扩展里不放开关
- 「信息」中的投骰按**发送者**的设置判定，并写进消息，所有人看到同一个结果
- 消息格式：只在判定关闭且主骰为单个 d20 时写 `c=0` 并升到 `v=3`（否决"不升版本"和"所有消息都升版本"）

**参考**：2024 规则（SRD 5.2.1）中，天然 20 / 1 必定命中 / 未命中只适用于攻击检定；属性检定和豁免检定不自动成败。是否沿用本 App 现有的"全部判定"由用户的设置决定。

**成功标准**
1. App 设置页可开关判定，App 与扩展都按该设置投骰，无需重启
2. 判定关闭时：天然 20 / 1 不显示大成功 / 大失败，DC 按总值判定，公式标出"不判定大成功"
3. 判定开着时，一切与现在完全相同（包括消息网址）
4. 0.5.x 收到判定关闭的消息时显示"请更新 App"，不会显示与发送者不同的结果

## 2. 规则与数据（`DiceKit`）

**`RollSpec`**
- 新增 `public var criticalsEnabled: Bool`，默认 `true`；`init` 参数 `criticalsEnabled: Bool = true` 放在 `extras` 之后
- `init(from:)` 用 `decodeIfPresent ?? true`，旧的存储数据读作开启
- 不参与 `validate()`

**`DiceEngine.evaluate`**
- 大成功 / 大失败条件改为 `spec.isSingleD20 && spec.criticalsEnabled`
- 关闭时 `critical == .none`，`dcOutcome` 按 `total >= dc` 判定（天然 20 也可能失败，天然 1 也可能成功）
- 优势 / 劣势、加成骰不受影响；总值颜色因 `critical == .none` 自然为普通颜色

**`RollFormatter.formula`**
- `!spec.criticalsEnabled && spec.isSingleD20` 时，在 DC 之后追加 ` · 不判定大成功`（英文 ` · No crits`），例如 `1d20+5 · 优势 · DC 15 · 不判定大成功`
- 主骰不是单个 d20 时不追加

## 3. 消息格式（`MessageCodec`）

**编码：选能表达这条消息的最低版本**

| 情况 | 版本 | 新字段 |
|---|---|---|
| 判定开，无加成骰 | `v=1`（与现在逐字节相同） | — |
| 判定开，有加成骰 | `v=2`（与现在逐字节相同） | — |
| 判定关且主骰为单个 d20（有无加成骰均可） | `v=3` | `c=0`，放在 `x` 之后、`d` 之前 |
| 判定关但主骰不是单个 d20 | 同前两行 | 不写 `c` |

**解码**
- `currentVersion = 3`；接受 `v ∈ 1...3`
- `v=3`：`c=0` → `criticalsEnabled = false`；缺少 `c` → `true`；其他值 → `malformed("c")`
- `v=1`、`v=2` 忽略 `c`
- 0.5.x 遇到 `v=3` 走已有的 `needsUpdate` 分支

| 发送方 | 接收方 | 效果 |
|---|---|---|
| 新版，判定开 | 0.5.x | 正常，结果一致 |
| 新版，判定关、主骰 d20 | 0.5.x | 请更新 App |
| 0.5.x | 新版 | 正常（按判定开，与发送者一致） |
| 新版，判定关 | 未安装 | 备用布局公式带"· 不判定大成功" |

**README**：补充版本选择规则——发送时选能表达消息的最低版本；凡是会让旧版算出不同结果的改动都必须升版本。

## 4. 设置与界面

**App Group 与 `SettingsStore`**
- App 与扩展加入 App Group `group.dev.ansel.dice`（`project.yml` 中两个 target 的 entitlements）
- `Shared/SettingsStore.swift`：`struct SettingsStore`，`init(defaults: UserDefaults = SettingsStore.shared)`；`var criticalsEnabled: Bool`（键 `criticalsEnabled`，缺省 `true`）。`shared` 为 `UserDefaults(suiteName: "group.dev.ansel.dice") ?? .standard`，共享存储不可用时退回本地，不崩溃
- 首次配置需要在开发者账号登记 App Group；`release.sh` 的自动签名（`-allowProvisioningUpdates`）通常会处理，若失败列出需要用户在网页上完成的步骤。CI 不签名，不受影响

**App 设置页（`DiceApp/SettingsView.swift`）**
- 导航栏右上角「?」旁加齿轮按钮，sheet 打开设置页，右上角「完成」
- `Form` 中一个 `Toggle("Critical Success & Failure")`（中文「大成功 / 大失败判定」），说明文字：开——天然 20 / 1 显示大成功 / 大失败并决定 DC 成败；关——DC 只按总值比较。在「信息」里发出的投骰按你的设置判定，公式会标出

**`PanelModel`**
- `init(store: SpecStore, settings: SettingsStore = SettingsStore())`
- `func refreshSettings()`：把 `settings.criticalsEnabled` 写入 `spec.criticalsEnabled`；在 `init`、`didActivate()`、App 关闭设置页时调用
- `roll(using:)` 投掷前再调用一次 `refreshSettings()`，保证以投掷时的设置为准
- 面板公式行通过 `RollFormatter.formula` 自然显示"· 不判定大成功"

**其他**
- App 内使用说明「面板小技巧」新增一条：可在设置中关闭大成功 / 大失败判定
- 使用指南（中英）、快速上手不变、README（中英）、`beta-info.md` 0.6.0「测试内容」同步更新

**新增文案**（英文为源，zh-Hans）
- `Settings` → 设置；`Rules` → 规则；`Critical Success & Failure` → 大成功 / 大失败判定；`No crits`（公式内，由 `RollFormatter` 直接给出中英文）；设置说明与使用说明各一条

## 5. 测试

**`DiceKit`**
- `DiceEngine`：关闭时天然 20 对 DC 30 → 失败、天然 1 对 DC 1 → 成功、`critical == .none`；开启时与现有测试一致；关闭 + 优势取高不变
- `RollSpec`：缺 `criticalsEnabled` 的旧 JSON 解码为 `true`；JSON 往返
- `RollFormatter`：关闭且主骰 d20 时公式带"· 不判定大成功" / "· No crits"；主骰非 d20 时不带
- `MessageCodec`：开启时网址与现有逐字节相同；`v=3&c=0` 往返（有 / 无加成骰、带目的）；主骰非 d20 时不写 `c`；`v=3` 中 `c` 为其他值 → `malformed("c")`；`v=4` → `unsupportedVersion(4)`；`v=2` 带 `c` 时忽略

**`DiceMessagesTests`**
- `SettingsStore`：缺省为 `true`；写入后读出（独立 `UserDefaults` suite）
- `PanelModel`：设置为关时 `roll()` 的 `spec.criticalsEnabled == false`；修改设置后 `refreshSettings()` 使 `spec` 与公式随之变化
- `ScreenTests`：`v=3&c=0` 的网址解码出关闭判定的气泡

**模拟器手工验收**
1. App 设置页关闭判定 → App 投 1d20 DC：公式带"不判定大成功"
2. 打开「信息」扩展：面板公式同样带该标注；投掷插入草稿
3. 重新开启判定：两边恢复
4. 深色模式、大字号下设置页正常

**真机验收（需用户协助）**
1. 判定关闭的气泡与详情显示正确
2. 0.5.x 收到判定关闭的消息显示"请更新 App"
3. App Group 在 TestFlight 版本中生效（App 中改设置，「信息」中立即生效）

## 6. 发布

- 版本 `0.6.0`，`scripts/release.sh 0.6.0`
- 更新 `docs/testflight/beta-info.md`、使用指南、README、roadmap
