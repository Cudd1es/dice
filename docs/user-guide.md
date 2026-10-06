# DND Dice user guide

[简体中文](user-guide.zh-CN.md) · [Quick start](quick-start.md)

DND Dice rolls D&D 5e-style dice in two places that share the same panel:

- **The app**, for games at the table. The result shows on your screen, and recent rolls are listed below it.
- **Messages**, for games over chat. The roll is sent as a message, and nobody sees the result until it is sent.

The interface follows your phone's language: English or Simplified Chinese.

## The roll panel

From top to bottom:

| Control | What it does |
|---|---|
| **Purpose** | Optional, up to 40 characters, e.g. "Attack the goblin". Shown with the roll and cleared after each roll. The ✕ clears it; a counter appears past 30 characters. |
| **Die** | d4, d6, d8, d10, d12, d20, d100. This is the *main* die. |
| **Dice** | How many main dice, 1–20. |
| **Modifier** | A flat number added to the total, −20 to +20. |
| **Bonus** | Extra dice groups such as +1d4. See [Bonus dice](#bonus-dice). |
| **Normal / Advantage / Disadvantage** | Only available when the main dice are exactly 1d20. |
| **DC** | Optional target number, 1–999. Use − / + or tap the number to type it; tap **Done** or roll to apply it. If you leave the field empty, the DC stays as it was. |
| **Formula** | What will be rolled, e.g. `1d20+1d4+5 · Advantage · DC 15`. |
| **Roll** | Rolls. Always visible at the bottom of the panel. |

The panel remembers your last formula, bonus dice included, but not the purpose. The app and the Messages panel each remember their own.

### Bonus dice

Bonus dice are extra groups rolled after the main dice and added to (or subtracted from) the total. Typical uses: Bless or Guidance (+1d4), Bane (−1d4), or a damage combination such as Sneak Attack (`1d8+2d6+3`).

**Adding a bonus**
1. Tap **+ Bonus**.
2. Choose **Add** or **Subtract**.
3. Tap a die. It is added and you are back on the panel at once.

Tap the same kind again and it merges: +1d4 twice becomes +2d4.

**Changing one**

Tap its tag (e.g. **+2d4**) to get **One More**, **One Fewer** or **Remove**.

**Limits**
- Up to 4 groups, each 1–10 dice from d4 to d100.
- Once you have 4 groups, only kinds that merge into an existing group can be added.

**Rules**
- Advantage, disadvantage and criticals look only at the main d20. With advantage, the two d20s compete and every bonus die still counts.
- Bonus dice count toward the DC. A natural 20 on the main d20 still always succeeds, and a natural 1 always fails.
- A total can be zero or negative (e.g. `1d4-2d6`). It is shown as rolled.

## Reading a result

| Part | Example | Meaning |
|---|---|---|
| Total | **25** | Orange for a critical success, red for a critical failure |
| Breakdown | `[~~11~~, 16] + [4] + 5 = 25` | Main dice (a struck-through die was dropped by advantage or disadvantage), then each bonus group, then the modifier |
| Outcome | **Success** | Critical Success / Critical Failure on a natural 20 / 1 on the main d20; otherwise Success / Failure against the DC |

## Rolling in the app

The roller fills the screen:
- the latest result at the top;
- **Recent** (the last 10 rolls, newest first, each with its time, formula, total, outcome and purpose) in the middle;
- the panel at the bottom.

The phone gives a light tap on every roll and a stronger one on a critical. **Recent** is cleared when you close the app.

Tap **?** in the top right for the in-app guide.

## Rolling in Messages

1. In a conversation, tap **+** next to the text field and choose **DND Dice**.
2. Set your roll. Tapping the purpose or DC field expands the panel so the keyboard can show.
3. Tap **Roll**. A draft goes into the text field. It shows the purpose, the formula and "Revealed when sent", never the result.
4. Send it. The bubble shows the result to everyone, without anyone tapping it.
5. Tap a sent bubble to open the full result. **Roll Again** takes you back to the panel.

### Who sees what

| Person | Sees |
|---|---|
| You, before sending | Formula only, so a reroll can't help you |
| Everyone with DND Dice, after sending | The same result, each in their own phone's language |
| People without DND Dice | The formula and "Install DND Dice to see the result" |
| People on an older version | Rolls they can read show normally. Newer features show "Can't read this roll. Please update the app." Before 0.3.0, DCs above 40 also showed "Invalid roll data". |

Version notes:
- A purpose needs 0.3.0 or later to be seen.
- Bonus dice need 0.4.0 or later to be read.

## Troubleshooting

| Problem | Fix |
|---|---|
| The DND Dice panel in Messages is blank grey | Wait a moment, or swipe Messages away and reopen it. This can happen right after an update. |
| DND Dice is missing from the + list or has no icon | Restart the phone. iOS caches Messages app icons. |
| A bubble says "Can't read this roll. Please update the app." | Update DND Dice in TestFlight. |
| A bubble says "Invalid roll data" | The message was damaged or edited, or it was a DC above 40 read by a version before 0.3.0. |
| A friend only sees the formula and an install prompt | They need to install DND Dice. |
| The bubble is in a different language from the draft | Expected: each phone draws bubbles in its own language. |

## Fair play

The result is decided when you tap Roll and is hidden from everyone, you included, until the message is sent.

It is stored in plain text inside the message, though. This stops casual rerolling among friends but is not tamper-proof against someone determined to cheat.
