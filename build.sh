#!/bin/zsh
# ./build.sh            build build/Twain.app
# ./build.sh install    build, copy to /Applications, relaunch
#
# Signing matters: macOS ties the Accessibility grant to the code signature, so
# a stable identity keeps the permission across rebuilds. Ad-hoc signing works
# but you'll have to re-grant after every build. Override with TWAIN_SIGN_ID.
set -euo pipefail
cd "${0:A:h}"

APP=build/Twain.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -wmo -swift-version 5 -target "$(uname -m)-apple-macos13.0" \
  Sources/*.swift -o "$APP/Contents/MacOS/Twain"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

ID="${TWAIN_SIGN_ID:-}"
if [[ -z "$ID" ]]; then
  ids=$(security find-identity -v -p codesigning 2>/dev/null || true)
  ID=$(print -r -- "$ids" | awk '/Developer ID Application/ {print $2; exit}')
  [[ -n "$ID" ]] || ID=$(print -r -- "$ids" | awk '/Apple Development/ {print $2; exit}')
  [[ -n "$ID" ]] || ID="-"
fi
codesign --force --sign "$ID" --identifier io.ft.twain "$APP"
[[ "$ID" == "-" ]] && echo "warning: ad-hoc signed; Accessibility must be re-granted after each build"
echo "built $APP"

if [[ "${1:-}" == "install" ]]; then
  pkill -x Twain 2>/dev/null || true
  rm -rf /Applications/Twain.app
  cp -R "$APP" /Applications/Twain.app
  open /Applications/Twain.app
  echo "installed and launched /Applications/Twain.app"
fi
