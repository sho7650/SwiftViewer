#!/bin/bash
#
# release.sh — Build, sign, notarize, and staple a standalone SwiftViewer.app.
#
# Produces build/export/SwiftViewer.app, notarized with Developer ID and ready to
# copy into /Applications. See docs/RELEASING.md for one-time credential setup.
#
set -euo pipefail

PROJECT="SwiftViewer.xcodeproj"
SCHEME="SwiftViewer"
TEAM_ID="TU59724Z2P"
KEYCHAIN_PROFILE="${NOTARY_PROFILE:-SwiftViewerNotary}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/SwiftViewer.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
APP_PATH="$EXPORT_DIR/SwiftViewer.app"
ZIP_PATH="$BUILD_DIR/SwiftViewer.zip"

cd "$ROOT_DIR"

echo "==> Preflight checks"
if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo "ERROR: No 'Developer ID Application' certificate found in the keychain."
    echo "       See docs/RELEASING.md, step 1 (create it via Xcode → Settings → Accounts)."
    exit 1
fi
if ! xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" >/dev/null 2>&1; then
    echo "ERROR: Notary keychain profile '$KEYCHAIN_PROFILE' is not configured."
    echo "       See docs/RELEASING.md, step 2 (xcrun notarytool store-credentials)."
    echo "       Override the profile name with NOTARY_PROFILE=<name> $0"
    exit 1
fi

echo "==> Archiving (Release)"
rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR" "$ZIP_PATH"
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -archivePath "$ARCHIVE_PATH"

echo "==> Exporting with Developer ID"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$ROOT_DIR/scripts/ExportOptions.plist" \
    -exportPath "$EXPORT_DIR"

echo "==> Zipping for notarization"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "==> Submitting to the notary service (this can take a few minutes)"
if ! xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$KEYCHAIN_PROFILE" --wait; then
    echo "ERROR: Notarization failed. Inspect the log with:"
    echo "       xcrun notarytool log <submission-id> --keychain-profile \"$KEYCHAIN_PROFILE\""
    exit 1
fi

echo "==> Stapling the ticket"
xcrun stapler staple "$APP_PATH"

echo "==> Verifying"
xcrun stapler validate "$APP_PATH"
spctl -a -vv "$APP_PATH"

echo ""
echo "Done. Notarized app: $APP_PATH"
echo "Install it with:"
echo "    ditto \"$APP_PATH\" /Applications/SwiftViewer.app"
