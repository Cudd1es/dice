# TestFlight 外部测试信息

在 App Store Connect → TestFlight → 测试信息（Test Information）里填写。每次发新版只需要改"测试内容"。

## Beta 版 App 描述（Beta App Description）

DND Dice 是给跑团（DnD 5e / 博德之门规则）用的骰子，有两种用法：

1. 在「信息」里投：对话里点 + →「骰子」，设好骰子后点「投掷」。结果在投掷时就已确定，但发送前谁都看不到，发出去后气泡上直接显示结果，大家看到的一样。所以没法"先看结果、不满意再重投"。
2. 在 App 里投：打开 App 就是投骰界面，适合线下跑团把手机当骰子用，下面保留最近 10 次记录。

支持 d4–d100、1–20 枚、加值、优势/劣势、DC，以及天然 20 / 天然 1 的大成功和大失败。

## 测试内容（What to Test）— 0.1.0（构建号 2）

这是第一个测试版，最想确认的是"别人能不能看到你投的结果"：

1. 在群聊里用「骰子」投一次并发送：每个人的气泡上是否都显示同一个结果（总值、明细、成败）？
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
> To test the iMessage extension: open Messages, start any conversation, tap the + button next to the text field, choose "骰子" (Dice), set the dice and tap "投掷" (Roll). The roll is inserted into the text field; its result is hidden until the message is sent, then the bubble shows it.
> To test the app: open it and tap "投掷" (Roll). The result appears at the top and recent rolls are listed below.
> No account, network access or in-app purchase is involved.
