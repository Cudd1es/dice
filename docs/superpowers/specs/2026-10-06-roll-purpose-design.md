# 投骰目的 — 设计文档

日期：2026-10-06
状态：待评审
前置：`2026-10-05-imessage-dice-design.md`（iMessage 扩展）、`2026-10-06-in-app-roller-design.md`（App 内投骰），均已实施

## 1. 目标与约束

**用户明确的需求**
- 投掷前由用户填写这次投骰的目的，例如「察觉检定：门后有没有人」
- App 内投骰和 iMessage 扩展都能填
- 投完自动清空，下次重新填

**设计决策（经确认）**
- 目的可选；不填时一切与现在相同
- 目的跟着骰子显示：iMessage 气泡（草稿和发送后）、结果详情、App 结果区与「最近」记录
- 输入框放在投骰面板最上方（否决了"弹窗询问"和"用「信息」自带注释"）
- 最长 40 个字符（按字形计，emoji 算 1 个）
- 消息格式版本不变，旧版 App 仍能显示结果，只是看不到目的
- 不做：保留上次目的、最近目的快捷填入、目的长期保存

**成功标准**
1. 两处都能填目的，投完清空
2. 填了目的的投骰，在所有显示结果的地方都能看到目的
3. 0.2.1 收到带目的的消息照常显示结果
4. 防重投不受影响：草稿与备用文字里仍没有结果

## 2. 数据与消息格式（`DiceKit`）

**`RollPurpose`**（新增，`public enum`）
- `public static let maxLength = 40`
- `public static func normalize(_ raw: String) -> String?`
  1. 换行（`\n`、`\r` 等 `isNewline` 字符）换成空格
  2. 去掉首尾空白
  3. 超过 `maxLength` 个 `Character` 时截断，截断后再去尾部空白
  4. 结果为空返回 `nil`

目的不放进 `RollSpec`：`RollSpec` 会被 `SpecStore` 保存为"上次的公式"并参与校验，目的投完就清空，生命周期不同。

**`MessageCodec`**
- `url(for spec: RollSpec, result: RollResult, purpose: String? = nil) -> URL`：`purpose` 经 `normalize` 后非空时追加查询字段 `p`（放在 `d` 之后）；否则网址与现在逐字节相同
- `decode(_:) -> (spec: RollSpec, result: RollResult, purpose: String?)`：读取 `p` 并 `normalize`；缺失或整理后为空即 `nil`。目的不会导致解码失败
- `currentVersion` 保持 `1`。0.2.1 的解码只取已知字段，未知的 `p` 被忽略
- 百分号编码由 `URLComponents` 处理（中文、`&`、`=`、`+`、`#`）

**`RollHistory`**
- `Entry` 新增 `public let purpose: String?`
- `add(spec:result:purpose:date:)`，`purpose` 默认 `nil`

**`RollFormatter`**
- `summary(_ spec: RollSpec, purpose: String? = nil, _ language: RollLanguage = .current)`：有目的时为 `🎲 察觉检定 · 1d20+5`，否则同现在

## 3. 界面

**输入框（`Shared/RollPanelView`）**
- 面板最上方，单行 `TextField`，占位文字 `Purpose (optional), e.g. Perception check`（中文：`目的（可选），如：察觉检定`）
- 输入时超过 40 字符即截断
- 回车键为「完成」（`.submitLabel(.done)`），按下只收起键盘
- `PanelModel` 新增 `@Published var purpose: String`（原始输入）
- `roll(using:)` / `roll()` 返回 `(spec, result, purpose: String?)`，`purpose` 为 `RollPurpose.normalize(self.purpose)`；返回前把 `self.purpose` 清空。`SpecStore` 只保存 `spec`

**扩展的键盘**
- 「信息」不允许扩展在紧凑（compact）样式下弹出键盘
- `RollPanelView` 新增可选回调 `onPurposeFocus: (() -> Void)?`；扩展传入 `requestPresentationStyle(.expanded)`。输入框获得焦点时调用；App 不传
- 需真机确认：紧凑样式下点输入框 → 切换到展开样式 → 键盘出现并保持焦点。若切换后焦点丢失，展开后再次设置焦点

**显示位置（有目的时；没有目的时与现在相同）**

| 位置 | 显示 |
|---|---|
| 草稿气泡（`BubbleView` pending） | 第一行目的（`.headline`，单行截断），下接公式、"发送后揭晓" |
| 发送后气泡（`BubbleView` revealed） | 第一行目的（`.headline`，单行截断），其余不变 |
| 结果详情 / App 结果区（`ResultCard`） | 公式上方显示目的（`.headline`，最多 2 行） |
| App「最近」记录（`HistoryRow`） | 原行不变，下加一行灰色小字目的（单行截断） |
| 备用布局（`MSMessageTemplateLayout`） | `caption` = 目的；`subcaption` = `公式 · 安装 DND Dice 查看结果` |
| `summaryText` | `🎲 察觉检定 · 1d20+5` |

**数据流经的类型**
- `Screen` 的 `.pendingBubble`、`.revealedBubble`、`.detail` 携带 `purpose: String?`，由 `Screen.resolve` 从解码结果取得
- `MessageFactory.makeMessage(spec:result:purpose:session:)`
- `ResultCard(spec:result:purpose:onRollAgain:)`，`purpose` 默认 `nil`

**新增文案**（英文为源，`Localizable.xcstrings` 提供 zh-Hans）
- `Purpose (optional), e.g. Perception check` → `目的（可选），如：察觉检定`

## 4. 兼容性与错误处理

| 发送方 | 接收方 | 效果 |
|---|---|---|
| 新版 | 0.2.1 | 结果正常，看不到目的 |
| 0.2.1 | 新版 | 无目的，显示同现在 |
| 新版 | 未安装 | 备用布局显示目的与公式，无结果 |

- 目的异常（过长、只有空白、含换行）一律经 `normalize` 整理，不会让消息变成"数据无效"
- 目的不是秘密，出现在草稿和备用布局中不影响防重投

## 5. 测试

**`DiceKit`（`swift test`）**
- `RollPurposeTests`：首尾空白；换行变空格；只有空白 → `nil`；正好 40 字保留；41 字截断为 40；emoji（含组合 emoji）按 1 字计
- `MessageCodecTests`：带目的往返；不带目的往返且网址与旧版相同；中文与 `& = + #` 往返；`p` 为空或超长时解码整理；没有 `p` 的旧网址解码得 `nil`
- `RollHistoryTests`：记录保存目的
- `RollFormatterTests`：`summary` 带 / 不带目的，中英文

**`DiceMessagesTests`**
- `PanelModelTests`：`roll()` 返回整理后的目的并清空 `purpose`；只有空白返回 `nil`；`SpecStore` 不保存目的
- `MessageFactoryTests`：带目的时网址含 `p`，备用布局与 `summaryText` 含目的且都不含结果
- `ScreenTests`：发送后的气泡与详情携带目的

**模拟器手工验收**
1. App：填目的 → 投掷 → 输入框清空；结果区与「最近」显示目的
2. App：不填目的投掷，显示同现在
3. 40 字上限；emoji 输入
4. iPhone SE、大字号、深色模式下面板与结果区完整

**真机验收（需用户协助）**
1. 扩展紧凑样式下点输入框 → 展开并弹出键盘
2. 草稿与发送后气泡显示目的；长目的单行截断
3. 0.2.1 设备收到带目的的消息，结果正常显示

## 6. 发布

- 版本 `0.3.0`（新功能，升次版本号），`scripts/release.sh 0.3.0`
- 更新 `docs/testflight/beta-info.md` 的「测试内容」与 README（删去"用「信息」注释说明投骰目的"那段，改为介绍目的输入框）
