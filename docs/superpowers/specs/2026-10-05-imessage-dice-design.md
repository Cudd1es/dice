# iMessage 骰子扩展 — 设计文档

日期：2026-10-05
状态：已实施（方案 A；见文末"实施记录"）

## 1. 目标与约束

**用户明确的需求**
- iMessage 扩展，投骰后消息插入输入框草稿（遵循 Apple 的"插入后由用户发送"逻辑）
- 草稿中**不显示**投骰结果
- 发送后，收发**双方**在聊天记录中直接看到结果
- 支持 DnD 5e / 博德之门风格：多枚、多面、优势/劣势、加值、DC 检定、大成功/大失败
- 使用场景：固定跑团群，所有成员都安装本 App
- 测试环境：目前没有真机，只用模拟器测试
- 隐藏结果的目的：防止发送者先看结果、不满意再重投
- 输入方式：按钮面板

**设计决策**
- 结果在插入草稿时即确定并写入消息，发送者从未看到结果，因此删除草稿重投无收益
- 防护级别为"防君子"：不做服务器或签名校验；懂技术的人能从消息 url 中读出结果，可接受
- 不做：文字表达式、保存常用投骰、kh/kl、混合表达式、重投规则、暴击伤害翻倍（均为后续版本候选）

**成功标准**
1. 草稿气泡只显示公式，不显示任何结果信息
2. 发送后，发送方与接收方气泡均自动显示同一结果，无需点击
3. 单聊与群聊均成立（模拟器只能验证单聊双方视角；群聊待有真机后验证）
4. `DiceKit` 单元测试全部通过

## 2. 方案选择

| 方案 | 做法 | 结论 |
|---|---|---|
| A | `MSMessageLiveLayout`，扩展自行渲染气泡；依据 `MSMessage.isPending` 决定显示公式还是结果 | **采用** |
| B | `MSMessageTemplateLayout` 气泡只写公式 +"点开查看"，结果在展开视图中显示 | **作为 A 的降级**（即 A 的 `alternateLayout`） |
| C | 草稿只带公式，渲染方以消息 ID 为种子现算 | 否决：发送前无稳定 ID，跨设备一致性无法保证 |

A 的关键行为 Apple 文档未明确说明，实施第一步为 spike（见第 7 节）。spike 失败则切换到 B，`DiceKit`、面板 UI、编解码均不变。

## 3. 架构

```
dice/
├─ DiceKit/                 本地 Swift Package（纯 Swift，无 UIKit）
│  ├─ RollSpec              投什么
│  ├─ DiceEngine            怎么投（RNG 可注入）
│  ├─ RollResult            投出了什么
│  ├─ MessageCodec          Spec+Result ⇄ URL query
│  └─ RollFormatter         展示文案
├─ DiceApp/                 宿主 App（仅一页使用说明）
└─ DiceMessages/            iMessage Extension（SwiftUI）
   ├─ MessagesViewController  按 presentationStyle 路由
   ├─ RollPanelView           投骰面板
   ├─ BubbleView              气泡（pending / revealed）
   └─ MessageFactory          组装 MSMessage
```

各单元职责：
- **`RollSpec`**：`count`、`sides`、`mode`（normal / advantage / disadvantage）、`modifier`、`dc?`。提供 `validate()` 校验范围
- **`DiceEngine`**：`roll(_ spec: RollSpec, using rng: inout some RandomNumberGenerator) -> RollResult`。正式环境用 `SystemRandomNumberGenerator`，测试用固定种子 RNG
- **`RollResult`**：`dice: [Int]`（全部掷出值）、`keptIndices`、`total`、`critical`（none / success / failure）、`dcOutcome?`（success / failure）
- **`MessageCodec`**：`encode(spec, result) -> [URLQueryItem]`，`decode(URL) throws -> (RollSpec, RollResult)`；含版本号 `v=1`；解码时重新校验所有数值并验证 `total` 与骰子明细一致
- **`RollFormatter`**：`formula(spec)` →「1d20+5 · 优势 · DC 15」；`detail(result)` →「[17, ~~8~~] + 5 = 22」；`outcome(result)` →「成功 / 失败 / 大成功 / 大失败」
- **`MessagesViewController`**：`.compact` / `.expanded` 且无选中已发送消息 → 面板；`.transcript` → `BubbleView`；`.expanded` 且选中已发送消息 → 结果详情
- **`MessageFactory`**：生成 `MSMessage`：`url` = 编码结果；`layout` = `MSMessageLiveLayout(alternateLayout:)`，`alternateLayout` 为 `MSMessageTemplateLayout`（caption = 公式，subcaption =「点开查看结果」）；`summaryText` 只含公式

## 4. 数据流

1. 用户在面板设置并点「投掷」
2. `DiceEngine` 立即掷出 → `MessageCodec` 编入 url → `MessageFactory` 生成消息
3. `activeConversation.insert(message)` 插入草稿；面板收起，**界面全程不显示结果**
4. 草稿气泡：`BubbleView` 读到 `isPending == true` → 只画公式 +「发送后揭晓」
5. 用户点发送 → 双方 `BubbleView` 读到 `isPending == false` → 画出结果
6. 面板记住上次的 `RollSpec`（`UserDefaults`，只存公式不存结果）

## 5. 骰子规则

- 面数：d4 / d6 / d8 / d10 / d12 / d20 / d100
- 数量：1–20
- 加值：-20 … +20，加在总和上
- 优势/劣势：仅当 `count == 1 && sides == 20` 可用；掷 2d20 取高/取低。其它情况 UI 置灰，`validate()` 拒绝
- 大成功/大失败：仅当 `count == 1 && sides == 20`；被采用的 d20 为 20 → 大成功，为 1 → 大失败
- DC：可选，1–40；`total >= dc` 为成功。**博德之门规则：天然 20 必定成功，天然 1 必定失败**

## 6. 界面

**面板（compact）**
- 行 1：面数按钮（横向滚动）
- 行 2：数量 `− n +`、加值 `− ±m +`
- 行 3：`劣势 | 普通 | 优势`；DC 开关 + 数值
- 公式预览 + 大号「投掷」按钮

**气泡**
- pending：🎲 + 公式 +「发送后揭晓」
- revealed：大字总值；明细行（优势/劣势被弃骰子划线）；DC 成败；大成功金色、大失败红色
- 点开已发送气泡：展开视图显示完整明细

## 7. Spike（实施第一步）

在模拟器「信息」App 上验证（它内置两个模拟会话方，可分别以发送方、接收方视角查看）：
1. 草稿中的 Live Layout 由扩展渲染，且 `isPending == true`
2. 发送后，发送方自己的气泡自动重新渲染为结果（`isPending == false`）
3. 接收方直接看到结果

任一不成立 → 切换方案 B：气泡固定为 template layout，结果仅在展开视图中显示（仅限 `isPending == false` 的消息）。spike 代码不保留。

## 8. 错误处理

- url 解析失败 / 未知版本 → 气泡显示「无法读取这次投骰，请更新 App」
- 数值越界或 `total` 与明细不符 → 显示「数据无效」，不显示结果
- `insert` 回调返回错误 → 面板提示，可重试

## 9. 测试

- **`DiceKit` 单元测试（`swift test`）**
  - 固定种子 → 结果可复现
  - 每种面数 10 万次：取值在 `1...sides`，分布大致均匀
  - 优势取高、劣势取低，`keptIndices` 正确
  - 大成功/大失败只在 1d20 判定
  - DC：普通成败、边界值（`total == dc`）、天然 20 低于 DC 仍成功、天然 1 高于 DC 仍失败
  - 编解码往返；缺字段、错版本、越界、`total` 不一致 → 抛错
  - 文案格式
- **UI**：SwiftUI Preview 覆盖 pending / 普通 / 大成功 / 大失败 / DC 成功 / DC 失败 / 错误态
- **手工验收**：在模拟器「信息」App 中以发送方、接收方两个视角收发，逐条核对第 1 节成功标准
- **后续**：有真机后补做真机 + 群聊验收

## 10. 开放风险

- Live Layout 行为依赖 iOS 版本，spike 结论需记录测试的 iOS 版本
- 只在模拟器测试：模拟器的「信息」App 不走真实 iMessage 网络，Live Layout 在真机上的渲染时机可能不同；spike 结论在有真机前视为暂定，方案 B 的降级路径保留
- 最低系统版本暂定 iOS 17（SwiftUI 与 Messages 框架均稳定），实施时可调整

## 实施记录（2026-10-05）

- 模拟器 spike 不成立，先按方案 B 实现；真机 spike 证明方案 A 在发送方成立，随后切换到 A。
  见 `docs/superpowers/spikes/2026-10-05-live-layout.md`。
- 消息 URL 用 `https://dice.invalid/roll?v=1&…`：「信息」会丢弃自定义 scheme 的 URL。
- `alternateLayout` 的副标题为「安装「骰子」App 查看结果」，给没装 App 的人看，不含结果。
- 第 3 节"`.expanded` 且选中已发送消息 → 结果详情"仍保留，用于方案 B 时期发出的旧消息：
  只有刚点开时才显示（由 `RevealState` 判断），显示为全屏居中的结果卡片，带「再投一次」。
- 「信息」重新创建滑出屏幕的气泡时，`willBecomeActive` 里 `activeConversation` 仍为 nil，
  必须使用回调参数里的 `conversation`。
- 成功标准 2、3 的接收方与群聊部分待 TestFlight 分发后验收。
