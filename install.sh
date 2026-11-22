#!/bin/zsh
# Release build → single copy in /Applications (other copies deleted) → Finder extension registered and on.
set -euo pipefail
cd "${0:A:h}"
xcodegen generate >/dev/null
xcodebuild -project VideoInfo.xcodeproj -scheme VideoInfo -configuration Release -derivedDataPath build/dd -quiet build
APP="/Applications/Video Info.app"
pkill -x "Video Info" || true; pkill -x FinderExtension || true; pkill -x PreviewExtension || true
rm -rf "$APP"; ditto "build/dd/Build/Products/Release/Video Info.app" "$APP"
rm -rf build/dd/Build/Products/*/"Video Info.app"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"
pluginkit -a "$APP/Contents/PlugIns/FinderExtension.appex" "$APP/Contents/PlugIns/PreviewExtension.appex"
pluginkit -e use -i com.christoarmani.videoinfo.FinderExtension
codesign -dv "$APP" 2>&1 | grep TeamIdentifier
