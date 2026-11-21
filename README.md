# MuseAutoAllow

A tiny macOS menu-bar app that automatically clicks **Allow once** when the Muse app asks
*"Allow … to upload this file using Browser?"*.

Muse only lets you save upload approval per site, so long-running automations that fill
forms on many different sites (job applications, etc.) keep stopping for approval. This
removes that one prompt and leaves every other approval (computer use, connectors, files)
untouched.

The menu-bar mark carries a badge for its state (✓ active, ‖ paused, ! needs
Accessibility, ○ Muse not running). Click it for a Liquid Glass panel with
session/all-time counts, the recent uploads it approved (site + file), a pause switch,
and launch at login.

Requires macOS 26 or later.

> Not affiliated with or endorsed by Meta or the Muse app.

## Install

1. Download `MuseAutoAllow.zip` from [Releases](../../releases/latest) and unzip it.
2. Move `MuseAutoAllow.app` to `~/Applications` (or `/Applications`).
3. The app is not notarized. On first launch, right-click → **Open** → **Open**, or run:
   ```sh
   xattr -dr com.apple.quarantine ~/Applications/MuseAutoAllow.app
   ```
4. Grant Accessibility when prompted (or from the panel's button), enable
   **MuseAutoAllow**, then quit and reopen the app.

Pause, launch at login and Quit are in the panel.

## How it works

Every 2 seconds it reads Muse's windows through the Accessibility API. It presses
**Allow once** only inside the card that asks to upload a file (the one offering "Always
allow uploads to this site"); if that card can't be told apart from another pending
approval, it does nothing. No mouse
movement, so Muse can stay in the background, as long as its window is open and the chat
with the prompt is showing.

## Security note

With this running, the Muse agent can upload files to **any** site without asking you.
Only run it while you trust the task you gave it.

## Build from source

```sh
./build.sh           # runs the self-check, then builds universal build/MuseAutoAllow.app + .zip (Xcode 26 SDK)
./build.sh install   # also installs to ~/Applications and launches
```

Without a signing identity the build is ad-hoc signed, and macOS resets the Accessibility
grant on every rebuild. To keep it, create a self-signed code-signing certificate named
`MuseAutoAllow Local Signing` in your login keychain (Keychain Access → Certificate Assistant →
Create a Certificate → type *Code Signing*). `build.sh` uses it automatically, or set `IDENTITY=...`.

`icon.swift` regenerates `AppIcon.icns` and `MenuMark.png` from `icon-source.png`.

## License

MIT
