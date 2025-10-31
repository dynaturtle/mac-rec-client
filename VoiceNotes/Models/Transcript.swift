import Foundation

struct Transcript: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let text: String
    let audioURL: URL
    let createdAt: Date
    let duration: TimeInterval
    let language: String
    let confidence: Double
    let segments: [TranscriptSegment]
    
    init(
        id: UUID = UUID(),
        text: String,
        audioURL: URL,
        createdAt: Date = Date(),
        duration: TimeInterval,
        language: String = "en-US",
        confidence: Double = 0.0,
        segments: [TranscriptSegment] = []
    ) {
        self.id = id
        self.text = text
        self.audioURL = audioURL
        self.createdAt = createdAt
        self.duration = duration
        self.language = language
        self.confidence = confidence
        self.segments = segments
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    var wordCount: Int {
        return text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
    
    var averageWordsPerMinute: Double {
        guard duration > 0 else { return 0 }
        return Double(wordCount) / (duration / 60.0)
    }
}

struct TranscriptSegment: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let confidence: Double
    
    init(
        id: UUID = UUID(),
        text: String,
        startTime: TimeInterval,
        endTime: TimeInterval,
        confidence: Double
    ) {
        self.id = id
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.confidence = confidence
    }
    
    var duration: TimeInterval {
        return endTime - startTime
    }
    
    var formattedTimeRange: String {
        let startMinutes = Int(startTime) / 60
        let startSeconds = Int(startTime) % 60
        let endMinutes = Int(endTime) / 60
        let endSecondsInt = Int(endTime) % 60
        
        return String(format: "%d:%02d - %d:%02d", 
                     startMinutes, startSeconds, 
                     endMinutes, endSecondsInt)
    }
}