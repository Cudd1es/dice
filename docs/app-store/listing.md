# App Store 上架资料

在 App Store Connect → App 里填写（App 信息、App 隐私、版本页）。每一项都标了字数上限，下面的文字都在上限以内（2026-10-10 数过）；改动后请重数。

> **名字：掷定 / Dicide**（2026-10-10 定）。"掷定"读 zhì dìng，谐音"制定 / 指定"；Dicide = dice + decide。查过 App Store 和商标检索，没有同名。主屏幕名字按语言显示（`InfoPlist.xcstrings`）。描述和关键词里不用 D&D / DnD 等商标。App Store Connect 里的 App 名称要手动从"DND Dice"改过来。

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

**名称**（30）：掷定 Dicide

**副标题**（30）：选择困难就过个检定，也能跑团投骰

**宣传文本**（170，可随时修改，不需要审核）：
拿不定主意？给它过个检定：DC 代表该不该做，加值和优势代表你有多想做，剩下的交给 d20。跑团时也是一套完整的骰子，在「信息」里投，发出前谁都看不到结果。

**关键词**（100，用逗号分隔，不加空格）：
骰子,选择困难,做决定,检定,跑团,掷骰,投骰,d20,DC,优势,劣势,大成功,桌游,TRPG,5e,随机,信息,iMessage


**描述**（4000）：

选择困难的时候，给它过个检定。

把问题写下来，例如"买不买那双鞋？"。用 DC 表示这件事该不该做：理智上该做就设低，不太该做就设高。再用加值或优势、劣势表示你自己有多想做。然后投一个 d20：成功就去做，失败就算了。天然 20 和天然 1 直接拍板。

它也是一套完整的跑团骰子。

【在「信息」里投】
• 点输入框旁的 +，选「掷定」，设好骰子点「投掷」
• 点「投掷」的那一刻结果就已确定，但发送前谁都看不到，包括你自己；发出后，对话里每个人看到的都是同一个结果，没法偷看后重投
• 可以写一句目的，例如"察觉检定：门后有没有人"，和结果一起显示
• 点已发送的投骰，打开完整结果

【在 App 里投】
• 打开就是投骰界面，结果大字显示
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

在「信息」里，想看结果的人都需要安装「掷定」；没装的人只会看到公式和安装提示。

加成预设包含 Wizards of the Coast LLC 的 System Reference Document 5.2.1 中的内容，以 CC BY 4.0 授权。本 App 与 Wizards of the Coast 无关，也未获其认可。

**此版本的新内容**（1.0.0）：
第一个正式版本。选择困难时用 d20 检定做决定，DC、加值、优劣势随你设；也能在「信息」里跑团投骰，发出前谁都看不到结果。

## English

**Name** (30): Dicide

**Subtitle** (30): Roll a check for any decision

**Promotional Text** (170, can change any time without review):
Can't decide? Roll a check: the DC is how much it deserves to happen, your modifier is how much you want it. Also a full dice roller for tabletop RPGs in Messages.

**Keywords** (100, comma-separated, no spaces):
dice,decision,decide,choice,check,d20,dc,rpg,ttrpg,5e,tabletop,roller,advantage,imessage,random

**Description** (4000):

Can't decide? Roll a check.

Write the question, like "Buy the shoes?". Set a DC for how much it deserves to happen: low if it's sensible, high if it's doubtful. Add a modifier, or advantage or disadvantage, for how much you want it. Then roll a d20: success means do it, failure means let it go. A natural 20 or 1 settles it.

It's also a full dice roller for tabletop RPGs.

IN MESSAGES
• Tap + next to the text field, choose Dicide, set your dice and tap Roll
• The result is fixed the moment you tap Roll but hidden until the message is sent, even from you. Then everyone in the chat sees the same result, so nobody can peek and roll again
• Add a purpose, like "Perception: is someone behind the door?", shown with the result
• Tap a sent roll to open the full result

IN THE APP
• Open it and roll; the result shows in large type
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

In Messages, everyone who wants to see the result needs Dicide; others see the formula and an install prompt.

Bonus presets include material from the System Reference Document 5.2.1 by Wizards of the Coast LLC, licensed under CC BY 4.0. This app is not affiliated with or endorsed by Wizards of the Coast.

**What's New** (1.0.0):
First release. Decide with a d20 check, with your own DC, modifier and advantage, and roll for tabletop RPGs in Messages with the result hidden until it's sent.

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
Dicide (Chinese name 掷定) has no account and needs no sign-in.

To test the iMessage extension: open Messages, start any conversation, tap the + button next to the text field, scroll the list and choose "Dicide" (掷定 on a Chinese iPhone), set the dice and tap "Roll". The roll is inserted into the text field; its result is hidden until the message is sent, then the bubble shows it. Tapping a sent roll opens the full result.

The app itself is a dice roller, also meant for making decisions with a DC check: tap "Roll" on the main screen. Settings (gear button) can turn critical success and failure off.

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
