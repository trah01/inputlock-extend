//
//  LanguageManager.swift
//  lockinput
//
//  Created by dave on 2025/12/19.
//

import Foundation
import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case chinese = "zh-Hans"
    case french = "fr"
    case german = "de"
    case japanese = "ja"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return String(localized: "language.system")
        case .english: return String(localized: "language.en")
        case .chinese: return String(localized: "language.zh-Hans")
        case .french: return String(localized: "language.fr")
        case .german: return String(localized: "language.de")
        case .japanese: return String(localized: "language.ja")
        }
    }

    var locale: Locale? {
        switch self {
        case .system: return nil
        case .english: return Locale(identifier: "en")
        case .chinese: return Locale(identifier: "zh-Hans")
        case .french: return Locale(identifier: "fr")
        case .german: return Locale(identifier: "de")
        case .japanese: return Locale(identifier: "ja")
        }
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @AppStorage("selectedLanguage") private var storedLanguage: String = AppLanguage.system.rawValue

    @Published var currentLanguage: AppLanguage {
        didSet {
            storedLanguage = currentLanguage.rawValue
            applyLanguage()
        }
    }

    @Published var bundle: Bundle = .main

    init() {
        let stored = AppLanguage(rawValue: UserDefaults.standard.string(forKey: "selectedLanguage") ?? "system") ?? .system
        self.currentLanguage = stored
        applyLanguage()
    }

    func applyLanguage() {
        let languageCode: String

        if currentLanguage == .system {
            languageCode = Locale.preferredLanguages.first ?? "en"
        } else {
            languageCode = currentLanguage.rawValue
        }

        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
                  let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            self.bundle = .main
        }

        objectWillChange.send()
    }

    func localizedString(_ key: String) -> String {
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

extension String {
    func localized(with manager: LanguageManager) -> String {
        return manager.localizedString(self)
    }
}
