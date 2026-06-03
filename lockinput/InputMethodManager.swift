//
//  InputMethodManager.swift
//  lockinput
//
//  Created by dave on 2025/12/19.
//

import AppKit
import Carbon
import Combine

class InputMethodManager: ObservableObject {
    static let shared = InputMethodManager()

    @Published var isLocked = false
    @Published var lockedInputSource: TISInputSource?
    @Published var lockedInputSourceID: String?
    @Published var currentInputSourceName: String = ""
    @Published var availableInputSources: [TISInputSource] = []

    private var lockState = InputSourceLockState()
    private var notificationObservers: [NSObjectProtocol] = []
    private var enforcementTimer: Timer?
    private var isEnforcingLockedSource = false

    init() {
        loadAvailableInputSources()
        updateCurrentInputSourceName()
        setupInputSourceChangeObservers()
    }

    deinit {
        for observer in notificationObservers {
            DistributedNotificationCenter.default().removeObserver(observer)
            NotificationCenter.default.removeObserver(observer)
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        enforcementTimer?.invalidate()
    }

    func loadAvailableInputSources() {
        let conditions = [
            kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource as Any,
            kTISPropertyInputSourceIsSelectCapable: kCFBooleanTrue as Any
        ] as CFDictionary

        guard let sources = TISCreateInputSourceList(conditions, false)?.takeRetainedValue() as? [TISInputSource] else {
            return
        }

        availableInputSources = sources.filter { source in
            if let enabled = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled) {
                return Unmanaged<CFBoolean>.fromOpaque(enabled).takeUnretainedValue() == kCFBooleanTrue
            }
            return false
        }
    }

    func getInputSourceName(_ source: TISInputSource) -> String {
        if let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) {
            return Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
        }
        return "Unknown"
    }

    func getInputSourceID(_ source: TISInputSource) -> String {
        if let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) {
            return Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
        }
        return ""
    }

    func getCurrentInputSource() -> TISInputSource? {
        return TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
    }

    func updateCurrentInputSourceName() {
        if let current = getCurrentInputSource() {
            currentInputSourceName = getInputSourceName(current)
        } else {
            currentInputSourceName = "Unknown"
        }
    }

    @discardableResult
    func selectInputSource(_ source: TISInputSource) -> Bool {
        let result = TISSelectInputSource(source)
        updateCurrentInputSourceName()
        return result == noErr
    }

    func lockCurrentInputSource() {
        guard let current = getCurrentInputSource() else { return }
        lock(source: current)
        updateCurrentInputSourceName()
        enforceLockedInputSource()
    }

    func lockInputSource(_ source: TISInputSource) {
        selectInputSource(source)
        lock(source: source)
        updateCurrentInputSourceName()
        enforceLockedInputSource()
    }

    func unlock() {
        lockState.unlock()
        syncPublishedLockState()
        stopEnforcementTimer()
    }

    func toggle() {
        if isLocked {
            unlock()
        } else {
            lockCurrentInputSource()
        }
    }

    private func setupInputSourceChangeObservers() {
        let distributedCenter = DistributedNotificationCenter.default()
        notificationObservers.append(distributedCenter.addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleInputSourceChange()
        })

        notificationObservers.append(distributedCenter.addObserver(
            forName: NSNotification.Name(kTISNotifyEnabledKeyboardInputSourcesChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadAvailableInputSources()
            self?.refreshLockedInputSource()
            self?.handleInputSourceChange()
        })

        notificationObservers.append(NotificationCenter.default.addObserver(
            forName: NSTextInputContext.keyboardSelectionDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleInputSourceChange()
        })

        notificationObservers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleInputSourceChange()
        })
    }

    private func handleInputSourceChange() {
        updateCurrentInputSourceName()
        enforceLockedInputSource()
    }

    private func lock(source: TISInputSource) {
        let sourceID = getInputSourceID(source)
        guard !sourceID.isEmpty else { return }

        lockState.lock(inputSourceID: sourceID)
        syncPublishedLockState()
        startEnforcementTimer()
    }

    private func syncPublishedLockState() {
        isLocked = lockState.isLocked
        lockedInputSourceID = lockState.lockedInputSourceID
        refreshLockedInputSource()
    }

    private func refreshLockedInputSource() {
        guard let lockedInputSourceID = lockState.lockedInputSourceID else {
            lockedInputSource = nil
            return
        }

        lockedInputSource = inputSource(withID: lockedInputSourceID)
    }

    private func inputSource(withID inputSourceID: String) -> TISInputSource? {
        if let source = availableInputSources.first(where: { getInputSourceID($0) == inputSourceID }) {
            return source
        }

        loadAvailableInputSources()
        return availableInputSources.first { getInputSourceID($0) == inputSourceID }
    }

    private func enforceLockedInputSource() {
        guard lockState.isLocked, !isEnforcingLockedSource else { return }
        guard let lockedInputSourceID = lockState.lockedInputSourceID else { return }
        guard let currentID = getCurrentInputSource().map(getInputSourceID),
              currentID != lockedInputSourceID else { return }
        guard let lockedSource = inputSource(withID: lockedInputSourceID) else { return }

        isEnforcingLockedSource = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            guard let self else { return }
            guard self.lockState.matchesLockedInputSourceID(lockedInputSourceID) else {
                self.isEnforcingLockedSource = false
                return
            }

            if !self.selectInputSource(lockedSource),
               let refreshedSource = self.inputSource(withID: lockedInputSourceID) {
                _ = self.selectInputSource(refreshedSource)
            }
            self.refreshLockedInputSource()
            self.isEnforcingLockedSource = false
        }
    }

    private func startEnforcementTimer() {
        guard enforcementTimer == nil else { return }

        enforcementTimer = Timer(timeInterval: 0.35, repeats: true) { [weak self] _ in
            self?.enforceLockedInputSource()
        }
        if let enforcementTimer {
            RunLoop.main.add(enforcementTimer, forMode: .common)
        }
    }

    private func stopEnforcementTimer() {
        enforcementTimer?.invalidate()
        enforcementTimer = nil
    }
}
