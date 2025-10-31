import Foundation
import SwiftUI

class Settings: ObservableObject {
    @AppStorage("showMenuBarIcon") var showMenuBarIcon: Bool = true
    @AppStorage("autoStartRecording") var autoStartRecording: Bool = false
    @AppStorage("saveLocation") var saveLocation: String = ""
    @AppStorage("audioFormat") var audioFormat: AudioFormat = .m4a
    @AppStorage("audioQuality") var audioQuality: AudioQuality = .high
    @AppStorage("language") var language: String = "en-US"
    @AppStorage("enableKeyboardShortcuts") var enableKeyboardShortcuts: Bool = true
    @AppStorage("showTranscriptionConfidence") var showTranscriptionConfidence: Bool = false
    @AppStorage("autoSaveTranscripts") var autoSaveTranscripts: Bool = true
    @AppStorage("maxRecordingDuration") var maxRecordingDuration: Double = 3600 // 1 hour in seconds
    @AppStorage("enableNotifications") var enableNotifications: Bool = true
    @AppStorage("showNotifications") var showNotifications: Bool = true
    @AppStorage("theme") var theme: AppTheme = .system
    @AppStorage("transcriptionConfidence") var transcriptionConfidence: Double = 0.5
    @AppStorage("recordingShortcut") var recordingShortcut: String = "⌘R"
    @AppStorage("settingsShortcut") var settingsShortcut: String = "⌘,"
    
    init() {
        // Set default save location if not set
        if saveLocation.isEmpty {
            saveLocation = FileManager.default.urls(for: .documentDirectory, 
                                                  in: .userDomainMask).first?.path ?? ""
        }
    }
    
    var saveLocationURL: URL? {
        guard !saveLocation.isEmpty else { return nil }
        return URL(fileURLWithPath: saveLocation)
    }
    
    func setSaveLocation(_ url: URL) {
        saveLocation = url.path
    }
    
    var availableLanguages: [String] {
        return [
            "en-US", "en-GB", "en-AU", "en-CA",
            "es-ES", "es-MX", "fr-FR", "fr-CA",
            "de-DE", "it-IT", "pt-BR", "pt-PT",
            "ru-RU", "ja-JP", "ko-KR", "zh-CN",
            "zh-TW", "ar-SA", "hi-IN", "nl-NL",
            "sv-SE", "da-DK", "no-NO", "fi-FI"
        ]
    }
    
    func languageDisplayName(for code: String) -> String {
        let locale = Locale(identifier: code)
        return locale.localizedString(forLanguageCode: String(code.prefix(2))) ?? code
    }
}

enum AudioFormat: String, CaseIterable, Codable {
    case m4a = "m4a"
    case wav = "wav"
    case aiff = "aiff"
    
    var displayName: String {
        switch self {
        case .m4a: return "M4A (Compressed)"
        case .wav: return "WAV (Uncompressed)"
        case .aiff: return "AIFF (Uncompressed)"
        }
    }
    
    var fileExtension: String {
        return rawValue
    }
}

enum AudioQuality: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case lossless = "lossless"
    
    var displayName: String {
        switch self {
        case .low: return "Low (32 kbps)"
        case .medium: return "Medium (128 kbps)"
        case .high: return "High (256 kbps)"
        case .lossless: return "Lossless"
        }
    }
    
    var bitRate: Int {
        switch self {
        case .low: return 32000
        case .medium: return 128000
        case .high: return 256000
        case .lossless: return 0 // Will use lossless encoding
        }
    }
}

enum AppTheme: String, CaseIterable, Codable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}