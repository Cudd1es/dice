# DND Dice

[English](README.md)

给 DnD 5e / 博德之门风格跑团用的骰子：可以在「信息」对话里直接投，也可以线下围着桌子时打开 App 投。界面支持英文和简体中文，跟随系统语言。

- **玩家：**[快速上手](docs/quick-start.zh-CN.md) · [使用指南](docs/user-guide.zh-CN.md)
- **开发者：**往下看。

## 功能

- d4 / d6 / d8 / d10 / d12 / d20 / d100，1–20 枚，加值 −20…+20
- 单个 d20 的优势 / 劣势、大成功 / 大失败
- 可选 DC（1–999），可以加减，也可以直接输入；天然 20 必定成功、天然 1 必定失败（设置中关闭判定时除外）
- **加成骰：**在主骰之外最多加 4 组，每组 1–10 个 d4–d100，可加可减。例如祝福术 `1d20+1d4`、灾祸术 `1d20-1d4`、伤害 `1d8+2d6+3`。优势和大成功只看主骰
- **加成预设：**按 2024 年规则（SRD 5.2.1）整理：祝福术、神导术、灾祸术、诗人激励（d6–d12）、猎人印记、脆弱诅咒、神恩术、至圣斩
- **大成功判定设置：**房规不用大成功 / 大失败的团，可以在设置里关掉。关掉后只用总值和 DC 比较，公式里会标出"不判定大成功"。App 和「信息」共用这个设置（App Group）
- **目的：**可选的一句话，最多 40 字，例如「察觉检定：门后有没有人」。它跟着这次投骰一起显示，投完自动清空
- **在 App 里投：**结果大字显示，下面保留最近 10 次记录，关掉 App 后清空
- **在「信息」里投：**
  - 点「投掷」时结果就已确定，但发送前谁都看不到；
  - 发出后，气泡对所有人显示结果。

## 怎么防止"不满意就重投"

1. 点「投掷」时结果就已确定，并写进消息。
2. 面板和草稿气泡上都只显示公式，例如「1d20+5 · 优势 · DC 15 / 发送后揭晓」。
3. 消息发出后，气泡自动显示总值、明细和成败，不用点开。

发送者在发送前看不到结果，所以删掉草稿重投没有意义。

**没装 DND Dice 的人**只会看到公式和「安装 DND Dice 查看结果」，同样看不到结果。

**显示语言：**
- 气泡由收消息的人自己手机上的 App 绘制，所以每个人看到的都是自己系统语言的文字；
- 草稿和备用文字用的是发送方的语言。

**这是"防君子"级别的防护：**结果以明文写在消息网址里，懂技术的人能读出来。

## 构建与运行

需要：
- Xcode 16 及以上（开发时用的是 Xcode 26.2）；
- iOS 17 及以上的模拟器或真机；
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)。

```bash
brew install xcodegen
```

`.xcodeproj` 不入库，由 `project.yml` 生成：

```bash
xcodegen generate
```

```bash
open Dice.xcodeproj
```

运行 `DiceApp` scheme。

- **在 App 里投：**App 打开就是投骰界面。
- **在「信息」里投：**进入任意对话，点输入框左边的 **+**，选 DND Dice。

> **气泡只能在真机上测试。**模拟器上的「信息」不让气泡读取自己的消息，气泡会是空的，详见 [spike 记录](docs/superpowers/spikes/2026-10-05-live-layout.md)。投骰面板和单元测试在模拟器上都没问题。

## 测试

规则、消息格式和文案都在 Swift 包 `DiceKit` 里，不需要 Xcode 工程：

```bash
swift test --package-path DiceKit
```

扩展的面板逻辑、界面路由和消息组装：

```bash
xcodebuild test -project Dice.xcodeproj -scheme DiceApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:DiceMessagesTests
```

无障碍检查（UI 测试，比较慢，不在 CI 里跑；发版前跑一次）：

```bash
xcodebuild test -project Dice.xcodeproj -scheme Accessibility -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

模拟器名称按本机已有的调整。

CI（GitHub Actions，`.github/workflows/ci.yml`）在每个 PR 和每次推送到 `main` 时跑这两套测试。

## 版本号与发布

**版本号**
- 版本号（`MARKETING_VERSION`）遵循 [SemVer](https://semver.org/lang/zh-CN/) 的 `主.次.修订`。TestFlight 测试阶段保持 `0.x.y`，正式上架时为 `1.0.0`。App Store 不接受 `-beta` 之类的后缀。
- 构建号（`CURRENT_PROJECT_VERSION`）是整数，**每次上传都必须比上一次大**，不随版本号归零。

**发布**

```bash
scripts/release.sh 0.4.1
```

1. 脚本会把构建号加一，并重新生成工程。
2. 跑两套测试，打包，上传到 App Store Connect 前先问你确认。`--yes` 不再询问；`--no-upload` 只打包、不上传。
3. 上传成功后提交版本号的修改；任何一步失败都会还原 `project.yml`。

脚本需要 Xcode 已登录团队的 Apple ID。如果报 `Failed to Use Accounts`，到 Xcode → Settings → Accounts 重新登录。

**TestFlight**

上传后：
1. 把构建加进测试组；
2. 把 [docs/testflight/beta-info.md](docs/testflight/beta-info.md) 里的"测试内容"粘贴上去。

**消息格式**
- 当前版本是 `v=3`。每条投骰都按**能表达它的最低版本**写入：
  - 普通投骰写 `v=1`；
  - 有加成骰写 `v=2`；
  - 关闭大成功判定、而且主骰是单个 d20 时写 `v=3`。
- App 遇到比自己新的版本时，会提示用户更新，不会自己猜。
- **以后改格式的规则：**凡是会让旧版算出不同结果的改动，都必须升版本；旧版可以放心忽略的功能（比如目的）可以留在旧版本。见 `DiceKit/Sources/DiceKit/MessageCodec.swift`。

## 目录结构

```
DiceKit/            Swift 包：RollSpec、BonusDice、DiceEngine、MessageCodec、RollFormatter、RollHistory
Shared/             App 与扩展共用：投骰面板、加成骰选择、结果卡片、公式存储、文案
DiceApp/            宿主 App：投骰主页（RollerView）与使用说明（GuideView）
DiceMessages/       iMessage 扩展：气泡、结果详情、消息组装
DiceMessagesTests/  扩展和共用面板的单元测试
scripts/            release.sh（发 TestFlight）、make_icons.py（生成图标，需要 Pillow）
docs/               玩家文档、TestFlight 说明、设计记录（docs/superpowers）
project.yml         XcodeGen 工程定义
```

## 设计记录

每个功能都按"设计 → 计划 → 实现"的顺序做：

| 功能 | 设计 | 计划 |
|---|---|---|
| iMessage 骰子 | [设计](docs/superpowers/specs/2026-10-05-imessage-dice-design.md) | [计划](docs/superpowers/plans/2026-10-05-imessage-dice.md) |
| App 内投骰 | [设计](docs/superpowers/specs/2026-10-06-in-app-roller-design.md) | [计划](docs/superpowers/plans/2026-10-06-in-app-roller.md) |
| 投骰目的、DC 上限 999 | [设计](docs/superpowers/specs/2026-10-06-roll-purpose-design.md) | [计划](docs/superpowers/plans/2026-10-06-roll-purpose.md) |
| 加成骰 | [设计](docs/superpowers/specs/2026-10-06-bonus-dice-design.md) | [计划](docs/superpowers/plans/2026-10-06-bonus-dice.md) |

接下来做什么、还有哪些已知问题，见 [roadmap](docs/roadmap.md)（英文）。

## 现状

最新的 TestFlight 版本是 **0.6.3（构建号 15）**。

**已在真机（iPhone 14 Pro，iOS 26.6）上验证：**
- 草稿只显示公式；
- 发送后气泡显示结果，滑走再滑回、退出再进入都正常；
- 气泡的小图标和布局正确；
- 「信息」里的目的输入框正常。

**还没在真机上验证：**
- 带加成骰的气泡；
- 0.3.x 收到加成骰消息时提示更新；
- 拼音还没选词时直接点投掷。

完整清单见 [roadmap](docs/roadmap.md)。

## 许可

代码：[MIT](LICENSE)。

预设的法术和职业特性来自 Wizards of the Coast 的 System Reference Document 5.2.1，以 CC-BY-4.0 授权：

This work includes material from the System Reference Document 5.2.1 ("SRD 5.2.1") by Wizards of the Coast LLC, available at https://www.dndbeyond.com/srd. The SRD 5.2.1 is licensed under the Creative Commons Attribution 4.0 International License, available at https://creativecommons.org/licenses/by/4.0/legalcode.
