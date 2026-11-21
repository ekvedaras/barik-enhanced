#!/usr/bin/env bash
# Builds Barik.app with SwiftPM only (no Xcode, no actool) into ~/Applications or the given dir (CI).
# Usage: scripts/build-app.sh [destination-dir]
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
dest_dir="${1:-$HOME/Applications}"
app="$dest_dir/Barik.app"
bundle_id="com.ekvedaras.Barik"
sources="$repo/BarikEnhanced"
assets="$sources/Resources/Assets.xcassets"
pbxproj="$repo/BarikEnhanced.xcodeproj/project.pbxproj"

build_setting() {
  grep "$1 = " "$pbxproj" | tail -1 | sed -E 's/.*= "?([^";]*)"?;/\1/'
}

cd "$repo"
swift build -c release
binary="$(swift build -c release --show-bin-path)/Barik"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
staged="$work/Barik.app"
mkdir -p "$staged/Contents/MacOS" "$staged/Contents/Resources"
cp "$binary" "$staged/Contents/MacOS/Barik"

plist="$staged/Contents/Info.plist"
cp "$sources/Info.plist" "$plist"
set_key() { plutil -replace "$1" -string "$2" "$plist"; }
set_key CFBundleIdentifier "$bundle_id"
set_key CFBundleName "Barik"
set_key CFBundleDisplayName "Barik"
set_key CFBundleExecutable "Barik"
set_key CFBundlePackageType "APPL"
set_key CFBundleIconFile "AppIcon"
set_key CFBundleShortVersionString "$(build_setting MARKETING_VERSION)"
set_key CFBundleVersion "$(build_setting CURRENT_PROJECT_VERSION)"
set_key LSMinimumSystemVersion "14.0"
set_key LSApplicationCategoryType "$(build_setting INFOPLIST_KEY_LSApplicationCategoryType)"
set_key NSAppleEventsUsageDescription "$(build_setting INFOPLIST_KEY_NSAppleEventsUsageDescription)"
set_key NSCalendarsUsageDescription "$(build_setting INFOPLIST_KEY_NSCalendarsUsageDescription)"
set_key NSCalendarsFullAccessUsageDescription "$(build_setting INFOPLIST_KEY_NSCalendarsUsageDescription)"
set_key NSLocationWhenInUseUsageDescription "$(build_setting INFOPLIST_KEY_NSLocationWhenInUseUsageDescription)"
set_key NSHumanReadableCopyright "$(build_setting INFOPLIST_KEY_NSHumanReadableCopyright)"
plutil -lint "$plist" >/dev/null

# Asset catalog stand-ins: colors live in SwiftPM/AssetColors.swift; images ship as loose files,
# which NSImage(named:) finds in Contents/Resources.
cp "$assets/CodexIcon.imageset/codex-icon.png" "$staged/Contents/Resources/CodexIcon.png"
cp "$assets/ClaudeIcon.imageset/claude-icon.svg" "$staged/Contents/Resources/ClaudeIcon.svg"

iconset="$work/AppIcon.iconset"
mkdir -p "$iconset"
icons="$assets/AppIcon.appiconset"
for size in 16 32 128 256 512; do
  case $size in 16) one=16 two=17 ;; 32) one=33 two=34 ;; *) one=$size two=$((size + 1)) ;; esac
  cp "$icons/Icon $one.png" "$iconset/icon_${size}x${size}.png"
  cp "$icons/Icon $two.png" "$iconset/icon_${size}x${size}@2x.png"
done
iconutil -c icns "$iconset" -o "$staged/Contents/Resources/AppIcon.icns"

codesign --force --sign - --options runtime \
  --entitlements "$sources/BarikEnhanced.entitlements" "$staged"
codesign --verify --strict "$staged"

mkdir -p "$dest_dir"
rm -rf "$app"
mv "$staged" "$app"
echo "Installed $app"
