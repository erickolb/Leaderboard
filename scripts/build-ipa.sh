#!/bin/bash
set -euo pipefail

# SideStore supplies device signing. Ad-hoc signing below preserves entitlements
# for its importer without requiring an Apple account on this build machine.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
WORK="$(mktemp -d "$ROOT/build-ipa.XXXXXX")"
echo "Build workspace: $WORK"
mkdir -p "$ROOT/dist" "$WORK/Payload"
xcodebuild -project Leaderboard.xcodeproj -scheme Leaderboard \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath "${DERIVED_DATA_PATH:-$WORK/DerivedData}" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
  CURRENT_PROJECT_VERSION="${BUILD_NUMBER:-4}" build

APP="$WORK/Payload/Leaderboard.app"
ditto "${DERIVED_DATA_PATH:-$WORK/DerivedData}/Build/Products/Release-iphoneos/Leaderboard.app" "$APP"
EXT="$APP/PlugIns/LeaderboardShare.appex"
test -d "$EXT"
# Normalize XML (including line endings) for Apple's entitlement parser.
plutil -convert xml1 -o "$WORK/app-signing.plist" "$ROOT/Leaderboard/Leaderboard.entitlements"
plutil -convert xml1 -o "$WORK/extension-signing.plist" "$ROOT/LeaderboardShare/LeaderboardShare.entitlements"
while IFS= read -r -d '' framework; do
  codesign --force --sign - --timestamp=none "$framework"
done < <(find "$APP" -depth \( -name '*.framework' -o -name '*.dylib' \) -print0)
codesign --force --sign - --timestamp=none \
  --entitlements "$WORK/extension-signing.plist" "$EXT"
codesign --force --sign - --timestamp=none \
  --entitlements "$WORK/app-signing.plist" "$APP"
codesign --verify --deep --strict "$APP"
codesign -d --entitlements :- "$APP" > "$WORK/app-entitlements.plist" 2>/dev/null
codesign -d --entitlements :- "$EXT" > "$WORK/extension-entitlements.plist" 2>/dev/null
for file in "$WORK/app-entitlements.plist" "$WORK/extension-entitlements.plist"; do
  group=$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.application-groups:0' "$file")
  test "$group" = 'group.me.erickolb.Leaderboard'
done
(cd "$WORK" && /usr/bin/zip -qry Leaderboard.ipa Payload)
mv "$WORK/Leaderboard.ipa" "$ROOT/dist/Leaderboard.ipa"
shasum -a 256 "$ROOT/dist/Leaderboard.ipa"
echo "Ready for SideStore: $ROOT/dist/Leaderboard.ipa"
echo "Intermediate build files retained at $WORK"
