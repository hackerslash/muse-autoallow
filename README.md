<p align="center"><img src="logo.png" width="128" alt="MuseAutoAllow"></p>

<h1 align="center">MuseAutoAllow</h1>

<p align="center">Menu-bar app for macOS that auto-approves Muse's <b>"Allow … to upload this file?"</b> prompts, so browser automations don't stall on every new site.</p>

<p align="center">
  <a href="../../releases/latest"><img src="https://img.shields.io/github/v/release/hackerslash/muse-autoallow" alt="release"></a>
  <img src="https://img.shields.io/badge/macOS-26%2B-black" alt="macOS 26+">
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT">
</p>

- Presses **Allow once** only on upload prompts. Every other approval still asks you.
- Optional switch to also approve Muse's "access this sensitive site" prompts (off by default).
- Works with any agent name; needs Muse's UI in English.
- Status badge in the menu bar: ✓ active, ‖ paused, ! needs Accessibility, ○ Muse not running.
- Liquid Glass panel with session and all-time counts, recent uploads, pause and launch at login.
- Works with Muse in the background (no mouse movement).

## Install

1. Download `MuseAutoAllow.zip` from [Releases](../../releases/latest), unzip, move to Applications.
2. It isn't notarized: right-click → **Open**, or `xattr -dr com.apple.quarantine /path/to/MuseAutoAllow.app`.
3. Allow **MuseAutoAllow** in System Settings → Privacy & Security → Accessibility.

> [!WARNING]
> While it runs, the Muse agent can upload files to any site without asking. Pause it when you're not watching a task you trust.

## Build

```sh
./build.sh           # self-check + universal .app and .zip in build/
./build.sh install   # also installs to ~/Applications and launches
```

Ad-hoc builds lose the Accessibility grant on every rebuild. Create a code-signing certificate named `MuseAutoAllow Local Signing` (Keychain Access → Certificate Assistant) and trust it for code signing to keep it. `build.sh` picks it up automatically.

---

MIT · Not affiliated with Meta or Muse.
