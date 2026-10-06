# App 内投骰 — 设计文档

日期：2026-10-06
状态：已实施（见文末"实施记录"）
前置：`docs/superpowers/specs/2026-10-05-imessage-dice-design.md`（iMessage 扩展，已实施）

## 1. 目标与约束

**用户明确的需求**
- 宿主 App 本身也能投骰：和 iMessage 扩展一样设好骰子，点「投掷」，结果直接显示在主页
- 使用场景：线下跑团，把 App 当实体骰子用。重点是投得快、结果醒目、方便给旁边的人看
- 主页保留最近约 10 次投骰记录，关掉 App 后清空

**设计决策（经确认）**
- 规则、面板与 iMessage 扩展完全相同（面数、数量、加值、优势/劣势、DC、大成功/大失败）
- 主页就是投骰界面；现有使用说明移到右上角「?」按钮
- App 与扩展各自记住上次的公式，不配置 App Group
- 不做防重投、不隐藏结果（线下场景不需要）
- 不做：点记录回放、长期保存记录、音效、动画骰子（后续候选）

**成功标准**
1. 打开 App 即可投骰，结果大字显示，带明细与成败
2. 最近 10 次记录可回看，新的在前；关掉 App 后清空
3. iMessage 扩展行为不变，现有测试全部通过

## 2. 方案

采用"共享源文件"：把面板相关代码移到 `Shared/`，宿主 App 与扩展都编译它。

否决的方案：
- 在 `DiceKit` 里新建 SwiftUI 库 `DiceUI`：边界更清楚，但要拆包并维持 `DiceKit` 只依赖 Foundation 的约束；目前只有两个使用方，不值得
- 复制面板代码到 App：两份代码会走样

## 3. 架构

```
dice/
├─ DiceKit/                  纯 Swift 包
│  └─ RollHistory            新增：最近记录（内存，容量 10）
├─ Shared/                   新增目录，DiceApp / DiceMessages / DiceMessagesTests 共同编译
│  ├─ PanelModel             从 DiceMessages 移入；去掉 Messages 依赖
│  ├─ SpecStore              从 DiceMessages 移入，不变
│  ├─ RollPanelView          从 DiceMessages 移入，不变
│  └─ ResultCard             从 DiceMessages 移入，不变（含 RollResult 配色扩展）
├─ DiceApp/
│  ├─ DiceApp                入口改为 RollerView
│  ├─ RollerView             新增：主页（结果区 + 记录 + 面板）
│  └─ GuideView              新增：原 ContentView 的使用说明
└─ DiceMessages/             其余文件不变；MessagesViewController 改为自行组装消息
```

文件用 `git mv` 移动以保留历史。

**接口变化**
- `PanelModel`
  - 删除 `func makeRoll() -> MSMessage`
  - 新增 `func roll<G: RandomNumberGenerator>(using rng: inout G) -> (spec: RollSpec, result: RollResult)`：
    用当前 `spec` 掷骰，保存公式到 `SpecStore`，返回公式与结果
  - 新增 `func roll() -> (spec: RollSpec, result: RollResult)`：使用 `SystemRandomNumberGenerator`
  - 不再 `import Messages`
- `MessagesViewController.roll()`：`let (spec, result) = model.roll()`，
  再 `MessageFactory.makeMessage(spec: spec, result: result, session: nil)` 插入草稿
- `RollHistory`（`DiceKit`，`public struct`，`Equatable`）
  - `public struct Entry: Equatable, Identifiable { id: UUID; spec: RollSpec; result: RollResult; date: Date }`
  - `public static let capacity = 10`
  - `public private(set) var entries: [Entry]`（新的在前）
  - `public init()`
  - `public mutating func add(spec: RollSpec, result: RollResult, date: Date = Date())`：插到最前，超出容量丢弃最旧

## 4. 界面

**主页（竖屏，从上到下）**
1. 导航栏：标题「骰子」，右侧「?」按钮打开 `GuideView`（sheet）
2. 结果区（固定高度约 220pt）
   - 未投过：灰字「选好骰子，点「投掷」」
   - 已投：`ResultCard(spec:result:onRollAgain: nil)`——公式小字、总值大字、明细、成败徽章
3. 「最近」记录列表（占剩余空间，可滚动）：每行 `HH:mm · 公式 · 总值 · 成败`，成败按 `outcomeColor` 着色；不可点击
4. 投骰面板：`RollPanelView`，与扩展相同

**投掷反馈**（连续投出相同数字时也能看出投过）
- 总值数字使用 `.contentTransition(.numericText())` 动画
- 触觉反馈：大成功 → success，大失败 → error，其余 → 轻 impact

**其它**
- 深色模式可读；配色与 iMessage 气泡一致（大成功橙、大失败红、DC 成功绿）
- 小屏（iPhone SE）上结果区与面板完整显示，记录区变矮但可滚动

## 5. 数据流

1. 用户在面板调整公式（`PanelModel` 每次修改后 `normalized()`）
2. 点「投掷」→ `model.roll()` → 返回 `(spec, result)`，同时保存公式
3. `RollerView` 把结果放进结果区，并 `history.add(spec:result:)`
4. 触发数字动画与触觉反馈

`RollHistory` 由 `RollerView` 以 `@State` 持有，只在内存中，App 进程结束即清空。

## 6. 错误处理

- 存储的公式无法解码或不合法 → `SpecStore` 退回 `RollSpec()`（现有行为）
- 投骰不会失败：面板保证公式合法，App 内无网络与消息插入，因此不显示错误提示

## 7. 测试

- **`DiceKit`（`swift test`）新增 `RollHistoryTests`**
  - 新记录在最前
  - 第 11 条加入后只剩 10 条，最旧的被丢弃
  - 记录保留传入的 spec、result、date
- **`DiceMessagesTests`**
  - `test_panel_makeRollSavesSpec` → `test_panel_rollSavesSpec`
  - `test_panel_makeRollMessageDecodes` → `test_panel_rollIsReproducibleWithSeed`（同种子两次 `roll(using:)` 结果相同，且返回的 spec 等于 `model.spec`）
  - `MessageFactoryTests` 不变，继续保证扩展消息不含结果
- **模拟器手工验收**
  1. 打开 App 即投骰界面，未投时有提示
  2. 1d20+5 优势 DC 15：结果区显示公式、总值、明细、成败；记录 +1
  3. 连投 12 次：只保留最新 10 条，新的在最上
  4. 投出相同数字时能看出又投了一次
  5. 关掉 App 再打开：记录清空，面板保留上次公式
  6. 「?」打开使用说明
  7. 深色模式、iPhone SE 布局正常
  8. iMessage 扩展面板与插入照常（气泡在真机上复核）

## 实施记录（2026-10-06）

与本文设计的偏离，均为模拟器验收或整体审查中发现：
- 结果区高度：不是固定 220pt，而是"最多 220pt、约占可用高度 30%"；低于 200pt 时总值字号改为 52。原因：iPhone SE 上固定 220pt 会把记录区挤到 0 行
- iPhone 版锁定竖屏；横屏高度放不下面板
- 投骰面板放不下时可滚动；辅助功能字号下数量/加值上下排列；主页字号封顶 accessibility2
- `ResultCard` 收紧间距（6pt）与上下留白（8pt），并新增 `totalFontSize` 参数和 `.numericText()` 数字过渡；扩展的结果卡片共用这些改动
- 记录时间用 `RollFormatter.clockTime`，固定 24 小时制 `HH:mm`（设备设为 12 小时制时也不变）
- 面板标签不折行（`.fixedSize()`），SE 上「数量」原本竖排

待真机确认：震动反馈手感；扩展面板在「信息」中的布局。

