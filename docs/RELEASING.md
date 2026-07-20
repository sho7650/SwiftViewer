# Releasing SwiftViewer (Developer ID + Notarization)

`scripts/release.sh` builds a standalone, notarized `SwiftViewer.app` that any Mac can
launch from `/Applications` without Gatekeeper warnings. Two one-time setup steps are
required before the first run.

## One-time setup

### 1. Developer ID Application certificate

You need a **Developer ID Application** certificate for team `TU59724Z2P` in your login
keychain (requires the Account Holder or Admin role in the Apple Developer Program):

- Xcode → **Settings** → **Accounts** → select the team → **Manage Certificates…**
- Click **+** → **Developer ID Application**.

Verify it is present:

```bash
security find-identity -v -p codesigning | grep "Developer ID Application"
```

### 2. Notary credentials

Store a notary keychain profile named `SwiftViewerNotary` (the default the script expects).
Either option works — an App Store Connect API key is recommended:

```bash
# Option A — App Store Connect API key (recommended)
xcrun notarytool store-credentials SwiftViewerNotary \
    --key /path/to/AuthKey_XXXXXX.p8 \
    --key-id <KEY_ID> \
    --issuer <ISSUER_UUID>

# Option B — Apple ID + app-specific password
xcrun notarytool store-credentials SwiftViewerNotary \
    --apple-id tak7650@gmail.com \
    --team-id TU59724Z2P \
    --password <app-specific-password>
```

(Use a different profile name by exporting `NOTARY_PROFILE=<name>` before running the script.)

## Building a release

```bash
bash scripts/release.sh
```

The script archives (Release), exports with Developer ID, submits to the notary service
and waits, staples the ticket, and verifies with `spctl`. On success it prints the path to
the notarized app and the install command:

```bash
ditto build/export/SwiftViewer.app /Applications/SwiftViewer.app
```

## Notes

- App Store distribution configuration is unchanged; this flow is only for direct
  Developer ID distribution.
- If notarization fails, inspect the log:
  `xcrun notarytool log <submission-id> --keychain-profile SwiftViewerNotary`
- The app targets macOS 26 (Tahoe) and has no third-party dependencies, so the exported
  `.app` is fully self-contained.
