# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

InputLock 是一个轻量级 macOS 菜单栏应用，用于锁定输入法防止意外切换。纯 Swift/SwiftUI 项目，无第三方依赖。

- 平台：macOS 26.0+
- Bundle ID：com.cloudwings.lockinput
- LSUIElement：true（菜单栏应用，无 Dock 图标）
- 应用沙箱：禁用（需访问 Carbon TIS 输入法 API）

## 构建命令

```bash
# 构建
xcodebuild -project lockinput.xcodeproj -scheme lockinput -configuration Release -derivedDataPath build clean build

# 打包 DMG
bash scripts/create-dmg.sh
```

## 架构

四个核心文件，约 530 行 Swift 代码：

- **lockinputApp.swift** — 应用入口。`AppDelegate` 管理菜单栏图标（NSStatusBar）、弹出窗口和右键菜单。监听 `InputMethodManager` 的锁定状态变化来更新图标。
- **InputMethodManager.swift** — 核心逻辑，单例模式。通过 Carbon 框架的 `TISCopyInputMethodKeyboardLayouts` / `TISSelectInputSource` 等 API 管理输入法。锁定时以 50ms 延迟自动恢复选定输入法。监听 `kTISNotifySelectedKeyboardInputSourceChanged` 通知。
- **ContentView.swift** — SwiftUI 主界面。包含锁定状态、输入法列表、语言选择器、开机启动开关。
- **LanguageManager.swift** — 本地化管理，单例模式。支持系统默认 + 5 种语言（en/zh-Hans/fr/de/ja），动态加载 `.lproj` 资源包，使用 `@AppStorage` 持久化语言选择。

## 本地化

本地化字符串位于 `lockinput/Resources/{lang}.lproj/Localizable.strings`。添加新语言时需同步更新 `LanguageManager.swift` 中的 `SupportedLanguage` 枚举和 Xcode 项目的已知区域设置。
