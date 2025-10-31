import Foundation

enum AppState: Equatable {
    case idle
    case recording(startTime: Date, duration: TimeInterval)
    case transcribing(audioURL: URL, progress: Double)
    case ready(transcript: Transcript)
    case error(ErrorType, context: String?)
    
    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.recording(let lhsStart, let lhsDuration), .recording(let rhsStart, let rhsDuration)):
            return lhsStart == rhsStart && lhsDuration == rhsDuration
        case (.transcribing(let lhsURL, let lhsProgress), .transcribing(let rhsURL, let rhsProgress)):
            return lhsURL == rhsURL && lhsProgress == rhsProgress
        case (.ready(let lhsTranscript), .ready(let rhsTranscript)):
            return lhsTranscript == rhsTranscript
        case (.error(let lhsError, let lhsContext), .error(let rhsError, let rhsContext)):
            return lhsError == rhsError && lhsContext == rhsContext
        default:
            return false
        }
    }
}

enum ErrorType: String, CaseIterable, Equatable {
    // Microphone Errors
    case microphoneNotAvailable = "microphone_not_available"
    case microphonePermissionDenied = "microphone_permission_denied"
    case microphoneInUse = "microphone_in_use"
    
    // Speech Recognition Errors
    case speechModelUnavailable = "speech_model_unavailable"
    case speechRecognitionFailed = "speech_recognition_failed"
    case speechRecognitionTimeout = "speech_recognition_timeout"
    case speechPermissionDenied = "speech_permission_denied"
    
    // Storage Errors
    case diskFull = "disk_full"
    case writePermissionDenied = "write_permission_denied"
    case corruptedAudio = "corrupted_audio"
    
    // General Errors
    case unknown = "unknown"
    
    var localizedDescription: String {
        switch self {
        case .microphoneNotAvailable:
            return "No microphone detected. Please connect a microphone and try again."
        case .microphonePermissionDenied:
            return "Microphone access required. Please enable in System Settings > Privacy & Security > Microphone."
        case .microphoneInUse:
            return "Microphone is being used by another app. Please close other audio apps and try again."
        case .speechModelUnavailable:
            return "Speech recognition not available for selected language. Please check System Settings > General > Language & Region."
        case .speechRecognitionFailed:
            return "Could not transcribe audio. Please ensure clear speech and try again."
        case .speechRecognitionTimeout:
            return "Transcription taking longer than expected. The audio file has been saved for manual processing."
        case .speechPermissionDenied:
            return "Speech recognition permission required. Please enable in System Settings > Privacy & Security > Speech Recognition."
        case .diskFull:
            return "Not enough storage space. Please free up disk space and try again."
        case .writePermissionDenied:
            return "Cannot save file to selected location. Please choose a different location or check permissions."
        case .corruptedAudio:
            return "Audio file appears corrupted. Please try recording again."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
}