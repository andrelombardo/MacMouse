<p align="center">
  <img src="Sources/MacMouse/Resources/AppIcon.svg" alt="MacMouse logo" width="96" />
</p>

<h1 align="center">MacMouse</h1>

<p align="center">Customize your mouse buttons and scrolling with native macOS controls.</p>

<p align="center">
  <a href="https://github.com/andrelombardo/MacMouse/releases/latest">Download MacMouse</a>
</p>

Requires **macOS 27 or later** and **Apple Silicon**. Free, offline, with no accounts or telemetry.

## Features

- Assign Back, Forward, Mission Control, desktop switching, apps, or shortcuts to two side buttons.
- Reverse mouse wheel scrolling independently of the trackpad.
- Use middle click, including dragging.
- Launch at login and optionally hide the menu bar icon.

## Installation

1. Open the DMG and drag **MacMouse** into **Applications**.
2. Open the app and grant **Accessibility** access in System Settings.

If macOS blocks the app, follow [Apple’s instructions](https://support.apple.com/en-us/102445).

For natural trackpad scrolling and traditional mouse scrolling, keep **Natural scrolling** enabled in macOS and enable mouse scroll reversal in MacMouse.

Button mappings are shared across connected mice. Scroll reversal supports discrete wheel events; devices that send continuous scrolling keep the system direction.

## Build from source

Open `MacMouse.xcodeproj` in Xcode 27, or build with Swift 6.4 and the macOS 27 SDK:

```sh
scripts/build.sh
```

## License

[MIT](LICENSE).
