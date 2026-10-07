# Roadmap

Last reviewed: 2026-10-06, at 0.5.1 (build 10).

## Shipped

| Version | Build | What | PR |
|---|---|---|---|
| 0.1.0 | 2 | iMessage dice (hidden until sent) and rolling in the app | #1–#5 |
| 0.2.0 | 3 | English UI, "DND Dice" name, app icon | #6 |
| 0.2.1 | 4 | iMessage icon fixed with a new extension bundle ID; CI and `release.sh` | #7, #8 |
| 0.3.0 | 5 | Roll purpose; DC up to 999, typed input | #9 |
| 0.3.1 | 5 | Bubble first line clears the Messages app icon | #9 |
| 0.3.2 | 6 | Filled purpose field with clear button and counter | #9 |
| 0.4.0 | 7 | Bonus dice (`1d20+1d4`, `1d8+2d6+3`) | #10 |
| 0.5.0 | 8 | Bonus presets; compact drawer fits; purpose not cut mid-typing; picker resets | #12 |
| 0.5.1 | 10 | Bonus dice reset after every roll (its blue picker buttons were reverted: they read as "selected") | #14 |

## Waiting on a device check

These can't be checked in the simulator, because simulator bubbles are blank. They need a phone, and some need a second phone.

1. A bubble and its opened result with bonus dice
2. A 0.3.x phone receiving a bonus-dice roll shows "please update"
3. Pinyin in the purpose field: typing past 40 characters no longer breaks composition (the counter turns red); tapping Roll mid-composition sends the raw pinyin, as seen on the simulator
4. Long purpose: is the bubble's first line truncated cleanly and clear of the icon?
5. A tester other than the developer receives the rolls (the receiver's view in a group chat)
6. Haptics on Roll and on a critical, in the app

## Known issues (deferred minors)

None of these breaks a roll or leaks a result. They are ordered by how likely a player is to notice. Fixed on `dev` (after 0.4.0): the compact drawer now fits (without bonus dice), the purpose is no longer cut mid-typing (red counter instead), the bonus picker closes when the drawer reopens, and bonus tags are keyed by group.

| # | Issue | Where | Suggested fix |
|---|---|---|---|
| 1 | With bonus dice in the compact Messages drawer, the formula row sits just below the fold (the tags row shows the bonuses) | `Shared/RollPanelView.swift` | Show the formula in the tags row, or shorten the purpose field |
| 2 | With a purpose at the largest text sizes, the result card's breakdown is below the fold (the card scrolls) | `Shared/ResultCard.swift` | Smaller total font when a purpose is shown |
| 3 | A pasted DC that overflows `Int` or uses full-width digits (`１２０`) keeps the old DC | `PanelModel.setDC(text:)` | Normalize digits; treat long digit runs as 999 |
| 4 | VoiceOver: the Add/Subtract control is labelled "Bonus Dice", and "−1d6" may read poorly | `Shared/BonusPickerView.swift`, `BonusTags` | Add accessibility labels |
| 5 | The bonus picker's buttons are a little faint against the Messages drawer background. A light blue fill was tried in 0.5.1 and reverted: it reads as "selected" | `Shared/BonusPickerView.swift` | A darker neutral fill, or a thin outline |
| 6 | A DC typed while the panel is swapped for a result (tapping a sent bubble mid-edit) is dropped | `DCControls` | Commit `dcDraft` when the panel disappears |
| 7 | `x=%2B1d4` (an explicit "+") also decodes: same roll, a non-canonical URL | `MessageCodec.parseExtras` | Require ASCII digits only |
| 8 | `RevealState.ignoreNextExpand` can stay set within one activation (no visible effect found) | `DiceMessages/RevealState.swift` | Clear it on every expand |
| 9 | The panel's height cap is `nil` for the first frame (a possible one-frame jump of Recent) | `RollPanelView` | Seed an estimate |

## Tech debt

- ~~`RollPanelView` was the largest file (about 270 lines).~~ Split into `PurposeField`, `DCControls` and `BonusControls` (now about 180 lines).
- **View wiring has no automated tests.** Focus order, keyboard expansion and the picker swap are checked by hand. Model logic is covered (DiceKit 79 tests, DiceMessagesTests 55 tests). A small XCUITest smoke test of the app (roll, add a bonus, type a purpose) would catch layout regressions like the half-visible Roll button.
- **Device-only acceptance is manual for every release.** Keep the "Waiting on a device check" list current.

## Before 1.0 (App Store)

- [ ] **Privacy manifest** (`PrivacyInfo.xcprivacy`) for the app and the extension. `SpecStore` uses `UserDefaults`, a required-reason API (reason `CA92.1`). App Store review expects it to be declared.
- [ ] App Store listing: description, keywords, screenshots (app and Messages), age rating, privacy "Data Not Collected"
- [ ] Protect `main` (require PRs and passing CI); it is unprotected today
- [ ] Clear known issues 1–2 above
- [ ] An accessibility pass: VoiceOver labels, largest text sizes
- [ ] `MARKETING_VERSION` 1.0.0 through `scripts/release.sh 1.0.0`

## Next features

| Candidate | Notes |
|---|---|
| ~~Bonus presets~~ | Shipped in 0.5.0: Bless, Guidance, Bane, Bardic Inspiration d6–d12, Hunter's Mark, Hex, Divine Favor, Divine Smite (SRD 5.2.1). |
| More presets | Candidates the SRD also has but that need a choice the app can't know: Sneak Attack (scales by level), higher-slot Divine Smite. |
| Saved formulas | Name and reuse whole rolls ("Longsword", "Fireball 8d6"). Needs storage and a list UI. |
| Roll history in Messages | The extension has none today. |
| Dice sounds / animation | Out of scope so far; the app uses haptics only. |

Suggested order:
1. Run the device checks above on 0.5.0.
2. The before-1.0 list, starting with the privacy manifest and the accessibility pass (known issues 2 and 4).
