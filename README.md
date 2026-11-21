# MuseAutoAllow

A tiny macOS menu-bar app that automatically clicks **Allow once** when the Muse app asks
*"Allow … to upload this file using Browser?"*.

Muse only lets you save upload approval per site, so long-running automations that fill
forms on many different sites (job applications, etc.) keep stopping for approval. This
removes that one prompt and leaves every other approval (computer use, connectors, files)
untouched.

A small `m` glyph sits in the menu bar; its badge shows the state (✓ active, ‖ paused,
! needs Accessibility, ○ Muse not running). Click it for a Liquid Glass panel with
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

Every 2 seconds it reads Muse's windows through the Accessibility API. If a window contains
text with "to upload this file", it presses the button labelled **Allow once**. No mouse
movement, so Muse can stay in the background, as long as its window is open and the chat
with the prompt is showing.

## Security note

With this running, the Muse agent can upload files to **any** site without asking you.
Only run it while you trust the task you gave it.

## Build from source

```sh
./build.sh           # universal build/MuseAutoAllow.app + build/MuseAutoAllow.zip (needs Xcode 26 SDK)
./build.sh install   # also installs to ~/Applications and launches
```

Without a signing identity the build is ad-hoc signed, and macOS resets the Accessibility
grant on every rebuild. To keep it, create a self-signed code-signing certificate named
`MuseAutoAllow Local Signing` in your login keychain (Keychain Access → Certificate Assistant →
Create a Certificate → type *Code Signing*). `build.sh` uses it automatically, or set `IDENTITY=...`.

## License

MIT
