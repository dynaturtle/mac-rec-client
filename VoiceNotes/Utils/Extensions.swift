import Foundation
import SwiftUI
import AVFoundation

// MARK: - Date Extensions
extension Date {
    var formattedForDisplay: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDate(self, inSameDayAs: Date()) {
            formatter.dateFormat = "h:mm a"
            return "Today, \(formatter.string(from: self))"
        } else if calendar.isDate(self, inSameDayAs: Date().addingTimeInterval(-86400)) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday, \(formatter.string(from: self))"
        } else if calendar.isDate(self, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE, h:mm a"
            return formatter.string(from: self)
        } else {
            formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
            return formatter.string(from: self)
        }
    }
    
    var formattedForFilename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: self)
    }
}

// MARK: - TimeInterval Extensions
extension TimeInterval {
    var formattedDuration: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var formattedShortDuration: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - String Extensions
extension String {
    var wordCount: Int {
        let words = self.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    var estimatedReadingTime: TimeInterval {
        let wordsPerMinute: Double = 200 // Average reading speed
        let words = Double(self.wordCount)
        return (words / wordsPerMinute) * 60
    }
    
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count <= length {
            return self
        }
        return String(self.prefix(length)) + trailing
    }
}

// MARK: - URL Extensions
extension URL {
    var fileSize: Int64? {
        do {
            let resourceValues = try self.resourceValues(forKeys: [.fileSizeKey])
            return Int64(resourceValues.fileSize ?? 0)
        } catch {
            return nil
        }
    }
    
    var formattedFileSize: String {
        guard let size = fileSize else { return "Unknown" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var creationDate: Date? {
        do {
            let resourceValues = try self.resourceValues(forKeys: [.creationDateKey])
            return resourceValues.creationDate
        } catch {
            return nil
        }
    }
}

// MARK: - Color Extensions
extension Color {
    static let recordingRed = Color(red: 0.9, green: 0.2, blue: 0.2)
    static let transcribingBlue = Color(red: 0.2, green: 0.6, blue: 0.9)
    static let successGreen = Color(red: 0.2, green: 0.8, blue: 0.3)
    static let warningOrange = Color(red: 0.9, green: 0.6, blue: 0.1)
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions
extension View {
    func pulse(isActive: Bool = true) -> some View {
        self.scaleEffect(isActive ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isActive)
    }
    
    func shake(isActive: Bool = false) -> some View {
        self.offset(x: isActive ? -5 : 0)
            .animation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true), value: isActive)
    }
    
    func glow(color: Color = .blue, radius: CGFloat = 10) -> some View {
        self.shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
    }
}

// MARK: - AVAudioSession Extensions (iOS only)
#if os(iOS)
extension AVAudioSession {
    var isInputAvailable: Bool {
        return !availableInputs?.isEmpty ?? false
    }
    
    var currentInputName: String {
        return currentRoute.inputs.first?.portName ?? "Unknown"
    }
}
#endif

// MARK: - Notification Extensions
extension Notification.Name {
    static let recordingStarted = Notification.Name("recordingStarted")
    static let recordingStopped = Notification.Name("recordingStopped")
    static let transcriptionCompleted = Notification.Name("transcriptionCompleted")
    static let transcriptionFailed = Notification.Name("transcriptionFailed")
    static let settingsChanged = Notification.Name("settingsChanged")
}

// MARK: - UserDefaults Extensions
extension UserDefaults {
    private enum Keys {
        static let transcripts = "VoiceNotesTranscripts"
        static let lastSaveLocation = "LastSaveLocation"
    }
    
    func setLastSaveLocation(_ url: URL) {
        set(url.path, forKey: Keys.lastSaveLocation)
    }
    
    func getLastSaveLocation() -> URL? {
        guard let path = string(forKey: Keys.lastSaveLocation) else { return nil }
        return URL(fileURLWithPath: path)
    }
}

// MARK: - FileManager Extensions
extension FileManager {
    var documentsDirectory: URL {
        urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    var applicationSupportDirectory: URL {
        let url = urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appURL = url.appendingPathComponent("VoiceNotes")
        
        if !fileExists(atPath: appURL.path) {
            try? createDirectory(at: appURL, withIntermediateDirectories: true)
        }
        
        return appURL
    }
    
    func createDirectoryIfNeeded(at url: URL) throws {
        if !fileExists(atPath: url.path) {
            try createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    func sizeOfDirectory(at url: URL) -> Int64 {
        guard let enumerator = enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            } catch {
                continue
            }
        }
        
        return totalSize
    }
}

// MARK: - Error Extensions
extension Error {
    var userFriendlyDescription: String {
        if let appError = self as? AppError {
            return appError.localizedDescription
        }
        return self.localizedDescription
    }
}

// MARK: - Custom Error Types
enum AppError: LocalizedError {
    case microphonePermissionDenied
    case audioSessionSetupFailed
    case recordingFailed(String)
    case transcriptionFailed(String)
    case fileOperationFailed(String)
    case invalidAudioFormat
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access is required to record audio. Please grant permission in System Preferences."
        case .audioSessionSetupFailed:
            return "Failed to set up audio session. Please check your audio settings."
        case .recordingFailed(let message):
            return "Recording failed: \(message)"
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        case .fileOperationFailed(let message):
            return "File operation failed: \(message)"
        case .invalidAudioFormat:
            return "The selected audio format is not supported."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Export Format
enum ExportFormat: String, CaseIterable {
    case text = "txt"
    case markdown = "md"
    case json = "json"
    
    var displayName: String {
        switch self {
        case .text: return "Plain Text"
        case .markdown: return "Markdown"
        case .json: return "JSON"
        }
    }
    
    var fileExtension: String {
        return self.rawValue
    }
}