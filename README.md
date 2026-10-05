# Text Assist

Text Assist brings local AI writing tools to selected text anywhere on macOS.
Select text, press `Option-Shift-S`, choose an action, and get a result in a
floating panel without switching away from the app you are using.

The app runs in the menu bar and uses Ollama as its language-model backend.
Its default Ollama endpoint is `http://localhost:11434`; requests go to the
endpoint configured in the app. No hosted AI provider is included.

## What It Does

- **Transform:** Summarize selected text in several styles or use a custom
  prompt.
- **Write:** Fix grammar, change tone or length, compare the result with the
  original, and replace the selection.
- **Chat:** Ask follow-up questions with the selected text as context.
- Check Ollama status, choose a model, and revisit recent results from the menu
  bar.

Text Assist is an early-stage personal-use project. It requires macOS 13 or
later and is not distributed through the Mac App Store.

## Quick Start

1. Install and start [Ollama](https://ollama.com/download).
2. Download the default model:

   ```sh
   ollama pull phi3:instruct
   ```

3. Build and launch Text Assist from the repository root:

   ```sh
   Scripts/run.sh
   ```

4. Grant Text Assist access in **System Settings → Privacy & Security →
   Accessibility**. This is required to capture selected text and replace it
   in other apps.
5. Select text in another app and press `Option-Shift-S`. You can also use
   **Assist with Selection** from the Text Assist menu-bar popover.

The menu-bar popover shows whether Ollama is reachable and lets you select an
available model. The Ollama server and selected model must be available for
Transform, Write, and Chat.

## Build and Run

Requirements: macOS 13 or later, Xcode with the macOS SDK, and Ollama for using
the app's AI features.

To build and launch the Debug app:

```sh
Scripts/run.sh
```

To build without opening the app:

```sh
Scripts/run.sh --no-open
```

The equivalent Xcode build command is:

```sh
xcodebuild build \
  -project TextAssist.xcodeproj \
  -scheme "Text Assist" \
  -configuration Debug \
  -destination "platform=macOS" \
  -derivedDataPath build/DerivedData
```

## Package a Release

To build a local DMG without publishing a GitHub Release:

```sh
Scripts/build-dmg.sh [version]
```

To build a universal DMG, generate its SHA-256 checksum, and publish a GitHub
Release:

```sh
Scripts/release.sh [version] [--draft]
```

The release script must run from the main checkout on `main`; it requires
`xcodebuild`, `create-dmg`, `gh`, and `jq`. Releases are ad-hoc signed and not
notarized, so macOS may block the first launch. See the
[release script guide](Scripts/README.md) for prerequisites, options, and
installation guidance.

## Development Notes

There are currently no automated tests. Verify changes by building the app and
manually checking the affected flow in a running macOS app.

- [Product requirements](tickets/PRD-v2.md)
- [Approved design system](Docs/design/v2/README.md)
- [Agent and repository constraints](AGENTS.md)
- [Release script guide](Scripts/README.md)