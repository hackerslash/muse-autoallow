#!/bin/sh
# Usage: ./build.sh            build + zip into ./build
#        ./build.sh install    also install to ~/Applications and launch
set -e
cd "$(dirname "$0")"
APP=build/MuseAutoAllow.app
rm -rf build && mkdir build
osacompile -s -o "$APP" muse-autoallow.applescript
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier io.github.hackerslash.muse-autoallow" "$APP/Contents/Info.plist" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string io.github.hackerslash.muse-autoallow" "$APP/Contents/Info.plist"
codesign -f -s - "$APP"
ditto -c -k --keepParent "$APP" build/MuseAutoAllow.zip
echo "built $APP and build/MuseAutoAllow.zip"

if [ "$1" = install ]; then
  pkill -f MuseAutoAllow.app || true
  rm -rf ~/Applications/MuseAutoAllow.app
  cp -R "$APP" ~/Applications/
  open ~/Applications/MuseAutoAllow.app
fi
