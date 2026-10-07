# 加成骰（骰子组合）— 设计文档

日期：2026-10-06
状态：已实施（0.4.0，PR #10；见文末"实施记录"）
前置：`2026-10-05-imessage-dice-design.md`、`2026-10-06-in-app-roller-design.md`、`2026-10-06-roll-purpose-design.md`（均已实施）

## 1. 目标与约束

**用户明确的需求**
- 支持骰子组合，例如 `1d20+1d4`（祝福术、神导术）、`1d20-1d4`（灾祸术）、`1d8+2d6+3`（伤害组合）
- 这一版先让程序具备组合能力；"祝福术"等常用预设以后再加
- 主面板多一个「加成」键，进入二级菜单选择加成骰，选完自动返回

**设计决策（经确认）**
- 主面板的那组骰子是"主骰"；加成骰是额外的若干组，计入总值
- 优势/劣势、大成功/大失败只看主骰（主骰为 1d20 时生效），与现在相同
- 加值（−20…+20）留在主面板
- 同种加成骰合并（+1d4 再加 +1d4 → +2d4）；主面板的加成骰标签点开菜单可「多一个 / 少一个 / 删除」
- 二级菜单选一个骰子即自动返回（否决"选好后点完成返回"：常见情况多一步，且以后的预设点一下就该完成）
- 数据方案：在 `RollSpec` 上加加成骰列表（否决"通用表达式重写"和"加成骰不计入总值"）
- 不做：预设、加成骰的优势/劣势、加成骰的大成功、`2d20 取高` 等玩法

**成功标准**
1. App 与扩展都能投 `1d20+1d4+5`（含优势、DC）、`1d20-1d4`、`1d8+2d6+3`，总值与明细正确
2. 没有加成骰的投骰与消息与现在完全相同
3. 0.3.x 收到带加成骰的消息显示"请更新 App"，而不是"数据无效"或错误结果
4. 防重投不受影响

## 2. 数据与规则（`DiceKit`）

**`BonusDice`**（新增，`public struct`，`Codable, Equatable, Hashable, Sendable`）
- `public enum Sign: String, Codable { case plus, minus }`
- `sign: Sign`、`count: Int`、`sides: Int`
- `public static let countRange = 1...10`
- `public static let allowedSides = [4, 6, 8, 10, 12, 20, 100]`

**`RollSpec`**
- 新增 `public var extras: [BonusDice]`，默认 `[]`，位于 `modifier` 之后
- `public static let maxExtras = 4`
- `Codable` 改为手写 `init(from:)`：缺少 `extras` 键时为 `[]`，保证 `SpecStore` 中已存的旧公式可读
- `validate()` 新增：`extras.count <= 4`；每组 `count` 在 1…10、`sides` 在允许面数内；同一 `(sign, sides)` 不得重复出现 → 新错误 `RollSpecError.invalidExtras`
- `mutating func addBonus(sign:sides:)`：已有同 `(sign, sides)` 则 `count + 1`（上限 10），否则追加新组；已有 4 组且需要新组时不变
- `diceToRoll` 含义不变（只算主骰）；新增 `var totalDiceCount: Int`（主骰 + 所有加成骰），供编解码校验
- `isSingleD20`、`normalized()` 只看主骰，与 `extras` 无关

**`RollResult`**
- 新增 `public let bonusRolls: [[Int]]`，与 `spec.extras` 一一对应；无加成骰时为 `[]`
- `dice`、`keptIndices` 含义不变（只含主骰）

**`DiceEngine`**
- `roll`：先投主骰，再按 `extras` 顺序投每组
- `evaluate(_ spec:, dice:, bonusRolls: [[Int]] = [])`：
  `total = 主骰保留点数之和 + Σ(plus 组之和) − Σ(minus 组之和) + modifier`
- 大成功/大失败只由主骰 d20 决定；天然 20 必成功、天然 1 必失败的 DC 规则不变
- 总值可为负数或 0，照实显示

**`RollFormatter`**
- `formula`：主骰 → 加成骰 → 加值，例如 `1d20+1d4+5 · 优势 · DC 15`、`1d20-1d4`、`1d8+2d6+3`
- `detailMarkdown`：主骰明细后依次接 ` + [3]` 或 ` - [2, 5]`，再接加值，例如 `[17, ~~8~~] + [3] + 5 = 25`

## 3. 消息格式（`MessageCodec`）

- 无加成骰：网址与现在逐字节相同，`v=1`
- 有加成骰：`v=2`，新增字段 `x`，逗号分隔各组：正号省略、负号写 `-`，例如 `x=1d4,-2d6`
- 骰点仍全部放在 `d`：先主骰（`diceToRoll` 个），再按 `x` 顺序放每组的 `count` 个
- `currentVersion = 2`；解码接受 1 和 2；`v=1` 时忽略 `x`
- 解码重新计算总值；骰点个数不等于 `totalDiceCount` 或点数越界 → `invalidDice`；`x` 无法解析 → `malformed("x")`；`extras` 不合法 → `invalidSpec`
- 目的字段 `p` 在两个版本中都可出现
- 0.3.x 的 `currentVersion = 1`，遇到 `v=2` 走已有的 `needsUpdate` 分支，显示"无法读取这次投骰，请更新 App"

| 发送方 | 接收方 | 效果 |
|---|---|---|
| 新版，无加成骰 | 0.3.x | 正常 |
| 新版，有加成骰 | 0.3.x | 请更新 App |
| 0.3.x | 新版 | 正常 |
| 新版，有加成骰 | 未安装 | 备用布局显示完整公式与安装提示 |

## 4. 界面（`Shared/RollPanelView`，App 与扩展共用）

**主面板**
- "数量 / 加值"之下新增"加成"行：已有加成骰的标签（`+1d4`、`−2d6`，样式同面数按钮）依次排列，末尾「＋ 加成」按钮；行内容超宽时横向滚动
- 标签是 `Menu`：「多一个」（到 10 个时禁用）、「少一个」（只剩 1 个时即删除）、「删除」
- 面板多一行（约 40pt）；放不下时沿用现有的滚动

**二级菜单（`BonusPickerView`）**
- 在面板内原地切换（`PanelModel` 持有 `isPickingBonus`），带滑入过渡；不使用导航推入，App 与扩展表现一致
- 内容：左上「‹ 返回」；「加 / 减」分段控件（默认加，每次进入重置为加）；d4–d100 按钮，点击即 `addBonus` 并返回
- 已有 4 组时，会产生新组的按钮禁用；已有种类仍可点（合并）
- 下方留空，以后放预设

**`PanelModel`**
- `addBonus(sign:sides:)`、`incrementBonus(at:)`、`decrementBonus(at:)`、`removeBonus(at:)`，都经 `update` 保存并 `normalized()`
- 加成骰是公式的一部分，随 `SpecStore` 保存

**其他显示**：公式行、结果卡片、气泡、App「最近」记录都用新的 `formula`；明细超长时自动换行

**新增文案**（英文为源，zh-Hans 翻译）
- `Bonus` → 加成；`Add` → 加；`Subtract` → 减；`One More` → 多一个；`One Fewer` → 少一个；`Remove` → 删除；`Back` → 返回；`Bonus Dice` → 加成骰（二级菜单标题）

## 5. 测试

**`DiceKit`**
- `BonusDice` / `RollSpec`：合并、count 上限 10、4 组上限、`validate` 各错误、缺 `extras` 键的旧 JSON 可解码
- `DiceEngine`：总值（含减号组、负数总值）、有加成骰时的优势取高与大成功、DC 判定、同种子可复现
- `RollFormatter`：公式与明细，中英文
- `MessageCodec`：无加成骰网址与旧格式逐字节相同；单组、多组含减号、与目的同时存在的往返；骰点个数或范围错误 → 无效；`x` 格式错误 → `malformed`；`v=3` → `unsupportedVersion`；`v=1` 带 `x` 时忽略

**`DiceMessagesTests`**
- `PanelModel`：添加/合并/上限/多一个/少一个/删除；加成骰随公式保存；`isPickingBonus` 在添加后为 false
- `Screen`：`v=2` 网址解码为带加成骰的气泡与详情
- `MessageFactory`：带加成骰时备用布局与 `summaryText` 显示完整公式且不含结果

**模拟器手工验收**
1. App：`1d20+1d4+5` 优势 DC 15、`1d20-1d4`、`1d8+2d6+3` 各投一次，总值与明细正确
2. 二级菜单选完自动返回；「‹ 返回」不加任何骰子
3. 标签菜单多一个 / 少一个 / 删除；到 4 组后新种类禁用
4. 扩展：同样操作并插入草稿
5. 小屏、大字号、深色模式

**真机验收（需用户协助）**
1. 带加成骰的气泡与详情显示正常
2. 0.3.x 收到带加成骰的消息显示"请更新 App"

## 6. 发布

- 版本 `0.4.0`（新功能），`scripts/release.sh 0.4.0`
- 更新 `docs/testflight/beta-info.md`「测试内容」与 README（功能列表加入加成骰；提醒更新，旧版无法读取带加成骰的消息）

## 实施记录（2026-10-06）

与本文设计的偏离：
- `RollSpec.init` 的 `extras:` 参数放在最后（`dc` 之后），不在 `modifier` 与 `dc` 之间：计划中所有调用都这样写，Swift 要求参数顺序与声明一致
- 第 4 节"都经 `update` 保存"措辞不准：加成骰与其他公式字段一样，在投掷时由 `SpecStore` 保存
- 原有把 `v=2` 当作"未来版本"的测试改为 `v=3`；`SpecStore` 存储键允许 `extras`
- 「投掷」按钮固定在可滚动面板下方：多了加成行后，扩展紧凑样式里按钮只露出一半（整体审查发现）。代价是紧凑样式里 DC 与公式行需要上滑查看

- 0.5.0：二级菜单加入 SRD 5.2.1 预设（检定：祝福术、神导术、灾祸术、诗人激励 d6–d12；伤害：猎人印记、脆弱诅咒、神恩术、至圣斩），`RollSpec.addBonus` 支持一次加多个
- 0.5.1：按用户要求，加成骰改为只用于一次投骰——投掷后清空、不再随公式保存，读取旧版存下的公式时也清掉（推翻第 2 节"随 `SpecStore` 保存"）；二级菜单按钮改用强调色底，在「信息」小窗口里更醒目

暂缓的次要问题见 `docs/roadmap.md`。
