# DND Dice

iMessage 骰子扩展，给固定跑团群用：在「信息」里用按钮面板投 DnD 5e / 博德之门风格的骰子。界面支持英文和简体中文，跟随系统语言。

- d4 / d6 / d8 / d10 / d12 / d20 / d100，1–20 枚，加值 −20…+20
- 1d20 的优势 / 劣势、大成功 / 大失败
- 可选 DC（1–999），天然 20 必定成功、天然 1 必定失败
- 加成骰：在主骰之外最多加 4 组，每组 1–10 个 d4–d100，可加可减（如祝福术 `1d20+1d4`、灾祸术 `1d20-1d4`、伤害 `1d8+2d6+3`）。优势/劣势与大成功/大失败只看主骰。带加成骰的消息需要 0.4.0 及以上才能读取，旧版会提示更新

## 怎么防止"不满意就重投"

点「投掷」时结果就已确定并写进消息，但面板和草稿气泡上都只显示公式，例如「1d20+5 · 优势 · DC 15 / 发送后揭晓」。消息发出后，气泡自动显示结果（总值、明细、成败），不用点开。发送者在发送前看不到结果，所以删掉草稿重投没有意义。

没装 DND Dice 的人收到时，只会看到公式和「安装 DND Dice 查看结果」，同样看不到结果。

气泡由收消息的人自己手机上的 App 绘制，所以每个人看到的是自己系统语言的文字；草稿和没装 App 的人看到的备用文字用的是发送方的语言。

这是"防君子"级别的防护：结果以明文写在消息 URL 里，懂技术的人能读出来。

> **只能在真机上测试气泡。** 模拟器上的「信息」不让气泡读取自己的消息，气泡会是空的；真机上正常。详见 [spike 记录](docs/superpowers/spikes/2026-10-05-live-layout.md)。投骰面板和单元测试在模拟器上都没问题。

## 构建与运行

需要 Xcode 16 及以上（开发时用的是 Xcode 26.2）、iOS 17 及以上的模拟器，以及 [XcodeGen](https://github.com/yonaskolb/XcodeGen)。

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

在 Xcode 里选 `DiceApp` scheme 运行，然后打开「信息」，进入任意对话，点输入框左侧的 **+**，在 App 列表里选「DND Dice」。

**打开 App 本身也能投骰**，适合线下跑团把手机当骰子用：面板和「信息」里的一样，结果大字显示在上方，下面列出最近 10 次记录，关掉 App 后清空。

面板最上方可以填这次投骰的目的（可选，最多 40 字，比如「攻击哥布林」）。它会和骰子一起显示在气泡、结果详情和 App 的「最近」记录里，投完自动清空。还没更新的旧版 App 收到时照常显示结果，只是看不到目的。

DC 可以用加减按钮调，也可以点数字直接输入（1–999）。

## 测试

规则、编解码和文案都在纯 Swift 包 `DiceKit` 里，不依赖 Xcode 工程：

```bash
cd DiceKit && swift test
```

扩展的路由、消息组装和面板逻辑：

```bash
xcodebuild test -project Dice.xcodeproj -scheme DiceApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:DiceMessagesTests
```

模拟器名称按本机已有的调整。

## 版本号与发布

- 版本号（`MARKETING_VERSION`）遵循 [SemVer](https://semver.org/lang/zh-CN/) 的 `主.次.修订`；TestFlight 测试阶段保持 `0.x.y`，正式上架时为 `1.0.0`。App Store 不接受 `-beta` 之类的后缀
- 构建号（`CURRENT_PROJECT_VERSION`）是整数，**每次上传都必须比上一次大**，不随版本号归零
- 两者都在 `project.yml` 里改，改完运行 `xcodegen generate`
- TestFlight 的外部测试说明见 [docs/testflight/beta-info.md](docs/testflight/beta-info.md)

## 目录结构

```
DiceKit/            纯 Swift 包：RollSpec、DiceEngine、MessageCodec、RollFormatter
DiceMessages/       iMessage 扩展（SwiftUI）：面板、结果详情、消息组装
DiceMessagesTests/  扩展的单元测试
DiceApp/            宿主 App：投骰主页（RollerView）与使用说明（GuideView）
Shared/             App 与扩展共用的面板、结果卡片和公式存储
scripts/            make_icons.py：生成 App 与 iMessage 图标（需要 Pillow）
docs/superpowers/   设计、实施计划、spike 与验收记录
project.yml         XcodeGen 工程定义
```

## 文档

- [设计](docs/superpowers/specs/2026-10-05-imessage-dice-design.md)
- [实施计划](docs/superpowers/plans/2026-10-05-imessage-dice.md)
- [Live Layout spike](docs/superpowers/spikes/2026-10-05-live-layout.md)
- [模拟器验收](docs/superpowers/acceptance/2026-10-05-simulator.md)

## 现状

发送方已在真机（iPhone 14 Pro）上验证：草稿只显示公式，发送后气泡自动显示结果，滑走再滑回、退出再进入都正常。

App 内投骰已在模拟器上验收（iPhone 17 Pro、iPhone SE、深色模式、大字号），震动反馈的手感待真机确认。

接收方视角和群聊还没验证，要等加入 Apple Developer Program、用 TestFlight 把 App 发给群友之后。

## 许可

[MIT](LICENSE)
