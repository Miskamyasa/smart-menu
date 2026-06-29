# Smart Menu

A minimal SwiftUI macOS menu bar app for system monitoring.

<img src="screenshot.jpg" alt="Smart Menu panel showing memory usage and disk SMART fields" width="420">

The menu bar shows a square gauge that fills with current memory usage. Clicking it opens a panel with:

- **Memory** — used / total and a live usage bar, refreshed every second.
- **Disk** — NVMe S.M.A.R.T. health: temperature, wear, data written, power-on hours, and more.

SMART data is read directly through IOKit — no external tools, no admin rights. The UI follows the system Light/Dark appearance automatically.

## Why memory?

Memory and SSD wear are linked. When memory usage climbs, macOS starts swapping pages to disk — and under memory pressure during intensive I/O tasks, that means more reads and writes hitting your SSD. Keeping an eye on memory is an early warning for the swap activity that adds to your drive's lifetime write count, which is exactly what the Disk section tracks.

## Build & run

```sh
make build     # build the app
make run       # build and launch
make install   # copy to /Applications and launch
make test      # run unit tests
```

## Requirements

- macOS 13+ (Apple Silicon or Intel with an NVMe drive).
- Xcode 16 to build.

## Notes

- The Disk section uses the NVMe SMART log via IOKit (`IONVMeSMARTInterface`); the Disk section is empty on Macs without an NVMe drive.
- The app runs unsandboxed, so it is distributed outside the Mac App Store as a notarized DMG (`make dmg`).

## Releasing (for forks)

Because the app reads NVMe SMART through a private IOKit user client, it can't be sandboxed and therefore can't ship on the Mac App Store. Distribute it the way Apple supports for outside-the-store apps: a **Developer ID–signed, notarized, stapled DMG**. You need an Apple Developer account ($99/yr).

### 1. One-time setup

- **Developer ID Application certificate.** In Xcode → Settings → Accounts → Manage Certificates, create a *Developer ID Application* certificate (not "iOS Distribution" or "Developer ID Installer"). Confirm it's installed:

  ```sh
  security find-identity -v -p codesigning   # note the "Developer ID Application: NAME (TEAMID)" line
  ```

- **App-specific password for notarization.** At [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords, generate one (format `abcd-efgh-ijkl-mnop`). Store it in the keychain as a reusable notary profile so you never paste it again:

  ```sh
  xcrun notarytool store-credentials notary \
    --apple-id "you@example.com" \
    --team-id "TEAMID" \
    --password "abcd-efgh-ijkl-mnop"
  ```

### 2. Build, sign, notarize, staple

```sh
# Build Release and produce a signed DMG in build/SmartMenu.dmg
SIGN_ID="Developer ID Application: NAME (TEAMID)" make dmg

# Upload to Apple, wait for the result, then attach the ticket to the DMG
xcrun notarytool submit build/SmartMenu.dmg --keychain-profile notary --wait
xcrun stapler staple build/SmartMenu.dmg

# Verify the DMG passes Gatekeeper as a notarized app
xcrun stapler validate build/SmartMenu.dmg
spctl --assess --type open --context context:primary-signature -vv build/SmartMenu.dmg
```

Without `SIGN_ID`, `make dmg` still produces a DMG, but it's unsigned — fine for local testing, not for distribution (other Macs will block it).

### 3. Publish a GitHub release

Bump `MARKETING_VERSION` in the Xcode project if needed, then tag and publish the notarized DMG with the [`gh`](https://cli.github.com) CLI:

```sh
git tag v1.0.0
git push origin v1.0.0

gh release create v1.0.0 build/SmartMenu.dmg \
  --title "Smart Menu v1.0.0" \
  --notes "Menu bar memory gauge + NVMe SMART disk health. Download the DMG, drag to Applications."
```

The stable download link for the latest release is then:

```
https://github.com/<owner>/<repo>/releases/latest/download/SmartMenu.dmg
```

## License

[MIT](LICENSE)
