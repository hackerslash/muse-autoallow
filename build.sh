#!/bin/sh
set -e
APP=~/Applications/MuseAutoAllow.app
pkill -f MuseAutoAllow.app || true
rm -rf "$APP"
osacompile -s -o "$APP" "$(dirname "$0")/muse-autoallow.applescript"
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$APP/Contents/Info.plist"
codesign -f -s - "$APP"
open "$APP"
