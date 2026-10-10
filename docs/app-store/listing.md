# App Store 上架资料

在 App Store Connect → App 里填写（App 信息、App 隐私、版本页）。每一项都标了字数上限，下面的文字都在上限以内（2026-10-10 数过）；改动后请重数。

> **先决定名字。** "DND" 是 Dungeons & Dragons 的常见缩写，D&D 是 Wizards of the Coast 的商标；SRD 的 CC-BY 授权只覆盖规则文字，不授予商标使用权。App 名称里带商标容易被审核以 5.2.1（知识产权）拒绝，上架后也可能被投诉下架。下面的文案暂用 "DND Dice"，描述和关键词里已避免使用 D&D / DnD。

## 网址

| 项目 | 网址 |
|---|---|
| 隐私政策网址（必填） | https://github.com/Cudd1es/dice/blob/main/docs/privacy.md |
| 技术支持网址（必填） | https://github.com/Cudd1es/dice/blob/main/docs/support.md |
| 营销网址（可选） | https://github.com/Cudd1es/dice |

这两个页面要等本分支合并进 `main` 后才能打开。

## App 信息

| 项目 | 建议 |
|---|---|
| 主要类别 | 娱乐（Entertainment） |
| 次要类别 | 工具（Utilities） |
| 版权 | 2026 Ansel |
| 内容版权 | 不包含第三方内容需要授权的部分：SRD 5.2.1 以 CC-BY-4.0 授权，已在 App 内"使用说明 → 关于"和描述中署名 |

不选"游戏"类别：它是投骰工具，不是游戏；选游戏会多出 Game Center 和游戏分级相关的问题。

## 简体中文

**名称**（30）：DND Dice

**副标题**（30）：跑团骰子，发出后才揭晓结果

**宣传文本**（170，可随时修改，不需要审核）：
在「信息」里投骰，发送前连你自己也看不到结果；发出后，全队看到同一个总值、骰子和成败，没法偷看后重投。也能在 App 里当桌边骰子用。

**关键词**（100，用逗号分隔，不加空格）：
骰子,跑团,掷骰,投骰,桌游,角色扮演,TRPG,d20,5e,优势,劣势,检定,大成功,祝福术,信息,iMessage,DM,团本

66 个字符。如果 App Store Connect 提示超长（它按字符计，个别情况按字节计时会是 126），从后往前删到能保存为止。

**描述**（4000）：

在「信息」对话里为跑团投骰，结果在发出之前谁都看不到，包括你自己。

点「投掷」的那一刻结果就已确定，但草稿里只显示公式，例如「1d20+5 · 优势 · DC 15 · 发送后揭晓」。发出后，对话里每个人看到的都是同一个总值、同一组骰子和同一个成败。不能先偷看再决定要不要重投。

【在「信息」里投】
• 点输入框旁的 +，选 DND Dice，设好骰子点「投掷」
• 可以写一句目的，例如「察觉检定：门后有没有人」，和结果一起显示
• 点已发送的投骰，打开完整结果

【在桌边投】
• 打开 App 就是投骰界面，结果大字显示
• 保留最近 10 次投骰，带时间和目的

【功能】
• d4、d6、d8、d10、d12、d20、d100，1–20 枚，加值 −20 到 +20
• 单个 d20 的优势 / 劣势
• DC 1–999，直接显示成功或失败
• 天然 20 大成功、天然 1 大失败；房规不用的话，可以在设置里关掉
• 加成骰：最多 4 组，例如祝福术 +1d4、灾祸术 −1d4，常用法术和职业特性一键添加
• 简体中文和英文界面，跟随系统语言
• 支持旁白（VoiceOver）和大字号

【隐私】
没有账号、没有广告、不追踪、不收集任何数据。设置只保存在你的 iPhone 上。

想看结果的人都需要安装 DND Dice；没装的人只会看到公式和安装提示。

加成预设包含 Wizards of the Coast LLC 的 System Reference Document 5.2.1 中的内容，以 CC BY 4.0 授权。本 App 与 Wizards of the Coast 无关，也未获其认可。

**此版本的新内容**（1.0.0）：
第一个正式版本。在「信息」里投骰，发出前谁都看不到结果；支持优势 / 劣势、DC、加成骰、投骰目的，以及关闭大成功判定。

## English

**Name** (30): DND Dice

**Subtitle** (30): Dice rolls revealed when sent

**Promotional Text** (170, can change any time without review):
Roll in Messages with the result hidden until it's sent, even from you. Then the whole party sees the same total, dice and outcome, so nobody can peek and reroll.

**Keywords** (100, comma-separated, no spaces):
dice,roller,d20,rpg,ttrpg,5e,tabletop,imessage,advantage,disadvantage,dc,critical,bless,dm,party

**Description** (4000):

Roll dice for your tabletop RPG right in Messages, and nobody sees the result until it's sent, not even you.

The result is fixed the moment you tap Roll, but the draft shows only the formula, like "1d20+5 · Advantage · DC 15 · Revealed when sent". Send it, and everyone in the chat sees the same total, the same dice and the same outcome. No peeking first and deciding whether to roll again.

IN MESSAGES
• Tap + next to the text field, choose DND Dice, set your dice and tap Roll
• Add a purpose, like "Perception: is someone behind the door?", shown with the result
• Tap a sent roll to open the full result

AT THE TABLE
• Open the app and roll; the result shows in large type
• The last 10 rolls are kept, with time and purpose

FEATURES
• d4, d6, d8, d10, d12, d20 and d100, 1–20 dice, modifiers from −20 to +20
• Advantage and disadvantage on a single d20
• A DC from 1 to 999, with success or failure shown on the roll
• Critical success on a natural 20 and critical failure on a natural 1, or turn them off in Settings for your house rules
• Bonus dice: up to 4 groups, like Bless +1d4 or Bane −1d4, with one-tap presets for common spells and class features
• English and Simplified Chinese, following your iPhone's language
• VoiceOver and large text support

PRIVATE
No account, no ads, no tracking, no data collected. Your settings stay on your iPhone.

Everyone who wants to see the result needs DND Dice; others see the formula and an install prompt.

Bonus presets include material from the System Reference Document 5.2.1 by Wizards of the Coast LLC, licensed under CC BY 4.0. This app is not affiliated with or endorsed by Wizards of the Coast.

**What's New** (1.0.0):
First release. Roll in Messages with the result hidden until it's sent, with advantage and disadvantage, a DC, bonus dice, a purpose for each roll, and an option to turn off critical success and failure.

## App 隐私（App Privacy）

1. "你或你的第三方合作伙伴是否从此 App 收集数据？"→ **否，我们不从此 App 收集数据**。
2. 结果显示为 **"未收集数据"（Data Not Collected）**。

依据：App 不联网，也没有第三方 SDK；公式和设置只保存在本机（`PrivacyInfo.xcprivacy` 已声明 `UserDefaults` 的用途）。在「信息」里发出的投骰由用户主动发送、由 Apple 的 iMessage 传递，开发者收不到，不算"收集"。

## 年龄分级

所有内容类问题都选 **"无"（None）**：暴力、恐怖、成人内容、粗俗幽默、药物、模拟赌博、竞赛、医疗等。其他问题：

| 问题 | 回答 | 说明 |
|---|---|---|
| 不受限制的网页访问 | 否 | "关于"里的两个链接在 Safari 中打开，App 内没有浏览器 |
| 用户生成内容 / 用户之间的消息 | 否 | 目的文字通过 Apple 的「信息」发送，App 本身不提供交流功能 |
| 广告 | 否 | |
| 家长控制 / 年龄验证 | 否 | |

预计分级：**4+**。骰子只是数字，不涉及真钱或奖品，不属于模拟赌博。

## 审核备注（App Review Information）

- **需要登录**：否（不勾选"需要登录"）
- **联系信息**：填写你的姓名、电话和邮箱（只给审核人员看）
- **备注**（英文）：

```
DND Dice has no account and needs no sign-in.

To test the iMessage extension: open Messages, start any conversation, tap the + button next to the text field, scroll the list and choose "DND Dice", set the dice and tap "Roll". The roll is inserted into the text field; its result is hidden until the message is sent, then the bubble shows it. Tapping a sent roll opens the full result.

The app itself is a dice roller: tap "Roll" on the main screen. Settings (gear button) can turn critical success and failure off.

The person receiving a roll needs the app to see the result; without it, Messages shows the formula and an install prompt.
```

## 截图

**只需要 iPhone**（App 已设为仅支持 iPhone）。上传 6.9 英寸（1320 × 2868）即可，系统会缩放给较小的机型。App 和 iMessage 扩展各一组。

| # | 组 | 内容 | 来源 |
|---|---|---|---|
| 1 | App | 大成功的结果卡片，带目的，下方有记录 | 模拟器（iPhone 17 Pro Max） |
| 2 | App | 面板：优势、DC、+1d4 祝福术 | 模拟器 |
| 3 | App | 加成菜单（预设） | 模拟器 |
| 4 | App | 设置页（大成功判定开关） | 模拟器 |
| 5 | iMessage | 「信息」里的面板，草稿气泡显示"发送后揭晓" | 模拟器（草稿气泡可能是空白，空白就用真机） |
| 6 | iMessage | 对话里已发送的气泡，显示结果 | **真机**（模拟器里气泡是空白的） |
| 7 | iMessage | 点开气泡后的完整结果 | **真机** |

中文和英文各一套：先截中文，英文用模拟器的 `-AppleLanguages (en)` 再截一遍。
