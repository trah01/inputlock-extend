//
//  SettingsView.swift
//  lockinput
//

import SwiftUI
import AppKit
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var inputManager = InputMethodManager.shared
    @ObservedObject var languageManager = LanguageManager.shared
    @ObservedObject var shortcutManager = GlobalShortcutManager.shared
    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("restorePreviousLockState") var restorePreviousLockState = false
    @AppStorage("temporaryInputSourceID") var temporaryInputSourceID = ""
    @AppStorage("temporaryInputRestoreInterval") var temporaryInputRestoreInterval = 5.0
    @State private var isRecordingShortcut = false
    @State private var shortcutRecordingMonitors: [Any] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("settings.title".localized(with: languageManager))
                    .font(.system(size: 20, weight: .bold))
                    .padding(.bottom, 2)

                // General section
                VStack(alignment: .leading, spacing: 6) {
                    Text("settings.section.general".localized(with: languageManager))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)

                    settingsSection {
                        SettingsRow(iconName: "globe", iconColor: .blue, title: "settings.language".localized(with: languageManager)) {
                            Picker("", selection: $languageManager.currentLanguage) {
                                ForEach(AppLanguage.allCases) { language in
                                    Text(language.displayName).tag(language)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 140)
                        }

                        Divider()

                        SettingsRow(iconName: "power", iconColor: .orange, title: "settings.launchAtLogin".localized(with: languageManager)) {
                            Toggle("", isOn: $launchAtLogin)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .onChange(of: launchAtLogin) { newValue in
                                    setLaunchAtLogin(newValue)
                                }
                        }

                        Divider()

                        SettingsRow(iconName: "arrow.clockwise", iconColor: .green, title: "settings.restorePreviousLockState".localized(with: languageManager)) {
                            Toggle("", isOn: $restorePreviousLockState)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                    }
                }

                // Shortcut & Temporary Switch section
                VStack(alignment: .leading, spacing: 6) {
                    Text("settings.section.shortcut".localized(with: languageManager))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)

                    settingsSection {
                        SettingsRow(iconName: "keyboard", iconColor: .purple, title: "settings.temporaryInputShortcut".localized(with: languageManager)) {
                            HStack(spacing: 8) {
                                Button(action: {
                                    startShortcutRecording()
                                }) {
                                    Text(shortcutButtonTitle)
                                        .font(AppTypography.control)
                                        .lineLimit(1)
                                        .frame(width: 110, alignment: .leading)
                                }
                                .buttonStyle(.bordered)

                                Button(action: {
                                    shortcutManager.clearShortcut()
                                    stopShortcutRecording()
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .semibold))
                                        .frame(width: 20, height: 20)
                                }
                                .buttonStyle(.bordered)
                                .disabled(shortcutManager.shortcut == nil && !isRecordingShortcut)
                                .help("settings.clearShortcut".localized(with: languageManager))
                            }
                        }

                        Divider()

                        SettingsRow(iconName: "arrow.right.circle", iconColor: .teal, title: "settings.temporaryInputSource".localized(with: languageManager)) {
                            Picker("", selection: $temporaryInputSourceID) {
                                Text("settings.temporaryInputSourceAutomatic".localized(with: languageManager))
                                    .tag("")

                                ForEach(inputManager.availableInputSources, id: \.self) { source in
                                    Text(inputManager.getInputSourceName(source))
                                        .tag(inputManager.getInputSourceID(source))
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 170)
                        }

                        Divider()

                        SettingsRow(iconName: "timer", iconColor: .red, title: "settings.temporaryInputRestoreInterval".localized(with: languageManager)) {
                            Stepper(value: $temporaryInputRestoreInterval, in: 1...60, step: 1) {
                                Text(String(format: "settings.secondsFormat".localized(with: languageManager), Int(temporaryInputRestoreInterval)))
                                    .font(AppTypography.control)
                            }
                        }

                        Divider()

                        Text(String(format: "settings.temporaryInputHint".localized(with: languageManager), Int(temporaryInputRestoreInterval)))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                    }
                }

                // About section
                VStack(alignment: .leading, spacing: 6) {
                    Text("settings.section.about".localized(with: languageManager))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)

                    settingsSection {
                        SettingsRow(iconName: "info.circle", iconColor: .gray, title: "settings.about".localized(with: languageManager)) {
                            Link(destination: URL(string: "https://github.com/trah01/inputlock-extend")!) {
                                Text("settings.projectLink".localized(with: languageManager))
                                    .font(AppTypography.control)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .frame(width: 460, height: 500)
        .onDisappear {
            stopShortcutRecording()
        }
    }

    var shortcutButtonTitle: String {
        if isRecordingShortcut {
            return "settings.recordingShortcut".localized(with: languageManager)
        }

        return shortcutManager.shortcut?.displayText
            ?? "settings.setShortcut".localized(with: languageManager)
    }

    func settingsSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 0.5)
        )
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to set launch at login: \(error)")
            }
        }
    }

    func startShortcutRecording() {
        stopShortcutRecording()
        isRecordingShortcut = true

        let keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                stopShortcutRecording()
                return nil
            }

            if event.keyCode == 51 {
                shortcutManager.clearShortcut()
                stopShortcutRecording()
                return nil
            }

            if shortcutManager.updateShortcut(from: event) {
                stopShortcutRecording()
            }
            return nil
        }

        let flagsChangedMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            if shortcutManager.updateShortcut(from: event) {
                stopShortcutRecording()
                return nil
            }

            return event
        }

        shortcutRecordingMonitors = [keyDownMonitor, flagsChangedMonitor].compactMap { $0 }
    }

    func stopShortcutRecording() {
        for monitor in shortcutRecordingMonitors {
            NSEvent.removeMonitor(monitor)
        }
        shortcutRecordingMonitors.removeAll()
        isRecordingShortcut = false
    }
}

struct SettingsRowIcon: View {
    let name: String
    let color: Color
    
    var body: some View {
        Image(systemName: name)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 22, height: 22)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
            )
    }
}

struct SettingsRow<Content: View>: View {
    let iconName: String
    let iconColor: Color
    let title: String
    @ViewBuilder let control: () -> Content
    
    var body: some View {
        HStack(spacing: 12) {
            SettingsRowIcon(name: iconName, color: iconColor)
            
            Text(title)
                .font(AppTypography.primary)
                .foregroundColor(.primary)
            
            Spacer()
            
            control()
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG && canImport(PreviewsMacros)
#Preview {
    SettingsView()
}
#endif
