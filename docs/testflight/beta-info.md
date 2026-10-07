# TestFlight 外部测试信息

在 App Store Connect → TestFlight → 测试信息（Test Information）里填写。每次发新版只需要改"测试内容"。

## Beta 版 App 描述（Beta App Description）

DND Dice 是给跑团（DnD 5e / 博德之门规则）用的骰子，有两种用法：

1. 在「信息」里投：对话里点 + →「DND Dice」，设好骰子后点「投掷」。结果在投掷时就已确定，但发送前谁都看不到，发出去后气泡上直接显示结果，大家看到的一样。所以没法"先看结果、不满意再重投"。
2. 在 App 里投：打开 App 就是投骰界面，适合线下跑团把手机当骰子用，下面保留最近 10 次记录。

支持 d4–d100、1–20 枚、加值、优势/劣势、DC（1–999），以及天然 20 / 天然 1 的大成功和大失败；可以加上祝福术 +1d4 这样的加成骰，也可以写一句投骰目的（例如「察觉检定」），和结果一起显示。

## 测试内容（What to Test）— 0.6.0

新功能：设置页里可以关闭大成功 / 大失败判定（App 右上角齿轮）。关掉后天然 20 / 1 只是普通点数，只用总值和 DC 比较，公式末尾标出"不判定大成功"。「信息」里用的也是这个设置；你发出的投骰按你的设置判定，大家看到的结果一致。请大家都更新：旧版收到关闭判定的投骰会提示"请更新 App"。

1. 在设置里关掉判定，App 里投一次带 DC 的 1d20：公式是否带"不判定大成功"？天然 20 是否不再显示大成功？
2. 回到「信息」打开 DND Dice：面板公式是否也带这句？发一条给朋友：朋友那边的结果是否和你一致？
3. 重新打开判定：两边是否恢复？
4. 还没更新的朋友收到关闭判定的投骰，是否提示"请更新 App"？

### English

New: a Settings page (the gear at the top right of the app) can turn critical success / failure off. When off, a natural 20 or 1 is just a number, only the total meets the DC, and the formula ends with "No crits". Messages uses the same setting; rolls you send follow your setting, so everyone sees the same result. Please update: older versions ask to update when they receive a roll with criticals off.

1. Turn criticals off and roll a 1d20 with a DC in the app: does the formula say "No crits", and does a natural 20 no longer show Critical Success?
2. Open DND Dice in Messages: does the panel's formula say it too? Send one to a friend: do they see the same result?
3. Turn criticals back on: do both places go back to normal?
4. Friends who haven't updated: does a roll with criticals off ask them to update?

### 上一版：测试内容（What to Test）— 0.5.2（构建号 11）

加成菜单的按钮改成和主面板骰子按钮一样的灰底、黑字：在「信息」小窗口里看得清楚，也不会像"已选中"。蓝色只用在选中的骰子和已加上的加成标签上。

1. 加成菜单的按钮现在看得清楚吗？满 4 组时，加不进去的按钮能分辨出来吗？
2. 0.5.1 的改动也请再看一眼：投完后加成标签是否消失？

### English

The bonus picker's buttons now use the same grey with dark text as the panel's die buttons: easy to see in the Messages drawer, without looking "selected". Blue is used only for the selected die and added bonus tags.

1. Are the bonus picker's buttons easy to see now? With 4 groups, can you tell which buttons are unavailable?
2. Please also recheck 0.5.1: does the bonus tag disappear after a roll?

### 上一版：测试内容（What to Test）— 0.5.1（构建号 10）

两处改动：
- 加成骰只用于一次投骰：投完自动清空，下一次默认没有加成；骰子、加值、优势和 DC 仍会记住。
- 加成菜单里的按钮改成浅蓝底，在「信息」小窗口里更明显。

1. 加上祝福术投一次：投完后加成标签是否消失？再投一次是否不带 +1d4？
2. 加成菜单的按钮现在看得清楚吗？

### English

Two changes:
- Bonus dice now apply to one roll only: they are cleared after each roll. Dice, modifier, advantage and DC are still remembered.
- The bonus picker's buttons now have a light blue fill, so they stand out in the Messages drawer.

1. Add Bless and roll: does the bonus tag disappear afterwards, and does the next roll go without +1d4?
2. Are the bonus picker's buttons easy to see now?

### 上一版：测试内容（What to Test）— 0.5.0（构建号 9）

新功能：加成骰预设。在「＋ 加成」里新增按 2024 年规则整理的常用加成，点一下就加上：祝福术、神导术、灾祸术、诗人激励（d6–d12）、猎人印记、脆弱诅咒、神恩术、至圣斩。另外：
- 「＋ 加成」移到 DC 那一行的最右边，「信息」小窗口里整个面板能放下了；
- 目的超过 40 字不再在输入时截断（字数提示变红，投掷时保留前 40 字），拼音输入不会被打断；
- 「信息」里离开时停在加成菜单，下次打开会回到面板。

1. 试几个预设：祝福术 + 神导术是否合并成 +2d4？至圣斩是否加上 +2d8？
2. 「信息」小窗口里不用上滑就能看到 DC、公式和「投掷」吗？
3. 用拼音在目的里打一长句：输入是否顺畅？超过 40 字时提示是否变红？

### English

New: bonus presets. "+ Bonus" now has one-tap bonuses from the 2024 rules: Bless, Guidance, Bane, Bardic Inspiration (d6–d12), Hunter's Mark, Hex, Divine Favor, Divine Smite. Also:
- "+ Bonus" moved to the end of the DC row, so the whole panel fits the small Messages drawer;
- the purpose is no longer cut while typing (the counter turns red past 40 and rolling keeps the first 40), so pinyin input isn't interrupted;
- leaving Messages with the bonus picker open returns to the panel next time.

1. Try a few presets: do Bless and Guidance merge into +2d4? Does Divine Smite add +2d8?
2. In the small Messages drawer, can you see the DC row, the formula and Roll without scrolling?
3. Type a long purpose with pinyin: is input smooth, and does the counter turn red past 40?

### 上一版：测试内容（What to Test）— 0.4.0（构建号 8）

新功能：加成骰（骰子组合）。在面板上点「＋ 加成」选骰子，选完自动回到面板；也可以点「减」做灾祸术那样的 -1d4。请大家都更新：旧版收到带加成骰的消息只会提示"请更新 App"。

1. 试三种组合：`1d20+1d4+5`（开优势和 DC 15）、`1d20-1d4`、`1d8+2d6+3`（主骰选 d8、加值 +3、加成 2 次 d6）。总值和明细算得对吗？
2. 点加成骰的小标签：「多一个 / 少一个 / 删除」是否正常？加满 4 组后，新的骰子种类是否变灰？
3. 在「信息」里发一条带加成骰的投骰：自己和朋友看到的气泡、点开的结果是否一致？
4. 还没更新的朋友收到带加成骰的消息，是否显示"请更新 App"？

### English

New: bonus dice. Tap "+ Bonus" on the panel to pick one; you return to the panel right away. Switch to Subtract for things like Bane (-1d4). Please update: older versions only show "Please update the app" for rolls with bonus dice.

1. Try `1d20+1d4+5` (with advantage and DC 15), `1d20-1d4`, and `1d8+2d6+3` (main die d8, modifier +3, d6 added twice). Are the total and breakdown right?
2. Tap a bonus tag: do One More / One Fewer / Remove work? With 4 groups, are new kinds greyed out?
3. Send a roll with bonus dice in Messages: do you and your friends see the same bubble and result?
4. Friends who haven't updated: does a roll with bonus dice ask them to update?

### 上一版：测试内容（What to Test）— 0.3.2（构建号 7）

目的输入框换了新样式：浅灰圆角底，和面板按钮统一；有文字时右边出现清空按钮，超过 30 字显示字数。

1. 目的输入框在浅色和深色模式下是否好看、好点？清空按钮能否正常清空？
2. 点 DC 数字输入时，输入框样式是否正常？
3. 0.3.1 要测的气泡第一行（不被小图标挡住）也请再看一眼。

### English

The purpose field has a new look: a filled rounded field matching the panel's buttons, a clear button once there is text, and a character counter past 30.

1. Does the purpose field look right and feel easy to tap in light and dark mode? Does the clear button work?
2. Does the DC field look right when you tap the number to type?
3. Please also recheck the 0.3.1 item: the first line of a bubble is not covered by the small icon.

### 上一版：测试内容（What to Test）— 0.3.1（构建号 6）

修复：骰子气泡左上角的小图标挡住第一行文字（目的或公式）。

1. 气泡的第一行（目的，没填目的时是公式）是否完整显示在小图标右边，没有被挡住？
2. 0.3.0 要测的几项也请顺手再看一眼。

### English

Fix: the small app icon in the bubble's top-left corner no longer covers the first line (the purpose, or the formula when there is none).

1. Does the first line of a dice bubble show in full, to the right of the small icon?
2. Please also recheck the 0.3.0 items below.

### 上一版：测试内容（What to Test）— 0.3.0（构建号 5）

新功能：投骰前可以写一句目的；DC 上限提高到 999，还能直接输入。请大家都更新到这一版（旧版收到 DC 超过 40 的消息会显示"数据无效"）。

1. 投骰面板最上方填目的（比如「察觉检定：门后有没有人」）再投：草稿气泡、发出后的气泡、点开的结果里都能看到目的吗？投完输入框是否清空？
2. 在「信息」里，面板在下方小窗口时点目的输入框：面板是否展开到全屏并弹出键盘？（如果之前点开过某条骰子结果，也试一次，确认不会跳到那条结果）
3. 点 DC 的数字，直接输入 120 之类的大数，点「完成」后是否生效？不点「完成」直接点「投掷」，用的是不是刚输入的 DC？
4. 还没更新的朋友收到带目的的消息：结果是否照常显示（只是看不到目的）？
5. App 内投骰：结果区和「最近」记录里是否显示目的？

### English

New: write an optional purpose before rolling, and DCs now go up to 999 and can be typed. Please update (older versions show "Invalid roll data" for DCs above 40).

1. Fill in the purpose at the top of the panel (e.g. "Perception: anyone behind the door?") and roll: does it show on the draft bubble, the sent bubble and the opened result? Is the field cleared afterwards?
2. In Messages, with the panel in the small drawer, tap the purpose field: does the panel expand and show the keyboard? (Also try after opening an earlier roll's result; it should not jump to that result.)
3. Tap the DC number and type a large one like 120, then Done: does it apply? And if you tap Roll straight away instead of Done, does the roll use the DC you just typed?
4. Friends who haven't updated yet: do messages with a purpose still show the result (just without the purpose)?
5. In the app: does the purpose show in the result area and the Recent list?

### 上一版：测试内容（What to Test）— 0.2.1（构建号 4）

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
