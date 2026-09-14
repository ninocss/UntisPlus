#!/usr/bin/env bash
#
# Prepares a TrollStore-compatible IPA from a `flutter build ios --release
# --no-codesign` output directory.
#
# TrollStore installs apps permasigned (no Apple ID, no 7-day re-signing). Any
# entitlements baked into the binary signature are preserved when TrollStore
# re-signs the app with its fake root certificate, so we ad-hoc (fake) sign the
# whole bundle with the project entitlements (app groups, etc.) to keep widgets
# and shared containers working.
#
# Usage:
#   prepare_trollstore_ipa.sh <path/to/Runner.app> [output dir] [ipa name]
#
# Exit codes:
#  0 success, 1 usage/bad input, 2 codesign/packaging failure
set -euo pipefail

APP_SRC="${1:-}"
OUT_DIR="${2:-release_assets}"
IPA_NAME="${3:-}"

if [ -z "$APP_SRC" ]; then
  echo "usage: prepare_trollstore_ipa.sh <path/to/Runner.app> [output dir] [ipa name]" >&2
  exit 1
fi

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENTITLEMENTS="$BASE_DIR/tool/trollstore/Runner.entitlements"

if [ ! -d "$APP_SRC" ]; then
  echo "error: .app not found: $APP_SRC" >&2
  exit 1
fi
if [ ! -f "$ENTITLEMENTS" ]; then
  echo "error: entitlements not found: $ENTITLEMENTS" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
WORK_DIR="$OUT_DIR/.trollstore"
APP_DIR="$WORK_DIR/Payload/Runner.app"

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/Payload"
ditto --norsrc "$APP_SRC" "$APP_DIR"

# Remove any pre-existing signature artifacts from the build.
find "$APP_DIR" -name "_CodeSignature" -type d -exec rm -rf {} +
find "$APP_DIR" -name "CodeResources" -type f -delete
find "$APP_DIR" -name "embedded.mobileprovision" -type f -delete

# Sign nested bundles (app extensions, frameworks) bottom-up first, then the
# root app. Ad-hoc identity ("-") produces a fake signature that TrollStore
# accepts and preserves while re-signing.
find "$APP_DIR" \( -name "*.appex" -o -name "*.framework" \) -print0 | \
while IFS= read -r -d '' bundle; do
  codesign --force --timestamp=none --sign - --entitlements "$ENTITLEMENTS" "$bundle"
done
codesign --force --deep --timestamp=none --sign - --entitlements "$ENTITLEMENTS" "$APP_DIR"

if [ -z "$IPA_NAME" ]; then
  APP_VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP_DIR/Info.plist")"
  IPA_NAME="UntisPlus-${APP_VERSION}-trollstore.ipa"
fi

(cd "$WORK_DIR" && zip -qry "../$IPA_NAME" "Payload")
rm -rf "$WORK_DIR"

echo "TrollStore IPA ready: $OUT_DIR/$IPA_NAME"