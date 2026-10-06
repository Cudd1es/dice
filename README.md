# DND Dice

[简体中文](README.zh-CN.md)

Dice for D&D 5e / Baldur's Gate style tabletop games. You can roll them two ways: right inside a Messages conversation, or in the app itself when everyone is at the same table. The interface is in English or Simplified Chinese, following the system language.

- **For players:** [Quick start](docs/quick-start.md) · [User guide](docs/user-guide.md)
- **For developers:** read on.

## Features

- d4 / d6 / d8 / d10 / d12 / d20 / d100, 1–20 dice, modifier −20…+20
- Advantage / disadvantage and critical success / failure on a single d20
- Optional DC from 1 to 999; you can step it or type it in. A natural 20 always succeeds and a natural 1 always fails.
- **Bonus dice:** up to 4 groups after the main dice, each 1–10 dice from d4 to d100, added or subtracted. Examples: Bless `1d20+1d4`, Bane `1d20-1d4`, damage `1d8+2d6+3`. Advantage and criticals look only at the main dice.
- **Purpose:** an optional line of up to 40 characters, such as "Perception: anyone behind the door?". It travels with the roll and is cleared after each one.
- **In the app:** a big result, plus the last 10 rolls (kept until the app closes)
- **In Messages:**
  - the result is fixed when you tap Roll but stays hidden until the message is sent;
  - after that, the bubble shows it to everyone.

## Keeping rolls honest

1. Tapping Roll fixes the result and writes it into the message.
2. The panel and the draft bubble show only the formula, such as `1d20+5 · Advantage · DC 15 / Revealed when sent`.
3. Once the message is sent, the bubble shows the total, the breakdown and the outcome without being tapped.

The sender never sees the result before sending, so deleting the draft and rolling again gains nothing.

**People without the app** see the formula and "Install DND Dice to see the result". They can't see the result either.

**Language:**
- Each recipient's own app draws the bubble, so everyone reads it in their own language.
- The draft and the fallback text are in the sender's language.

**This is a courtesy guard, not cryptography.** The result is in plain text in the message URL, so anyone technical can read it.

## Build and run

You need:
- Xcode 16 or later (developed with Xcode 26.2);
- an iOS 17+ simulator or device;
- [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
```

The `.xcodeproj` is not committed; generate it from `project.yml`:

```bash
xcodegen generate
```

```bash
open Dice.xcodeproj
```

Run the `DiceApp` scheme.

- **Roll in the app:** the app opens on the roller.
- **Roll in Messages:** open Messages, pick a conversation, tap **+** next to the text field and choose DND Dice.

> **Bubbles only render on a device.** The simulator's Messages doesn't let a bubble read its own message, so bubbles show up blank there (see the [Live Layout spike](docs/superpowers/spikes/2026-10-05-live-layout.md)). The panels and every unit test work on the simulator.

## Tests

The rules, the message format and the wording live in the Swift package `DiceKit`, which needs no Xcode project:

```bash
swift test --package-path DiceKit
```

Panel logic, screen routing and message building for the extension:

```bash
xcodebuild test -project Dice.xcodeproj -scheme DiceApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:DiceMessagesTests
```

Change the simulator name to one you have.

CI (GitHub Actions, `.github/workflows/ci.yml`) runs both suites on every pull request and every push to `main`.

## Versions and releases

**Version numbers**
- `MARKETING_VERSION` follows [SemVer](https://semver.org) `major.minor.patch`. It stays `0.x.y` while in TestFlight and becomes `1.0.0` for the App Store. App Store Connect rejects suffixes such as `-beta`.
- `CURRENT_PROJECT_VERSION` (the build number) is an integer that **must go up with every upload**. It never resets.

**Releasing**

```bash
scripts/release.sh 0.4.1
```

1. The script bumps the build number and regenerates the project.
2. It runs both test suites, archives, and asks before uploading to App Store Connect. `--yes` skips the question; `--no-upload` stops after the archive.
3. After a successful upload it commits the version bump. If anything fails, it restores `project.yml`.

It needs Xcode signed in to the team's Apple ID. `Failed to Use Accounts` means you have to sign in again under Xcode → Settings → Accounts.

**TestFlight**

After uploading:
1. add the build to the tester groups;
2. paste "What to Test" from [docs/testflight/beta-info.md](docs/testflight/beta-info.md).

**Message format**
- The current version is `v=2`. Rolls without bonus dice are still written as `v=1`, so older apps keep reading them.
- An app that meets a newer version asks the user to update.
- Any format change must keep that promise; see `DiceKit/Sources/DiceKit/MessageCodec.swift`.

## Project layout

```
DiceKit/            Swift package: RollSpec, BonusDice, DiceEngine, MessageCodec, RollFormatter, RollHistory
Shared/             Code shared by the app and the extension: roll panel, bonus picker, result card, formula store,
                    string catalog
DiceApp/            Host app: roller (RollerView) and in-app guide (GuideView)
DiceMessages/       iMessage extension: bubbles, result detail, message building
DiceMessagesTests/  Unit tests for the extension and the shared panel
scripts/            release.sh (TestFlight), make_icons.py (icons; needs Pillow)
docs/               Player docs, TestFlight notes, design history (docs/superpowers)
project.yml         XcodeGen project definition
```

## Design history

Each feature went through spec → plan → implementation. The documents are in Chinese.

| Feature | Spec | Plan |
|---|---|---|
| iMessage dice | [spec](docs/superpowers/specs/2026-10-05-imessage-dice-design.md) | [plan](docs/superpowers/plans/2026-10-05-imessage-dice.md) |
| Rolling in the app | [spec](docs/superpowers/specs/2026-10-06-in-app-roller-design.md) | [plan](docs/superpowers/plans/2026-10-06-in-app-roller.md) |
| Roll purpose, DC up to 999 | [spec](docs/superpowers/specs/2026-10-06-roll-purpose-design.md) | [plan](docs/superpowers/plans/2026-10-06-roll-purpose.md) |
| Bonus dice | [spec](docs/superpowers/specs/2026-10-06-bonus-dice-design.md) | [plan](docs/superpowers/plans/2026-10-06-bonus-dice.md) |

What's next, and the known gaps: [roadmap](docs/roadmap.md).

## Status

The latest TestFlight build is **0.4.0 (build 8)**.

**Verified on a device (iPhone 14 Pro, iOS 26.6):**
- the draft shows only the formula;
- the sent bubble reveals the result and survives scrolling and relaunching;
- the bubble icon and layout are correct;
- the purpose field works in Messages.

**Not yet verified on a device:**
- bubbles with bonus dice;
- 0.3.x asking to update when it receives a bonus-dice roll;
- tapping Roll while a pinyin composition is still open.

The full list is in the [roadmap](docs/roadmap.md).

## License

[MIT](LICENSE)
