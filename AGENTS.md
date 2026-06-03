# Repository Guidelines

## Project Structure & Module Organization

This is a macOS SwiftUI menu bar app with one Xcode target, `lockinput`.
Primary source lives in `lockinput/`: `lockinputApp.swift` owns app startup and status bar behavior, `ContentView.swift` renders the popover UI, `InputMethodManager.swift` handles Carbon input sources, and `LanguageManager.swift` manages runtime localization. App metadata is in `lockinput/Info.plist`. Assets are in `lockinput/Assets.xcassets/`. Localized strings live under `lockinput/Resources/<lang>.lproj/Localizable.strings` for `en`, `zh-Hans`, `fr`, `de`, and `ja`. Packaging helpers are in `scripts/`.

## Build, Test, and Development Commands

Use Xcode for day-to-day development:

```bash
open lockinput.xcodeproj
```

If `xcodebuild` points at Command Line Tools, switch to full Xcode first:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Build a Release app into `build/Build/Products/Release/lockinput.app`:

```bash
xcodebuild -project lockinput.xcodeproj -scheme lockinput -configuration Release -derivedDataPath build clean build
```

Create a release DMG after the Release build:

```bash
./scripts/create-dmg.sh
```

## Coding Style & Naming Conventions

Use Swift 5 and SwiftUI conventions. Keep four-space indentation, descriptive method names, and UpperCamelCase for types such as `InputMethodManager`; use lowerCamelCase for properties, methods, and local values. Keep singleton managers explicit (`InputMethodManager.shared`, `LanguageManager.shared`) unless refactoring the app architecture deliberately. Prefer `String.localized(with:)` keys over hard-coded UI strings.

## Testing Guidelines

There is currently no dedicated test target. For behavior changes, manually verify launch, menu bar icon state, popover interaction, lock/unlock behavior, launch-at-login toggling, and language switching. If adding tests, create an Xcode test target and name test files after the unit under test, for example `InputMethodManagerTests.swift`.

## Commit & Pull Request Guidelines

Recent history uses short, direct commit subjects such as `init`, `update`, and Chinese summaries like `增加多语言支持`. Keep commit subjects concise and describe the user-visible change. Pull requests should include the purpose, changed files or flows, manual verification steps, and screenshots or screen recordings for UI changes.

## Security & Configuration Tips

Do not commit `build/`, `DerivedData/`, generated `.app` bundles, or temporary DMG folders. The project uses automatic code signing; avoid changing signing settings unless the release process requires it.
