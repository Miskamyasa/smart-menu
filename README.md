# Smart Menu

Minimal SwiftUI macOS menu bar app that runs `smartctl -a disk0` and displays selected SMART fields.

## Runtime notes

- Install `smartctl` via smartmontools before running the app.
- The app checks `/opt/homebrew/bin/smartctl`, `/opt/homebrew/sbin/smartctl`, `/usr/local/bin/smartctl`, `/usr/local/sbin/smartctl`, then entries in `PATH`.
- The app is intentionally unsandboxed so it can launch the external `smartctl` command. Xcode-launched apps may have a limited `PATH`, so the Homebrew paths above are checked explicitly.
- Some `smartctl` versions return a non-zero status while still printing usable SMART data. The app displays parsed stdout when available and only shows a command failure when no stdout was produced.
