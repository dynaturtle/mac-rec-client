import Foundation
import SwiftUI

// MARK: - App Constants
struct AppConstants {
    
    // MARK: - App Information
    static let appName = "VoiceNotes"
    static let appVersion = "1.0.0"
    static let appBundleIdentifier = "com.voicenotes.mac"
    
    // MARK: - File System
    struct FileSystem {
        static let transcriptsDirectoryName = "Transcripts"
        static let audioDirectoryName = "Audio"
        static let settingsFileName = "settings.json"
        static let transcriptsFileName = "transcripts.json"
        
        static let supportedAudioFormats = ["m4a", "wav", "mp3", "aiff", "caf"]
        static let supportedExportFormats = ["txt", "md", "json", "pdf", "docx"]
        
        static let maxFileNameLength = 255
        static let maxDirectoryDepth = 10
    }
    
    // MARK: - Audio Recording
    struct Audio {
        static let defaultSampleRate: Double = 44100.0
        static let defaultChannels: UInt32 = 1
        static let defaultBitDepth: UInt32 = 16
        
        static let minRecordingDuration: TimeInterval = 1.0
        static let maxRecordingDuration: TimeInterval = 3600.0 // 1 hour
        static let defaultMaxRecordingDuration: TimeInterval = 1800.0 // 30 minutes
        
        static let audioLevelUpdateInterval: TimeInterval = 0.1
        static let audioBufferSize: UInt32 = 1024
        
        // Quality settings
        struct Quality {
            static let lowBitRate: Int = 64000
            static let mediumBitRate: Int = 128000
            static let highBitRate: Int = 256000
            static let losslessBitRate: Int = 0 // Use lossless compression
        }
    }
    
    // MARK: - Speech Recognition
    struct SpeechRecognition {
        static let defaultLanguage = "en-US"
        static let supportedLanguages = [
            "en-US": "English (US)",
            "en-GB": "English (UK)",
            "es-ES": "Spanish (Spain)",
            "es-MX": "Spanish (Mexico)",
            "fr-FR": "French (France)",
            "de-DE": "German (Germany)",
            "it-IT": "Italian (Italy)",
            "pt-BR": "Portuguese (Brazil)",
            "zh-CN": "Chinese (Simplified)",
            "zh-TW": "Chinese (Traditional)",
            "ja-JP": "Japanese",
            "ko-KR": "Korean",
            "ru-RU": "Russian",
            "ar-SA": "Arabic (Saudi Arabia)"
        ]
        
        static let defaultConfidenceThreshold: Double = 0.5
        static let minConfidenceThreshold: Double = 0.0
        static let maxConfidenceThreshold: Double = 1.0
        
        static let transcriptionTimeout: TimeInterval = 30.0
        static let segmentMinDuration: TimeInterval = 0.5
        static let segmentMaxDuration: TimeInterval = 30.0
    }
    
    // MARK: - User Interface
    struct UI {
        // Window sizes
        static let minWindowWidth: CGFloat = 800
        static let minWindowHeight: CGFloat = 600
        static let defaultWindowWidth: CGFloat = 1000
        static let defaultWindowHeight: CGFloat = 700
        
        // Sidebar
        static let sidebarMinWidth: CGFloat = 250
        static let sidebarMaxWidth: CGFloat = 400
        static let sidebarDefaultWidth: CGFloat = 300
        
        // Animation durations
        static let shortAnimationDuration: TimeInterval = 0.2
        static let mediumAnimationDuration: TimeInterval = 0.3
        static let longAnimationDuration: TimeInterval = 0.5
        
        // Colors
        static let recordingColor = Color.red
        static let transcribingColor = Color.blue
        static let successColor = Color.green
        static let warningColor = Color.orange
        static let errorColor = Color.red
        
        // Spacing
        static let smallSpacing: CGFloat = 4
        static let mediumSpacing: CGFloat = 8
        static let largeSpacing: CGFloat = 16
        static let extraLargeSpacing: CGFloat = 24
        
        // Corner radius
        static let smallCornerRadius: CGFloat = 4
        static let mediumCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 12
    }
    
    // MARK: - Menu Bar
    struct MenuBar {
        static let iconSize: CGFloat = 18
        static let popoverWidth: CGFloat = 300
        static let popoverHeight: CGFloat = 400
        
        static let quickActionsCount = 5
        static let recentTranscriptsCount = 3
    }
    
    // MARK: - Keyboard Shortcuts
    struct KeyboardShortcuts {
        static let defaultRecordingShortcut = "⌘R"
        static let defaultSettingsShortcut = "⌘,"
        static let defaultNewRecordingShortcut = "⌘N"
        static let defaultStopRecordingShortcut = "⌘."
        static let defaultPlayPauseShortcut = "Space"
        static let defaultDeleteShortcut = "⌫"
    }
    
    // MARK: - Performance
    struct Performance {
        static let maxConcurrentTranscriptions = 1
        static let maxCachedTranscripts = 100
        static let maxRecentTranscripts = 10
        
        static let backgroundTaskTimeout: TimeInterval = 30.0
        static let networkRequestTimeout: TimeInterval = 30.0
        
        // Memory limits
        static let maxMemoryUsage: Int64 = 500 * 1024 * 1024 // 500 MB
        static let maxCacheSize: Int64 = 100 * 1024 * 1024 // 100 MB
    }
    
    // MARK: - Notifications
    struct Notifications {
        static let recordingStartedTitle = "Recording Started"
        static let recordingStoppedTitle = "Recording Stopped"
        static let transcriptionCompletedTitle = "Transcription Complete"
        static let transcriptionFailedTitle = "Transcription Failed"
        static let errorTitle = "VoiceNotes Error"
        
        static let notificationDisplayDuration: TimeInterval = 3.0
    }
    
    // MARK: - Privacy & Security
    struct Privacy {
        static let microphoneUsageDescription = "VoiceNotes needs microphone access to record audio for transcription."
        static let localProcessingOnly = true
        static let dataRetentionDays = 0 // 0 means indefinite, user controlled
        
        static let encryptionEnabled = false // For future implementation
        static let cloudSyncEnabled = false // For future implementation
    }
    
    // MARK: - Error Messages
    struct ErrorMessages {
        static let genericError = "An unexpected error occurred. Please try again."
        static let microphonePermissionDenied = "Microphone access is required to record audio. Please grant permission in System Preferences > Security & Privacy > Privacy > Microphone."
        static let audioSessionFailed = "Failed to set up audio session. Please check your audio settings and try again."
        static let recordingFailed = "Recording failed. Please check your microphone and try again."
        static let transcriptionFailed = "Transcription failed. Please try again or check your internet connection."
        static let fileOperationFailed = "File operation failed. Please check your permissions and available disk space."
        static let invalidAudioFormat = "The selected audio format is not supported. Please choose a different format."
        static let diskSpaceLow = "Low disk space. Please free up some space and try again."
        static let networkError = "Network error. Please check your internet connection and try again."
    }
    
    // MARK: - Default Settings
    struct DefaultSettings {
        static let showMenuBarIcon = true
        static let autoStartRecording = false
        static let audioFormat = AudioFormat.m4a
        static let audioQuality = AudioQuality.high
        static let language = "auto"
        static let transcriptionConfidence = 0.7
        static let autoSaveTranscripts = true
        static let maxRecordingDuration = 1800.0 // 30 minutes
        static let showNotifications = true
        static let theme = AppTheme.system
        static let showTranscriptionConfidence = true
    }
    
    // MARK: - URLs and Links
    struct URLs {
        static let appWebsite = "https://voicenotes.app"
        static let supportEmail = "support@voicenotes.app"
        static let privacyPolicy = "https://voicenotes.app/privacy"
        static let termsOfService = "https://voicenotes.app/terms"
        static let documentation = "https://docs.voicenotes.app"
        static let github = "https://github.com/voicenotes/mac"
    }
    
    // MARK: - Feature Flags
    struct FeatureFlags {
        static let enableCloudSync = false
        static let enableAdvancedExport = true
        static let enableRealTimeTranscription = true
        static let enableMultipleLanguages = true
        static let enableAudioVisualization = true
        static let enableKeyboardShortcuts = true
        static let enableMenuBarIntegration = true
        static let enableNotifications = true
    }
    
    // MARK: - Development
    struct Development {
        static let isDebugMode = false
        static let enableLogging = true
        static let logLevel = "INFO" // DEBUG, INFO, WARNING, ERROR
        static let enableAnalytics = false
        static let enableCrashReporting = false
    }
}

// MARK: - System Requirements
struct SystemRequirements {
    static let minimumMacOSVersion = "13.0"
    static let recommendedMacOSVersion = "14.0"
    static let minimumRAM: Int64 = 4 * 1024 * 1024 * 1024 // 4 GB
    static let recommendedRAM: Int64 = 8 * 1024 * 1024 * 1024 // 8 GB
    static let minimumDiskSpace: Int64 = 100 * 1024 * 1024 // 100 MB
    static let recommendedDiskSpace: Int64 = 1024 * 1024 * 1024 // 1 GB
}

// MARK: - Build Configuration
#if DEBUG
extension AppConstants.Development {
    static let isDebugMode = true
    static let enableLogging = true
    static let logLevel = "DEBUG"
}
#endif