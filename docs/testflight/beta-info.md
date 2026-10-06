# TestFlight 外部测试信息

在 App Store Connect → TestFlight → 测试信息（Test Information）里填写。每次发新版只需要改"测试内容"。

## Beta 版 App 描述（Beta App Description）

DND Dice 是给跑团（DnD 5e / 博德之门规则）用的骰子，有两种用法：

1. 在「信息」里投：对话里点 + →「DND Dice」，设好骰子后点「投掷」。结果在投掷时就已确定，但发送前谁都看不到，发出去后气泡上直接显示结果，大家看到的一样。所以没法"先看结果、不满意再重投"。
2. 在 App 里投：打开 App 就是投骰界面，适合线下跑团把手机当骰子用，下面保留最近 10 次记录。

支持 d4–d100、1–20 枚、加值、优势/劣势、DC，以及天然 20 / 天然 1 的大成功和大失败。

## 测试内容（What to Test）— 0.2.1（构建号 4）

修复「信息」App 列表里 DND Dice 不显示图标的问题。

1. 「信息」→ + 里的 DND Dice 是否有图标？
2. 之前发过的骰子消息还能正常显示结果吗？（这一版换了扩展的内部标识，旧消息可能只显示公式和安装提示；新发的消息应完全正常）

### English

Fixes the missing DND Dice icon in the Messages app list.

1. Does DND Dice show its icon under + in Messages?
2. Do dice messages sent before this update still show their results? (The extension's internal ID changed, so older messages may only show the formula and an install prompt; new messages should work normally.)

### 上一版：测试内容（What to Test）— 0.2.0（构建号 3）

这一版新增英文界面，App 统一改名为 DND Dice，并修复了图标：

1. 手机系统语言是英文的朋友：App 和「信息」里的面板、气泡是否显示英文？中文系统是否仍显示中文？
2. 一个英文手机、一个中文手机互发投骰：双方看到的是否是同一个结果，只是各自用自己的语言显示？
3. 主屏幕和「信息」的 App 列表里，名字是否为 DND Dice，图标是否正常显示？
4. 上一版要测的四项（大家看到的结果是否一致、草稿里是否只有公式、滑走再滑回结果是否还在、App 内投骰与震动）也请顺手再看一眼。

遇到问题请截图，在 TestFlight 里"发送 Beta 版反馈"，或直接在群里说。

### English

What's new: English interface, the app is now called DND Dice, and the icons are fixed.

1. If your phone is set to English: are the app, the Messages panel and the bubbles in English?
2. Send rolls between an English phone and a Chinese phone: does everyone see the same result, each in their own language?
3. Is the app called DND Dice with its icon on the Home Screen and in the Messages app list?
4. Please also recheck: everyone sees the same result, drafts show only the formula, results survive scrolling away and back, and rolling in the app (with haptics) works.

Please send screenshots through TestFlight feedback or in the group chat.

### 上一版：测试内容（What to Test）— 0.1.0（构建号 2）

这是第一个测试版，最想确认的是"别人能不能看到你投的结果"：

1. 在群聊里用 DND Dice 投一次并发送：每个人的气泡上是否都显示同一个结果（总值、明细、成败）？
2. 草稿还没发出去时，气泡上是否只有公式和「发送后揭晓」，看不到点数？
3. 把聊天记录往上滑，让骰子消息滑出屏幕再滑回来、或者退出对话再进来，结果是否还在？
4. 打开 App 本身投几次：结果和最近记录是否正常，投掷时是否有震动？

遇到问题请截图，在 TestFlight 里"发送 Beta 版反馈"（截屏后会自动弹出），或直接在群里说。

已知限制：
- 群里每个人都要安装才能看到结果，没装的人只会看到公式和安装提示
- 结果写在消息里，懂技术的人能读出来，防的是"顺手重投"，不是作弊

## 反馈邮箱（Feedback Email）

填你自己的邮箱。

## Beta 版 App 审核信息（Beta App Review Information）

- 联系人：你的姓名、电话、邮箱
- 需要登录：否（App 没有账号系统）
- 审核备注（Notes），可直接粘贴：

> This app is a dice roller for tabletop role-playing games. It has two parts: an iMessage extension and the app itself.
> To test the iMessage extension: open Messages, start any conversation, tap the + button next to the text field, choose "DND Dice", set the dice and tap "Roll". The roll is inserted into the text field; its result is hidden until the message is sent, then the bubble shows it.
> To test the app: open it and tap "Roll". The result appears at the top and recent rolls are listed below.
> No account, network access or in-app purchase is involved.
