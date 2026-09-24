# Text Assist — Project Setup Guide

## Overview

This guide explains how to set up the **Text Assist** project for macOS development. It is written for developers who are new to macOS or Swift. The project starts as a local build, but it is structured so it can later be distributed via **Homebrew** and published as an **open-source project**.

---

## Target Use Cases

| Stage                           | Goal                                                   | What This Guide Covers |
| :------------------------------ | :----------------------------------------------------- | :--------------------- |
| **Local development**     | Build and run the app on your own Mac                  | Steps 1–9             |
| **Homebrew distribution** | Let users install with `brew install text-assist` | Step 10                |
| **Open source**           | Publish source code on GitHub under a public license   | Step 11                |

---

## Recommended Tech Stack

| Layer              | Choice                                                                                      | Reason                                                                                                |
| :----------------- | :------------------------------------------------------------------------------------------ | :---------------------------------------------------------------------------------------------------- |
| Language           | **Swift 5.9+**                                                                        | Required for native macOS APIs: Accessibility, Keychain, global hotkeys, floating panels.             |
| UI                 | **SwiftUI + AppKit interop**                                                          | SwiftUI is fast to write; AppKit is used for the menu-bar status item and non-activating popup panel. |
| Project format     | **Xcode project** (`.xcodeproj`)                                                    | Easier for beginners than SPM alone. Handles signing, entitlements, assets, and app packaging.        |
| Global hotkeys     | **[KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)** SPM package | Modern, sandbox-friendly, includes a recorder UI.                                                     |
| Markdown rendering | **[MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui)** SPM package        | Renders Markdown in SwiftUI with minimal effort.                                                      |
| Minimum macOS      | **macOS 13 Ventura**                                                                  | Broad compatibility; revisit macOS 14 only if newer features are needed.                              |

---

## Refined Project Structure

Use this folder layout inside the Xcode project. Group names in Xcode can match these folders.

```text
TextAssist/
├── TextAssist.xcodeproj
├── TextAssist/
│   ├── App/
│   │   └── TextAssistApp.swift              # @main entry point
│   ├── Core/
│   │   ├── HotkeyManager.swift              # Global shortcuts
│   │   ├── TextCaptureService.swift         # Accessibility + ⌘C fallback
│   │   └── SummarizationOrchestrator.swift  # Wires capture → style → provider → popup
│   ├── Models/
│   │   ├── CapturedText.swift               # Text + source app name
│   │   ├── SummaryStyle.swift               # Style name + prompt template
│   │   ├── SummaryRequest.swift             # Provider request payload
│   │   └── CaptureError.swift               # Accessibility / no selection / too long
│   ├── Providers/
│   │   ├── LLMProvider.swift                # Shared protocol
│   │   ├── OllamaProvider.swift             # Local Ollama backend
│   │   └── OpenAICompatibleProvider.swift   # OpenAI-compatible APIs
│   ├── Stores/
│   │   ├── SettingsStore.swift              # UserDefaults wrapper
│   │   ├── StyleStore.swift                 # Built-in + custom styles
│   │   └── HistoryStore.swift               # Recent summaries (v1.1)
│   ├── UI/
│   │   ├── MenuBar/
│   │   │   └── MenuBarStatusView.swift      # Status item + dropdown menu
│   │   ├── StylePicker/
│   │   │   └── StylePickerPanel.swift       # Compact style chooser
│   │   ├── Popup/
│   │   │   └── SummaryPopup.swift           # Floating summary panel
│   │   └── Settings/
│   │       ├── SettingsWindow.swift         # Tabbed settings host
│   │       ├── GeneralSettingsView.swift    # Hotkeys, launch at login, limits
│   │       ├── StylesSettingsView.swift     # Manage style templates
│   │       ├── ProvidersSettingsView.swift  # Ollama / OpenAI setup + test
│   │       └── OutputSettingsView.swift     # Folder, auto-save, filename
│   ├── Utilities/
│   │   ├── KeychainStore.swift              # macOS Keychain wrapper
│   │   ├── MarkdownWriter.swift             # Save .md files with frontmatter
│   │   ├── PromptTemplater.swift            # Replace {{text}} in prompts
│   │   └── StreamParsers.swift              # NDJSON / SSE token parsers
│   ├── Resources/
│   │   ├── Assets.xcassets                  # App icon, colors
│   │   └── Localizable.xcstrings            # String Catalog for localization
│   ├── Info.plist
│   └── TextAssist.entitlements
├── TextAssistTests/
│   ├── PromptTemplateTests.swift
│   ├── StreamParserTests.swift
│   ├── MarkdownWriterTests.swift
│   └── KeychainStoreTests.swift
├── LICENSE
├── README.md
└── Docs/
    ├── PRD.md
    └── setup-guide.md
```

---

## Step-by-Step Setup

### Step 1: Install Xcode

1. Open the **Mac App Store**.
2. Search for **Xcode**.
3. Click **Get** or **Install**.
4. Wait for the download to finish (about 10 GB).
5. Open Xcode and accept the license agreement.

> **Why Xcode?** It includes the Swift compiler, macOS SDK, Interface Builder, and debugger. Everything needed to build a native macOS app.

---

### Step 2: Create the Xcode Project

1. Open Xcode.
2. Choose **File → New → Project…** or press `Shift-Command-N`.
3. Select **macOS** at the top of the template chooser.
4. Choose **App**, then click **Next**.
5. Fill in the project details:

| Field                   | Recommended Value                                     |
| :---------------------- | :---------------------------------------------------- |
| Product Name            | `Text Assist`                                       |
| Team                    | None for now, or your Apple ID team later for signing |
| Organization Identifier | `com.yourname` or your reverse-domain name          |
| Interface               | `SwiftUI`                                           |
| Language                | `Swift`                                             |
| Minimum Deployments     | macOS`13.0`                                         |

6. Choose a folder to save the project.
7. Make sure **Create Git repository on my Mac** is checked.
8. Click **Create**.

---

### Step 3: Configure the App as a Menu-Bar Agent

The app must live in the menu bar with no Dock icon.

1. In the Project navigator, click the top-level **TextAssist** project.
2. Select the **Text Assist** target.
3. Go to the **Info** tab.
4. Find **Custom macOS Application Target Properties**.
5. Click the **+** button to add a new row.
6. Enter:
   - Key: `LSUIElement`
   - Type: `Boolean`
   - Value: `YES`

---

### Step 4: Turn Off the App Sandbox

The App Sandbox blocks simulated ⌘C and some Accessibility workflows. The PRD recommends distribution **outside the Mac App Store**, so the sandbox should be disabled.

1. In the Project navigator, find `TextAssist.entitlements`.
2. If it does not exist, create it with **File → New → File → Property List** and name it `TextAssist.entitlements`.
3. Set its contents to:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
```

4. In the target settings, under **Signing & Capabilities**, make sure this entitlements file is selected.

---

### Step 5: Add Swift Package Dependencies

Two external packages are needed.

| Package           | URL                                                   | Purpose                        |
| :---------------- | :---------------------------------------------------- | :----------------------------- |
| KeyboardShortcuts | `https://github.com/sindresorhus/KeyboardShortcuts` | Global hotkeys and recorder UI |
| MarkdownUI        | `https://github.com/gonzalezreal/swift-markdown-ui` | Render Markdown in the popup   |

To add them:

1. Select the project in the Project navigator.
2. Go to the **Package Dependencies** tab.
3. Click **+**.
4. Paste the URL for `KeyboardShortcuts`.
5. Click **Add Package**.
6. Repeat for `MarkdownUI`.

---

### Step 6: Create the Folder Groups

Organize the project by creating these groups in the Project navigator:

1. Right-click the blue **TextAssist** folder.
2. Choose **New Group**.
3. Create these top-level groups:
   - `App`
   - `Core`
   - `Models`
   - `Providers`
   - `Stores`
   - `UI`
   - `Utilities`
4. Inside `UI`, create subgroups:
   - `MenuBar`
   - `StylePicker`
   - `Popup`
   - `Settings`
5. Drag existing files (like `ContentView.swift`) into the correct group, or delete them if not needed.

---

### Step 7: Install Ollama for Local Testing

The default LLM backend is a local Ollama instance.

1. Visit [https://ollama.com](https://ollama.com).
2. Download and install Ollama for macOS.
3. Open Terminal and pull a small model for testing:

```bash
ollama pull qwen2.5:0.5b
```

4. Start the Ollama server:

```bash
ollama serve
```

5. Verify it is running:

```bash
curl http://localhost:11434/api/tags
```

You should see a JSON response listing installed models.

---

### Step 8: Build the First Milestone

Do not build the full app at once. Start with the smallest working version that proves the riskiest parts.

**Milestone 1: Capture text with a global hotkey**

The goal is:

1. A menu-bar icon appears.
2. Pressing `⌥⇧S` triggers the app.
3. The app reads selected text using the Accessibility API.
4. The captured text is printed to the Xcode console.

Files to create first:

- [TextAssistApp.swift](../TextAssist/App/TextAssistApp.swift)
- [HotkeyManager.swift](../TextAssist/Core/HotkeyManager.swift)
- [TextCaptureService.swift](../TextAssist/Core/TextCaptureService.swift)

Once this works, add the style picker, provider, popup, and save features.

---

### Step 9: Run the App Locally

This project currently has one application target and scheme named **Text Assist**. The project folder is named `TextAssist`, while the target uses the user-facing name with a space.

#### 9.1 Open the project and resolve dependencies

1. Open **Terminal**.
2. Change to the project folder. Replace the path if you saved the project elsewhere:

```bash
cd /Users/gagik/projects/TextAssist
```

3. Open the project in Xcode:

```bash
open TextAssist.xcodeproj
```

4. Xcode downloads the Swift packages the first time the project opens. Wait for the activity indicator in the top-right corner to finish. If package resolution fails, use **File → Packages → Resolve Package Versions**.

The project includes these packages already, so do **not** add them again:

| Package | Used for |
| :------ | :------- |
| `KeyboardShortcuts` | Registers the global hotkey. |
| `MarkdownUI` | Displays Markdown-formatted summaries. |

#### 9.2 Build and run with Xcode

1. In the Xcode toolbar, select the **Text Assist** scheme.
2. Select **My Mac** as the run destination.
3. Press `Command-B` to build the app. A successful build displays **Build Succeeded** in Xcode.
4. Press `Command-R` to build (if needed) and start the app.
5. Look for the app icon in the macOS menu bar. This is a menu-bar app, so it intentionally does not appear in the Dock.
6. To stop the app while debugging, press `Command-.` in Xcode or choose **Product → Stop**.

When the app is running from Xcode, use Xcode's console to see `print` output and errors:

1. Choose **View → Debug Area → Activate Console**.
2. Select text in another application, such as TextEdit.
3. Press the configured shortcut, currently `Option-Shift-S` (`⌥⇧S`).
4. Confirm that the captured text or a useful error message appears in the console.

#### 9.3 Grant macOS permissions

The global shortcut does not need a permission dialog. Reading selected text does require **Accessibility** permission.

1. Start the app once using `Command-R`.
2. Open **System Settings → Privacy & Security → Accessibility**.
3. Enable **Text Assist**. If it is not listed, click **+**, then choose the built app from Xcode's Derived Data folder or start the app again and return to this screen.
4. Stop and run the app again from Xcode.
5. Test it with text selected in TextEdit or another standard macOS app.

> **Tip:** Permission is linked to the built application. If you clean Derived Data, switch signing identities, or run an app copied to a different location, macOS may ask you to grant permission again.

#### 9.4 Build, run, and install from Terminal

Use these commands when you prefer the terminal or need to check that the project builds without opening Xcode. Run them from the project root.

First, resolve Swift package dependencies. This requires internet access the first time:

```bash
xcodebuild -resolvePackageDependencies \
  -project TextAssist.xcodeproj \
  -scheme "Text Assist"
```

Build a debug version. `Debug` keeps debugging information and is the right configuration while developing:

```bash
xcodebuild build \
  -project TextAssist.xcodeproj \
  -scheme "Text Assist" \
  -configuration Debug \
  -destination "platform=macOS" \
  -derivedDataPath build/DerivedData
```

The resulting app bundle is placed at:

```text
build/DerivedData/Build/Products/Debug/Text Assist.app
```

Start that build with:

```bash
open "build/DerivedData/Build/Products/Debug/Text Assist.app"
```

To install the debug build into your user Applications folder, close any running copy first and copy the `.app` bundle:

```bash
osascript -e 'tell application "Text Assist" to quit' 2>/dev/null || true
rm -rf "$HOME/Applications/Text Assist.app"
ditto "build/DerivedData/Build/Products/Debug/Text Assist.app" "$HOME/Applications/Text Assist.app"
open "$HOME/Applications/Text Assist.app"
```

`ditto` copies an application bundle correctly, including its internal folders and file metadata. Installing into `~/Applications` affects only your user account and does not require an administrator password. Grant Accessibility permission to this installed copy if macOS requests it.

#### 9.5 Clean a broken local build

Use a clean build only when normal building fails after a dependency, Xcode, or build-setting change. Cleaning makes the next build slower because Xcode recreates all generated files.

In Xcode, choose **Product → Clean Build Folder** while holding `Option`, then build again with `Command-B`.

For the terminal build directory used above, run:

```bash
rm -rf build/DerivedData
```

Then repeat the dependency-resolution and debug-build commands from section 9.4.

#### 9.6 Development checklist

Before considering a local change ready, check the following:

1. The project builds with no errors.
2. The menu-bar icon appears after launching the app.
3. The hotkey activates the app.
4. Accessibility permission is enabled and selected text is captured.
5. Ollama is running when you test real summaries.
6. The Xcode console contains no unexpected errors.

---

## Step 10: Prepare for Homebrew Distribution

Homebrew is a good fit for an open-source macOS utility. To make the app installable with `brew install text-assist`, follow these guidelines during development.

### 10.1 Build a Release Binary

1. In Xcode, select **Product → Archive**.
2. In the Organizer, select the archive and click **Distribute App**.
3. Choose **Direct Distribution** (or **Copy App** for local testing).
4. Export the `.app` bundle.
5. Optionally, place the `.app` inside a `.dmg` or `.zip` for release.

### 10.2 Code Signing and Notarization

Homebrew casks can distribute signed or unsigned binaries, but signed and notarized apps are trusted by macOS and do not show Gatekeeper warnings.

1. Join the **Apple Developer Program** (paid, required for notarization).
2. In Xcode, set your Team in **Signing & Capabilities**.
3. Use **Product → Archive → Distribute App → Direct Distribution** with notarization enabled.
4. Wait for Apple to notarize the app.

### 10.3 Versioning and Releases

1. Use **Git tags** for versions, for example `v1.0.0`.
2. On GitHub, create a **Release** for each tag.
3. Attach the `.dmg` or `.zip` to the release.
4. Include a checksum (SHA-256) for the file.

### 10.4 Homebrew Cask File

A Homebrew cask file looks like this:

```ruby
cask "text-assist" do
  version "1.0.0"
  sha256 "abc123..."

  url "https://github.com/yourusername/text-assist/releases/download/v#{version}/Text-Assist-#{version}.dmg"
  name "Text Assist"
  desc "Menu-bar utility that summarizes selected text with a local or remote LLM"
  homepage "https://github.com/yourusername/text-assist"

  app "Text Assist.app"
end
```

> **Tip:** You can maintain the cask in your own tap first (`brew tap yourusername/tap`), then later submit it to `homebrew/cask`.

---

## Step 11: Build Without Xcode

You can build and export the `.app` from the command line. This is useful for CI/CD or if you prefer not to open Xcode.

### 11.1 Requirements

- macOS with **Xcode Command Line Tools** installed.
- To install them, run:

```bash
xcode-select --install
```

### 11.2 Build a Release App Bundle

Run this from the project root:

```bash
# 1. Clean and archive the app
xcodebuild archive \
  -project TextAssist.xcodeproj \
  -scheme "Text Assist" \
  -destination "generic/platform=macOS" \
  -archivePath build/TextAssist.xcarchive \
  -configuration Release

# 2. Export the .app bundle
xcodebuild -exportArchive \
  -archivePath build/TextAssist.xcarchive \
  -exportPath build/Export \
  -exportOptionsPlist export-options.plist
```

The exported `.app` will be at:

```text
build/Export/Text Assist.app
```

### 11.3 Run the App

Double-click `build/Export/Text Assist.app`, or run from the terminal:

```bash
open "build/Export/Text Assist.app"
```

### 11.4 Required export-options.plist

Create a file named `export-options.plist` in the project root:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinFor</key>
    <string>arm64,x86_64</string>
</dict>
</plist>
```

To sign the app, replace `YOUR_TEAM_ID` with your Apple Developer Team ID. You can find it in the Apple Developer portal or in Xcode under **Signing & Capabilities**.

If you want to export an **unsigned** `.app` for local testing only, use this minimal `export-options.plist` instead:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>stripSwiftSymbols</key>
    <true/>
</dict>
</plist>
```

> **Note:** Unsigned apps may show a Gatekeeper warning the first time you open them. Go to **System Settings → Privacy & Security** and click **Open Anyway**.

### 11.5 Package for Distribution

Create a `.zip` or `.dmg` from the exported `.app`:

```bash
# Zip
ditto -c -k --sequesterRsrc --keepParent \
  "build/Export/Text Assist.app" \
  build/Text-Assist.zip

# Or create a DMG with create-dmg (install with brew install create-dmg)
create-dmg \
  --volname "Text Assist" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --app-drop-link 600 185 \
  build/Text-Assist.dmg \
  "build/Export/Text Assist.app"
```

---

## Step 12: Prepare for Open Source

### 12.1 Choose a License

Common choices for macOS utilities:

| License    | Good for                                     |
| :--------- | :------------------------------------------- |
| MIT        | Simple, permissive, allows commercial use.   |
| GPL-3.0    | Requires derivative works to be open source. |
| Apache-2.0 | Permissive, includes patent grant.           |

For broad adoption, **MIT** is recommended.

Create a `LICENSE` file at the repository root.

### 12.2 Write a README.md

Include at least:

1. One-sentence description.
2. Screenshot or short demo GIF.
3. Features list.
4. Installation instructions (Homebrew + manual).
5. Setup instructions for Ollama and OpenAI-compatible providers.
6. Privacy note: no telemetry, API keys in Keychain.
7. License section.

### 12.3 Repository Hygiene

| File                    | Purpose                                                          |
| :---------------------- | :--------------------------------------------------------------- |
| `.gitignore`          | Ignore Xcode build folders,`xcuserdata`, `DerivedData`, etc. |
| `README.md`           | Project overview and install instructions.                       |
| `LICENSE`             | Open-source license.                                             |
| `CHANGELOG.md`        | Version history.                                                 |
| `Docs/PRD.md`         | Product requirements.                                            |
| `Docs/setup-guide.md` | This guide.                                                      |

### 12.4 Avoid Secrets in Git

- API keys must live only in the macOS Keychain.
- Never commit `.env` files or hardcoded credentials.
- Add API key placeholders to documentation only.

---

## Common Beginner Mistakes

| Mistake                             | How to Avoid                                                            |
| :---------------------------------- | :---------------------------------------------------------------------- |
| Using the App Sandbox               | Disable it in entitlements, or Accessibility/⌘C fallback will fail.    |
| Forgetting Accessibility permission | macOS blocks`AXUIElement` without it. Guide users to System Settings. |
| Building the full UI first          | Start with console output to prove text capture works.                  |
| Hardcoding API keys                 | Always use the Keychain for OpenAI-compatible providers.                |
| Choosing too new a macOS target     | Keep macOS 13 for broad compatibility.                                  |

---

## Next Steps

After the project is set up, create these files in order:

1. [TextAssistApp.swift](../TextAssist/App/TextAssistApp.swift) — App entry point.
2. [HotkeyManager.swift](../TextAssist/Core/HotkeyManager.swift) — Global hotkey with KeyboardShortcuts.
3. [TextCaptureService.swift](../TextAssist/Core/TextCaptureService.swift) — Accessibility API + ⌘C fallback.

Once Milestone 1 works, continue with the style picker, provider layer, popup, and Markdown writer.

---

## Related Documents

- [PRD.md](./PRD.md) — Full product requirements and architecture.
