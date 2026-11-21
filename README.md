# MuseAutoAllow

A tiny macOS menu-bar app that automatically clicks **Allow once** when the Muse app asks
*"Allow … to upload this file using Browser?"*.

Muse only lets you save upload approval per site, so long-running automations that fill
forms on many different sites (job applications, etc.) keep stopping for approval. This
removes that one prompt and leaves every other approval (computer use, connectors, files)
untouched.

The menu bar shows `M✓ <n>`, where `n` is the number of prompts clicked since launch.

> Not affiliated with or endorsed by Meta or the Muse app.

## Install

1. Download `MuseAutoAllow.zip` from [Releases](../../releases/latest) and unzip it.
2. Move `MuseAutoAllow.app` to `~/Applications` (or `/Applications`).
3. The app is not notarized. On first launch, right-click → **Open** → **Open**, or run:
   ```sh
   xattr -dr com.apple.quarantine ~/Applications/MuseAutoAllow.app
   ```
4. Grant Accessibility: **System Settings → Privacy & Security → Accessibility**, enable
   **applet** (that is MuseAutoAllow). Quit and reopen the app afterwards.
5. Optional: add it to **System Settings → General → Login Items**.

Quit from the menu-bar item.

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
./build.sh           # builds build/MuseAutoAllow.app and build/MuseAutoAllow.zip
./build.sh install   # also installs to ~/Applications and launches
```

Rebuilding changes the ad-hoc signature, so re-toggle Accessibility after each build.

## License

MIT
