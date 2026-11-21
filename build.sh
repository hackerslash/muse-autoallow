#!/bin/sh
# Usage: ./build.sh            build + zip into ./build
#        ./build.sh install    also install to ~/Applications and launch
set -e
cd "$(dirname "$0")"
VERSION=${VERSION:-0.2.0}
APP=build/MuseAutoAllow.app
rm -rf build/MuseAutoAllow.app build/bin-* build/selftest && mkdir -p "$APP/Contents/MacOS"
swiftc -swift-version 5 -parse-as-library -D SELFTEST main.swift selftest.swift -o build/selftest
build/selftest
for arch in arm64 x86_64; do
  swiftc -O -swift-version 5 -parse-as-library -target $arch-apple-macos26 main.swift -o build/bin-$arch
done
lipo -create build/bin-* -output "$APP/Contents/MacOS/MuseAutoAllow"
mkdir -p "$APP/Contents/Resources" && cp AppIcon.icns MenuMark.png "$APP/Contents/Resources/"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleExecutable</key><string>MuseAutoAllow</string>
  <key>CFBundleIdentifier</key><string>io.github.hackerslash.muse-autoallow</string>
  <key>CFBundleName</key><string>MuseAutoAllow</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>26.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
# A stable identity keeps the Accessibility grant across rebuilds; ad-hoc (-) resets it every build.
IDENTITY=${IDENTITY:-$(security find-identity -p codesigning | grep -q "MuseAutoAllow Local Signing" && echo "MuseAutoAllow Local Signing" || echo -)}
codesign -f -s "$IDENTITY" "$APP"
ditto -c -k --keepParent "$APP" build/MuseAutoAllow.zip
echo "built $APP and build/MuseAutoAllow.zip"

if [ "$1" = install ]; then
  pkill -f MuseAutoAllow.app || true
  rm -rf ~/Applications/MuseAutoAllow.app
  cp -R "$APP" ~/Applications/
  open ~/Applications/MuseAutoAllow.app
fi
