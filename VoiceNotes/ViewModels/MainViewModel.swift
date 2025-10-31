import Foundation
import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    @Published var appState: AppState = .idle
    @Published var transcripts: [Transcript] = []
    @Published var selectedTranscript: Transcript?
    @Published var showingSettings = false
    @Published var showingError = false
    @Published var currentError: (ErrorType, String?)?
    
    let settings: Settings
    private let audioService: AudioRecordingService
    private let speechService: SpeechRecognitionService
    private let fileService: FileService
    
    private var cancellables = Set<AnyCancellable>()
    private var currentRecordingURL: URL?
    
    init(settings: Settings) {
        self.settings = settings
        self.audioService = AudioRecordingService(settings: settings)
        self.speechService = SpeechRecognitionService(settings: settings)
        self.fileService = FileService(settings: settings)
        
        setupBindings()
        loadTranscripts()
    }
    
    private func setupBindings() {
        // Monitor settings changes that affect services
        settings.objectWillChange
            .sink { [weak self] _ in
                // Recreate speech service when language changes
                self?.speechService.cancelTranscription()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Recording Functions
    
    func startRecording() {
        audioService.startRecording { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let recordingURL):
                    self.currentRecordingURL = recordingURL
                    
                    let startTime = Date()
                    self.appState = .recording(startTime: startTime, duration: 0)
                    
                    // Monitor recording duration
                    Timer.publish(every: 0.1, on: .main, in: .common)
                        .autoconnect()
                        .sink { [weak self] _ in
                            guard let self = self,
                                  case .recording(let start, _) = self.appState else { return }
                            
                            let duration = Date().timeIntervalSince(start)
                            self.appState = .recording(startTime: start, duration: duration)
                        }
                        .store(in: &self.cancellables)
                        
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    func stopRecording() {
        audioService.stopRecording { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let url):
                    self.transcribeAudio(from: url)
                    
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    // MARK: - Transcription Functions
    
    private func transcribeAudio(from url: URL) {
        appState = .transcribing(audioURL: url, progress: 0.0)
        
        // Monitor transcription progress
        speechService.$transcriptionProgress
            .sink { [weak self] progress in
                guard let self = self,
                      case .transcribing(let audioURL, _) = self.appState else { return }
                self.appState = .transcribing(audioURL: audioURL, progress: progress)
            }
            .store(in: &cancellables)
        
        speechService.transcribeAudio(from: url) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let transcript):
                    do {
                        // Move audio file to proper location
                        let finalAudioURL = try self.fileService.moveAudioFile(from: url, associatedWith: transcript)
                        
                        // Update transcript with final audio URL
                        let finalTranscript = Transcript(
                            id: transcript.id,
                            text: transcript.text,
                            audioURL: finalAudioURL,
                            createdAt: transcript.createdAt,
                            duration: transcript.duration,
                            language: transcript.language,
                            confidence: transcript.confidence,
                            segments: transcript.segments
                        )
                        
                        // Save transcript if auto-save is enabled
                        if self.settings.autoSaveTranscripts {
                            try self.fileService.saveTranscript(finalTranscript)
                            self.transcripts.insert(finalTranscript, at: 0)
                        }
                        
                        self.appState = .ready(transcript: finalTranscript)
                        self.selectedTranscript = finalTranscript
                        
                    } catch {
                        self.handleError(error)
                    }
                    
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    func retryTranscription() {
        guard case .error(_, _) = appState,
              let audioURL = currentRecordingURL else { return }
        
        transcribeAudio(from: audioURL)
    }
    
    // MARK: - Transcript Management
    
    func loadTranscripts() {
        do {
            transcripts = try fileService.loadAllTranscripts()
        } catch {
            print("Failed to load transcripts: \(error)")
        }
    }
    
    func saveTranscript(_ transcript: Transcript) {
        do {
            try fileService.saveTranscript(transcript)
            
            // Update transcripts list if not already present
            if !transcripts.contains(where: { $0.id == transcript.id }) {
                transcripts.insert(transcript, at: 0)
            }
        } catch {
            handleError(error)
        }
    }
    
    func deleteTranscript(_ transcript: Transcript) {
        do {
            try fileService.deleteTranscript(withID: transcript.id)
            try fileService.deleteAudioFile(for: transcript)
            
            transcripts.removeAll { $0.id == transcript.id }
            
            if selectedTranscript?.id == transcript.id {
                selectedTranscript = nil
            }
            
        } catch {
            handleError(error)
        }
    }
    
    func selectTranscript(_ transcript: Transcript) {
        selectedTranscript = transcript
        appState = .ready(transcript: transcript)
    }
    
    // MARK: - Export Functions
    
    func exportTranscript(_ transcript: Transcript, format: ExportFormat, to url: URL) {
        do {
            switch format {
            case .text:
                try fileService.exportTranscriptAsText(transcript, to: url)
            case .markdown:
                try fileService.exportTranscriptAsMarkdown(transcript, to: url)
            case .json:
                try fileService.exportTranscriptAsJSON(transcript, to: url)
            }
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - State Management
    
    func resetToIdle() {
        appState = .idle
        selectedTranscript = nil
        currentRecordingURL = nil
        cancellables.removeAll()
    }
    
    func cancelTranscription() {
        speechService.cancelTranscription()
        resetToIdle()
    }
    
    func dismissError() {
        showingError = false
        currentError = nil
        
        // Return to idle state after error
        if case .error(_, _) = appState {
            resetToIdle()
        }
    }
    
    private func handleError(_ error: Error) {
        let errorType: ErrorType
        let context: String?
        
        switch error {
        case let audioError as AudioRecordingError:
            switch audioError {
            case .permissionDenied:
                errorType = .microphonePermissionDenied
            case .engineSetupFailed, .engineStartFailed:
                errorType = .microphoneNotAvailable
            default:
                errorType = .unknown
            }
            context = audioError.localizedDescription
            
        case let speechError as SpeechRecognitionError:
            switch speechError {
            case .permissionDenied:
                errorType = .speechPermissionDenied
            case .recognizerUnavailable:
                errorType = .speechModelUnavailable
            case .recognitionFailed:
                errorType = .speechRecognitionFailed
            default:
                errorType = .unknown
            }
            context = speechError.localizedDescription
            
        case let fileError as FileServiceError:
            switch fileError {
            case .invalidSaveLocation, .writePermissionDenied:
                errorType = .writePermissionDenied
            case .insufficientDiskSpace:
                errorType = .diskFull
            default:
                errorType = .unknown
            }
            context = fileError.localizedDescription
            
        default:
            errorType = .unknown
            context = error.localizedDescription
        }
        
        appState = .error(errorType, context: context)
        currentError = (errorType, context)
        showingError = true
    }
    
    // MARK: - Computed Properties
    
    var isRecording: Bool {
        if case .recording = appState {
            return true
        }
        return false
    }
    
    var isTranscribing: Bool {
        if case .transcribing = appState {
            return true
        }
        return false
    }
    
    var canStartRecording: Bool {
        return appState == .idle
    }
    
    var recordingDuration: TimeInterval {
        if case .recording(_, let duration) = appState {
            return duration
        }
        return 0
    }
    
    var transcriptionProgress: Double {
        if case .transcribing(_, let progress) = appState {
            return progress
        }
        return 0
    }
    
    var currentTranscript: Transcript? {
        if case .ready(let transcript) = appState {
            return transcript
        }
        return selectedTranscript
    }
}