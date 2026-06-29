# Smart Menu

A minimal SwiftUI macOS menu bar app for system monitoring.

The menu bar shows a square gauge that fills with current memory usage. Clicking it opens a panel with:

- **Memory** — used / total and a live usage bar, refreshed every second.
- **Disk** — selected S.M.A.R.T. fields from `smartctl -a disk0`.

The UI follows the system Light/Dark appearance automatically.

## Build & run

```sh
make build     # build the app
make run       # build and launch
make install   # copy to /Applications and launch
make test      # run unit tests
```

## Requirements

- macOS 13+ and Xcode 16.
- `smartctl` (from [smartmontools](https://www.smartmontools.org/)) for the Disk section.
  Install via Homebrew: `brew install smartmontools`.

## Notes

- The app checks `/opt/homebrew/{bin,sbin}/smartctl`, `/usr/local/{bin,sbin}/smartctl`, then `PATH`.
- It runs unsandboxed so it can launch the external `smartctl` command.
- Some `smartctl` versions return a non-zero status while still printing usable data; the app shows parsed output when available and only reports failure when no output was produced.

## License

[MIT](LICENSE)
