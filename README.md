<p align="center">
  <img src="Sources/MacMouse/Resources/AppIcon.svg" alt="MacMouse logo" width="96" />
</p>

<h1 align="center">MacMouse</h1>

<p align="center">Customize your mouse buttons and scrolling on Mac.</p>

<p align="center">
  <a href="https://github.com/andrelombardo/MacMouse/releases/latest">Download MacMouse</a>
</p>

Assign everyday actions to your mouse’s side buttons and reverse the scroll wheel without changing trackpad scrolling. MacMouse uses native macOS controls, stores settings on your Mac, and keeps working when you close its window.

The icon appears in the Dock when you open the window. The red close button closes the window and hides the Dock icon while keeping mouse actions active in the background. To quit the app, use its quit command.

Free and offline, with no accounts, ads, or telemetry. Requires **macOS 27 or later** and a Mac with **Apple Silicon**.

## Getting started

1. Download the **DMG** from [Releases](https://github.com/andrelombardo/MacMouse/releases/latest) and open it.
2. Drag **MacMouse** into the **Applications** folder in the window, then open the app from Applications.
3. Use the settings link to grant MacMouse Accessibility access, then return to the app.

To use natural scrolling on the trackpad and traditional scrolling on the mouse, leave **Natural scrolling** enabled in macOS settings and enable mouse scroll reversal in MacMouse.

## Features

- **See the connected model:** the model reported by the mouse appears below its name, only when available and different from the name. It updates automatically when you switch devices.
- **Customize two buttons:** Back, Forward, Mission Control, desktop switching, app launching, and shortcuts.
- **Control scrolling:** reverse vertical and horizontal scrolling while preserving speed and precision.
- **Use middle click:** including dragging, or keep or disable a button’s original action.
- **Launch at login:** through the native macOS service.
- **Hide the menu bar icon:** from the app window. When visible, its menu has just two commands: open MacMouse and quit MacMouse. You can always reopen the app from Applications.

Mappings apply to all mice that send the same button number. Reversal applies to discrete scroll wheel events; trackpad scrolling, gestures, and momentum pass through unchanged. Mice that send continuous scrolling, such as Magic Mouse or some drivers with smooth scrolling, keep the system scrolling direction.

## Permissions and resource usage

Accessibility access enables remapping and sending shortcuts. MacMouse does not log keystrokes: a shortcut is captured only in the shortcut recorder. Local button detection works before permission is granted; actions in other apps require authorization.

The engine waits for events, with no polling or periodic timers. Scrolling is intercepted only when reversal is enabled. Closing the window releases its interface. Temporary event filter objects are released after each event.

Builds without Developer ID signing and notarization may require approval in **System Settings → Privacy & Security**, following [Apple’s instructions](https://support.apple.com/en-us/102445). An update may require granting Accessibility access again to the copy in Applications.

## Development

Open `MacMouse.xcodeproj` in Xcode 27, or use Swift 6.4 with the macOS 27 SDK:

```sh
git clone https://github.com/andrelombardo/MacMouse.git
cd MacMouse
scripts/build.sh
scripts/package.sh
```

| Command | Result |
| --- | --- |
| `scripts/build.sh` | Builds `build/MacMouse.app`. |
| `scripts/package.sh` | Creates the DMG, ZIP, and checksums in `dist/`. |
| `scripts/install-local.sh` | Builds and installs in Applications, preserving preferences and a backup of the previous copy. |

The app has no external dependencies. Packaging requires Python 3.10+ and the tools pinned in `scripts/requirements-packaging.txt`, installed in an isolated environment. If needed, set the interpreter path with `PYTHON=/path/to/python3 scripts/package.sh`. The pipeline builds the Xcode project in Release configuration and verifies the bundle, archives, and checksums.

To publish an update, increment `CFBundleShortVersionString` and `CFBundleVersion` in `Sources/MacMouse/Resources/Info.plist`, update `docs/RELEASE_NOTES.md` in English, and push to `main`. After verification, GitHub automatically creates the tag and a new release with the DMG, ZIP, and checksums. Existing releases are preserved. You can also trigger a release by pushing a `vX.Y.Z` tag matching the app version.

## License

[MIT](LICENSE). Original code and icon; system symbols provided by macOS.
