# Roadmap

Last reviewed: 2026-10-06, at 0.4.0 (build 8). `main` = `dev` = PR #10 merged, CI green.

## Shipped

| Version | Build | What | PR |
|---|---|---|---|
| 0.1.0 | 2 | iMessage dice (hidden until sent) and rolling in the app | #1–#5 |
| 0.2.0 | 3 | English UI, "DND Dice" name, app icon | #6 |
| 0.2.1 | 4 | iMessage icon fixed with a new extension bundle ID; CI and `release.sh` | #7, #8 |
| 0.3.0 | 5 | Roll purpose; DC up to 999, typed input | #9 |
| 0.3.1 | 6 | Bubble first line clears the Messages app icon | #9 |
| 0.3.2 | 7 | Filled purpose field with clear button and counter | #9 |
| 0.4.0 | 8 | Bonus dice (`1d20+1d4`, `1d8+2d6+3`) | #10 |

## Waiting on a device check

These can't be checked in the simulator, because simulator bubbles are blank. They need a phone, and some need a second phone.

1. A bubble and its opened result with bonus dice
2. A 0.3.x phone receiving a bonus-dice roll shows "please update"
3. Tapping Roll while a pinyin composition is still open in the purpose field: is the purpose lost, or left behind in the field?
4. Long purpose: is the bubble's first line truncated cleanly and clear of the icon?
5. A tester other than the developer receives the rolls (the receiver's view in a group chat)
6. Haptics on Roll and on a critical, in the app

## Known issues (deferred minors)

None of these breaks a roll or leaks a result. They are ordered by how likely a player is to notice.

| # | Issue | Where | Suggested fix |
|---|---|---|---|
| 1 | In the compact Messages drawer, the DC and formula rows sit below the fold (the trade-off for keeping Roll fully visible) | `Shared/RollPanelView.swift` | Put "+ Bonus" in an existing row when there are no bonus dice; tighten spacing |
| 2 | Pinyin input: the 40-character cut can break an open composition, and Roll may miss uncommitted text | `RollPanelView.purposeField` | Skip the cut while `markedTextRange` is set (needs a UIKit text field), or cut only on roll |
| 3 | The bonus picker stays open when the Messages drawer is reopened | `PanelModel.isPickingBonus` | Reset in `MessagesViewController.willBecomeActive` |
| 4 | With a purpose at the largest text sizes, the result card's breakdown is below the fold (the card scrolls) | `Shared/ResultCard.swift` | Smaller total font when a purpose is shown |
| 5 | A pasted DC that overflows `Int` or uses full-width digits (`１２０`) keeps the old DC | `PanelModel.setDC(text:)` | Normalize digits; treat long digit runs as 999 |
| 6 | VoiceOver: the Add/Subtract control is labelled "Bonus Dice", and "−1d6" may read poorly | `Shared/BonusPickerView.swift`, `bonusRow` | Add accessibility labels |
| 7 | Bonus tags are identified by position (`id: \.offset`), so identity is reused after a removal | `bonusRow` | `id: \.element` (sign and sides are unique) |
| 8 | A DC typed while the panel is swapped for a result (tapping a sent bubble mid-edit) is dropped | `RollPanelView` | Commit `dcDraft` when the panel disappears |
| 9 | `x=%2B1d4` (an explicit "+") also decodes: same roll, a non-canonical URL | `MessageCodec.parseExtras` | Require ASCII digits only |
| 10 | `RevealState.ignoreNextExpand` can stay set within one activation (no visible effect found) | `DiceMessages/RevealState.swift` | Clear it on every expand |
| 11 | The panel's height cap is `nil` for the first frame (a possible one-frame jump of Recent) | `RollPanelView` | Seed an estimate |

## Tech debt

- **`RollPanelView` is the largest file (about 270 lines).** It holds the purpose field, DC editing, bonus row, steppers and focus handling. Split it into `PurposeField`, `DCRow` and `BonusRow` views before adding presets.
- **View wiring has no automated tests.** Focus order, keyboard expansion and the picker swap are checked by hand. Model logic is covered (DiceKit 79 tests, DiceMessagesTests 55 tests). A small XCUITest smoke test of the app (roll, add a bonus, type a purpose) would catch layout regressions like the half-visible Roll button.
- **Device-only acceptance is manual for every release.** Keep the "Waiting on a device check" list current.

## Before 1.0 (App Store)

- [ ] **Privacy manifest** (`PrivacyInfo.xcprivacy`) for the app and the extension. `SpecStore` uses `UserDefaults`, a required-reason API (reason `CA92.1`). App Store review expects it to be declared.
- [ ] App Store listing: description, keywords, screenshots (app and Messages), age rating, privacy "Data Not Collected"
- [ ] Protect `main` (require PRs and passing CI); it is unprotected today
- [ ] Clear known issues 1–3 above
- [ ] An accessibility pass: VoiceOver labels, largest text sizes
- [ ] `MARKETING_VERSION` 1.0.0 through `scripts/release.sh 1.0.0`

## Next features

| Candidate | Notes |
|---|---|
| **Bonus presets** (planned) | "Bless +1d4", "Bane −1d4", "Guidance +1d4" in the space reserved under the bonus picker; one tap adds and returns. Small, since it builds on `addBonus`. |
| Saved formulas | Name and reuse whole rolls ("Longsword", "Fireball 8d6"). Needs storage and a list UI. |
| Roll history in Messages | The extension has none today. |
| Dice sounds / animation | Out of scope so far; the app uses haptics only. |

Suggested order:
1. Clear known issues 1–3, together with the `RollPanelView` split.
2. Bonus presets.
3. The before-1.0 list.
