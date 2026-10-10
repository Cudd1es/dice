# Roadmap

Last reviewed: 2026-10-09, at 0.6.3 (build 15).

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
| 0.5.1 | 10 | Bonus dice reset after every roll | #14 |
| 0.5.2 | 11 | Bonus picker buttons in the panel's neutral grey (0.5.1's blue read as "selected") | #14 |
| 0.6.0 | 12 | Settings page with the critical success / failure toggle (App Group); message version 3 | #15 |
| 0.6.1 | 13 | Accessibility pass (VoiceOver, largest text sizes), outcome colors with AA contrast, privacy manifests | #16 |
| 0.6.2 | 14 | Tapping a sent bubble opens the full result, with the whole purpose (checked on a device) | #17 |
| 0.6.3 | 15 | Bonus tags share the formula's row, so the compact Messages drawer fits with bonus dice | #17 |

## Waiting on a device check

These can't be checked in the simulator, because simulator bubbles are blank. They need a phone, and some need a second phone.

1. A bubble and its opened result with bonus dice
2. A 0.3.x phone receiving a bonus-dice roll shows "please update"
3. Pinyin in the purpose field: typing past 40 characters no longer breaks composition (the counter turns red); tapping Roll mid-composition sends the raw pinyin, as seen on the simulator
4. Long purpose: is the bubble's first line truncated cleanly and clear of the icon?
5. A tester other than the developer receives the rolls (the receiver's view in a group chat)
6. Haptics on Roll and on a critical, in the app
7. App Group in the TestFlight build: turning criticals off in the app takes effect in Messages
8. A 0.5.x phone receiving a roll with criticals off asks to update
9. VoiceOver (accessibility pass, after 0.6.0): the result card, a history row and a sent bubble each read as one sentence that names the kept die; Dice and Modifier adjust by swiping up or down; bonus tags say "Add 1d4" / "Subtract 1d4"
10. The Messages panel at the largest text sizes (now capped at accessibility2 like the app; the simulator's Messages was too hard to drive at that size)

## Known issues (deferred minors)

None of these breaks a roll or leaks a result. They are ordered by how likely a player is to notice. Fixed on `dev` (after 0.4.0): the compact drawer now fits (without bonus dice), the purpose is no longer cut mid-typing (red counter instead), the bonus picker closes when the drawer reopens, and bonus tags are keyed by group. Fixed in the accessibility pass (after 0.6.0): 2, 4 and 9. Fixed after 0.6.2: 1.

| # | Issue | Where | Suggested fix |
|---|---|---|---|
| ~~1~~ | ~~With bonus dice in the compact Messages drawer, the formula row sits just below the fold~~ Fixed: the formula shares the tags' row (`TagsAndFormulaLayout`, split by `RowSplit`); with many groups the tags scroll and the formula shrinks, then truncates | `Shared/RollPanelView.swift`, `Shared/BonusControls.swift` | — |
| ~~2~~ | ~~With a purpose at the largest text sizes, the result card's breakdown is below the fold~~ Fixed: the outcome sits beside the total, the purpose keeps one line and the total shrinks at accessibility sizes | `Shared/ResultCard.swift` | — |
| 3 | A pasted DC that overflows `Int` or uses full-width digits (`１２０`) keeps the old DC | `PanelModel.setDC(text:)` | Normalize digits; treat long digit runs as 999 |
| ~~4~~ | ~~VoiceOver: the Add/Subtract control is labelled "Bonus Dice", and "−1d6" may read poorly~~ Fixed with accessibility labels | `Shared/BonusPickerView.swift`, `BonusTags` | — |
| 5 | A DC typed while the panel is swapped for a result (tapping a sent bubble mid-edit) is dropped | `DCControls` | Commit `dcDraft` when the panel disappears |
| 6 | `x=%2B1d4` (an explicit "+") also decodes: same roll, a non-canonical URL | `MessageCodec.parseExtras` | Require ASCII digits only |
| 7 | `RevealState.ignoreNextExpand` can stay set within one activation (no visible effect found) | `DiceMessages/RevealState.swift` | Clear it on every expand |
| 8 | The panel's height cap is `nil` for the first frame (a possible one-frame jump of Recent) | `RollPanelView` | Seed an estimate |
| ~~9~~ | ~~The history row's formula is cut off on one line~~ Fixed: it wraps to two lines (the audit found it cut off even without "No crits") | `DiceApp/RollerView.swift` `HistoryRow` | — |
| 10 | At accessibility text sizes the app's Recent list has no height left (the panel and result take the screen) | `DiceApp/RollerView.swift` | A Recent sheet behind a toolbar button at accessibility sizes |
| 11 | Contrast below WCAG AA (Xcode's audit) on the selected die and bonus tags (blue on light blue) and system grey secondary text. Kept on purpose: system styles. The outcome and critical total colors were fixed (darker in light mode, 4.6:1 or more) | `RollPanelView`, `BonusTags` | `.borderedProminent` for the selected die, if it ever matters |
| 12 | With VoiceOver, the DC can only be changed with the stepper (the type-in field sits inside the stepper's label) | `Shared/DCControls.swift` | A separate "Type DC" accessibility action |

## Tech debt

- ~~`RollPanelView` was the largest file (about 270 lines).~~ Split into `PurposeField`, `DCControls` and `BonusControls` (now about 180 lines).
- **View wiring has few automated tests.** Focus order, keyboard expansion and the picker swap are checked by hand. Model logic is covered (DiceKit 97 tests, DiceMessagesTests 80 tests). The `Accessibility` scheme (`DiceAppUITests`) runs Xcode's accessibility audit over the roller, a result, the bonus picker and Settings; it fails on missing labels and the like, and prints contrast, Dynamic Type and clipped-text findings (the clipped-text check also flags text that shows in full, so read those by eye). Run it before a release; it is not in CI.
- **Device-only acceptance is manual for every release.** Keep the "Waiting on a device check" list current.

## Before 1.0 (App Store)

- [x] **Privacy manifest** (`PrivacyInfo.xcprivacy`) in the app and the extension (on `dev`, ships with the next build): no tracking, no data collected; `UserDefaults` declared with `CA92.1` (`SpecStore`, the app's own defaults) and `1C8F.1` (`SettingsStore`, the App Group). Add a reason here whenever new code uses another required-reason API (file timestamps, system boot time, disk space, keyboards).
- [ ] App Store listing: copy, URLs, privacy and age rating answers drafted in [`docs/app-store/listing.md`](app-store/listing.md) (privacy policy and support pages in `docs/`); the app is iPhone-only (no iPad screenshots). Renamed to 掷定 / Dicide ("DND" risked a trademark rejection; the Home Screen name follows the language through `InfoPlist.xcstrings`; bundle IDs unchanged). Left: screenshots, rename the app in App Store Connect, fill it in
- [x] Protect `main`: ruleset "Protect main" (2026-10-10) requires a pull request (no approvals needed), the `DiceKit tests` and `App and extension` checks, merge commits only (squash or rebase would leave `dev` behind `main`); no force pushes, no deletion, no bypass
- [x] Clear known issue 1 above (on `dev`)
- [x] An accessibility pass: VoiceOver labels, largest text sizes, outcome colors with AA contrast (on `dev`; device checks 9 and 10 above)
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
1. Run the device checks above on 0.6.3.
2. The rest of the before-1.0 list: the App Store listing.
