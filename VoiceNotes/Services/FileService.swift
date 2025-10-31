import Foundation
// UniformTypeIdentifiers not available in macOS 10.15, using string constants instead

class FileService: ObservableObject {
    private let settings: Settings
    private let fileManager = FileManager.default
    
    init(settings: Settings) {
        self.settings = settings
        createDirectoriesIfNeeded()
    }
    
    // MARK: - Directory Management
    
    private func createDirectoriesIfNeeded() {
        guard let saveLocation = settings.saveLocationURL else { return }
        
        let transcriptsDir = saveLocation.appendingPathComponent("Transcripts")
        let audioDir = saveLocation.appendingPathComponent("Audio")
        
        try? fileManager.createDirectory(at: transcriptsDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: audioDir, withIntermediateDirectories: true)
    }
    
    var transcriptsDirectory: URL? {
        return settings.saveLocationURL?.appendingPathComponent("Transcripts")
    }
    
    var audioDirectory: URL? {
        return settings.saveLocationURL?.appendingPathComponent("Audio")
    }
    
    // MARK: - Transcript Management
    
    func saveTranscript(_ transcript: Transcript) throws {
        guard let transcriptsDir = transcriptsDirectory else {
            throw FileServiceError.invalidSaveLocation
        }
        
        let fileName = "transcript_\(transcript.id.uuidString).json"
        let fileURL = transcriptsDir.appendingPathComponent(fileName)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(transcript)
        try data.write(to: fileURL)
    }
    
    func loadTranscript(withID id: UUID) throws -> Transcript {
        guard let transcriptsDir = transcriptsDirectory else {
            throw FileServiceError.invalidSaveLocation
        }
        
        let fileName = "transcript_\(id.uuidString).json"
        let fileURL = transcriptsDir.appendingPathComponent(fileName)
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(Transcript.self, from: data)
    }
    
    func loadAllTranscripts() throws -> [Transcript] {
        guard let transcriptsDir = transcriptsDirectory else {
            throw FileServiceError.invalidSaveLocation
        }
        
        let fileURLs = try fileManager.contentsOfDirectory(at: transcriptsDir, 
                                                          includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
        
        var transcripts: [Transcript] = []
        
        for fileURL in fileURLs {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let transcript = try decoder.decode(Transcript.self, from: data)
                transcripts.append(transcript)
            } catch {
                print("Failed to load transcript from \(fileURL): \(error)")
            }
        }
        
        return transcripts.sorted { $0.createdAt > $1.createdAt }
    }
    
    func deleteTranscript(withID id: UUID) throws {
        guard let transcriptsDir = transcriptsDirectory else {
            throw FileServiceError.invalidSaveLocation
        }
        
        let fileName = "transcript_\(id.uuidString).json"
        let fileURL = transcriptsDir.appendingPathComponent(fileName)
        
        try fileManager.removeItem(at: fileURL)
    }
    
    // MARK: - Export Functions
    
    func exportTranscriptAsText(_ transcript: Transcript, to url: URL) throws {
        var content = "VoiceNotes Transcript\n"
        content += "=====================\n\n"
        content += "Date: \(transcript.formattedDate)\n"
        content += "Duration: \(transcript.formattedDuration)\n"
        content += "Language: \(transcript.language)\n"
        content += "Word Count: \(transcript.wordCount)\n"
        
        if settings.showTranscriptionConfidence {
            content += "Confidence: \(String(format: "%.1f%%", transcript.confidence * 100))\n"
        }
        
        content += "\n--- Transcript ---\n\n"
        content += transcript.text
        
        if !transcript.segments.isEmpty {
            content += "\n\n--- Segments ---\n\n"
            for segment in transcript.segments {
                content += "[\(segment.formattedTimeRange)] \(segment.text)\n"
            }
        }
        
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
    
    func exportTranscriptAsMarkdown(_ transcript: Transcript, to url: URL) throws {
        var content = "# VoiceNotes Transcript\n\n"
        content += "**Date:** \(transcript.formattedDate)  \n"
        content += "**Duration:** \(transcript.formattedDuration)  \n"
        content += "**Language:** \(transcript.language)  \n"
        content += "**Word Count:** \(transcript.wordCount)  \n"
        
        if settings.showTranscriptionConfidence {
            content += "**Confidence:** \(String(format: "%.1f%%", transcript.confidence * 100))  \n"
        }
        
        content += "\n## Transcript\n\n"
        content += transcript.text
        
        if !transcript.segments.isEmpty {
            content += "\n\n## Segments\n\n"
            for segment in transcript.segments {
                content += "**\(segment.formattedTimeRange):** \(segment.text)\n\n"
            }
        }
        
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
    
    func exportTranscriptAsJSON(_ transcript: Transcript, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(transcript)
        try data.write(to: url)
    }
    
    // MARK: - Audio File Management
    
    func moveAudioFile(from sourceURL: URL, associatedWith transcript: Transcript) throws -> URL {
        guard let audioDir = audioDirectory else {
            throw FileServiceError.invalidSaveLocation
        }
        
        let fileName = "audio_\(transcript.id.uuidString).\(sourceURL.pathExtension)"
        let destinationURL = audioDir.appendingPathComponent(fileName)
        
        // If source and destination are the same, no need to move
        if sourceURL == destinationURL {
            return destinationURL
        }
        
        // Remove existing file if it exists
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        try fileManager.moveItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }
    
    func deleteAudioFile(for transcript: Transcript) throws {
        let audioURL = transcript.audioURL
        
        if fileManager.fileExists(atPath: audioURL.path) {
            try fileManager.removeItem(at: audioURL)
        }
    }
    
    // MARK: - File System Utilities
    
    func getFileSize(at url: URL) -> Int64? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
    
    func getAvailableDiskSpace() -> Int64? {
        guard let saveLocation = settings.saveLocationURL else { return nil }
        
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: saveLocation.path)
            return attributes[.systemFreeSize] as? Int64
        } catch {
            return nil
        }
    }
    
    func validateSaveLocation() -> Bool {
        guard let saveLocation = settings.saveLocationURL else { return false }
        
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: saveLocation.path, isDirectory: &isDirectory)
        
        return exists && isDirectory.boolValue
    }
    
    // MARK: - Import Functions
    
    func importAudioFile(from url: URL) throws -> URL {
        guard let audioDir = audioDirectory else {
            throw FileServiceError.invalidSaveLocation
        }
        
        let fileName = url.lastPathComponent
        let destinationURL = audioDir.appendingPathComponent(fileName)
        
        // Check if file already exists
        if fileManager.fileExists(atPath: destinationURL.path) {
            let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
            let fileExtension = url.pathExtension
            let timestamp = DateFormatter.fileNameFormatter.string(from: Date())
            let newFileName = "\(nameWithoutExtension)_\(timestamp).\(fileExtension)"
            let newDestinationURL = audioDir.appendingPathComponent(newFileName)
            
            try fileManager.copyItem(at: url, to: newDestinationURL)
            return newDestinationURL
        } else {
            try fileManager.copyItem(at: url, to: destinationURL)
            return destinationURL
        }
    }
    
    func getSupportedAudioFormats() -> [String] {
        return [
            "public.audio",
            "public.mp3",
            "public.mpeg-4-audio",
            "com.microsoft.waveform-audio",
            "public.aiff-audio"
        ]
    }
}

enum FileServiceError: LocalizedError {
    case invalidSaveLocation
    case fileNotFound
    case insufficientDiskSpace
    case writePermissionDenied
    case unsupportedFileFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidSaveLocation:
            return "Invalid save location. Please check your settings."
        case .fileNotFound:
            return "File not found."
        case .insufficientDiskSpace:
            return "Insufficient disk space."
        case .writePermissionDenied:
            return "Write permission denied. Please check folder permissions."
        case .unsupportedFileFormat:
            return "Unsupported file format."
        }
    }
}