#!/bin/bash
# Build a distributable DMG for Smart Menu.
#
# Usage:
#   scripts/make-dmg.sh                       # unsigned DMG (local testing only)
#   SIGN_ID="Developer ID Application: NAME (TEAMID)" scripts/make-dmg.sh
#
# After signing, notarize and staple (see README / publishing notes):
#   xcrun notarytool submit build/SmartMenu.dmg --keychain-profile notary --wait
#   xcrun stapler staple build/SmartMenu.dmg

set -euo pipefail

APP_NAME="SmartMenu"
VOL_NAME="Smart Menu"
APP="build/DerivedData/Build/Products/Release/${APP_NAME}.app"
STAGE="build/dmg"
DMG="build/${APP_NAME}.dmg"

[ -d "$APP" ] || { echo "error: $APP not found — run 'make build' first." >&2; exit 1; }

# Optionally code-sign the app with a Developer ID identity (required for notarization).
if [ -n "${SIGN_ID:-}" ]; then
  echo "Signing app with: $SIGN_ID"
  codesign --force --deep --options runtime --timestamp --sign "$SIGN_ID" "$APP"
  codesign --verify --strict --verbose=2 "$APP"
fi

# Stage the app plus an /Applications shortcut for drag-to-install.
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG"

if [ -n "${SIGN_ID:-}" ]; then
  codesign --force --sign "$SIGN_ID" "$DMG"
fi

rm -rf "$STAGE"
echo "Created $DMG"
