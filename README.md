# LockInput

A lightweight macOS menu bar app to lock your input method and prevent accidental switching.

一个轻量级的 macOS 状态栏应用，用于锁定输入法，防止意外切换。

## Features

- **Lock Input Method** - Lock to your preferred input method, prevent accidental switching
- **Menu Bar App** - Lives in the menu bar, no dock icon
- **Multi-language Support** - English, 简体中文, Français, Deutsch, 日本語
- **Launch at Login** - Optional auto-start when you log in
- **Simple & Clean UI** - Minimal and intuitive interface

## Screenshots

| Unlocked | Locked |
|----------|--------|
| 🔓 | 🔒 |

## Requirements

- macOS 26.0 or later

## Installation

### Option 1: Build from Source

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/lockinput.git
   cd lockinput
   ```

2. Open in Xcode
   ```bash
   open lockinput.xcodeproj
   ```

3. Build and run (`Cmd + R`)

### Option 2: Download Release

Download the latest release from [Releases](https://github.com/yourusername/lockinput/releases) page.

## Usage

### Basic Operations

- **Left-click** menu bar icon - Open the main panel
- **Right-click** menu bar icon - Quick actions menu
- **Click an input method** in the list - Switch and lock to that input method
- **Lock/Unlock button** - Toggle lock status

### Settings

- **Language** - Choose interface language or follow system
- **Launch at Login** - Enable/disable auto-start

## Building

```bash
# Switch to Xcode (if needed)
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Build Release version
xcodebuild -project lockinput.xcodeproj \
           -scheme lockinput \
           -configuration Release \
           -derivedDataPath build \
           clean build

# Find the app at: build/Build/Products/Release/lockinput.app
```

## Project Structure

```
lockinput/
├── lockinputApp.swift        # App entry point & menu bar setup
├── ContentView.swift         # Main UI
├── InputMethodManager.swift  # Input method control logic
├── LanguageManager.swift     # Localization manager
├── Info.plist               # App configuration
├── Assets.xcassets/         # App icons and assets
└── Resources/
    ├── en.lproj/            # English
    ├── zh-Hans.lproj/       # Simplified Chinese
    ├── fr.lproj/            # French
    ├── de.lproj/            # German
    └── ja.lproj/            # Japanese
```

## Localization

The app supports the following languages:

| Language | Code |
|----------|------|
| English | en |
| 简体中文 | zh-Hans |
| Français | fr |
| Deutsch | de |
| 日本語 | ja |

To add a new language:
1. Create a new `.lproj` folder in `Resources/`
2. Copy `Localizable.strings` from `en.lproj`
3. Translate the strings
4. Add the language code to `knownRegions` in `project.pbxproj`
5. Add the language to `AppLanguage` enum in `LanguageManager.swift`

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
