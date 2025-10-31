import Foundation
import Speech
import AVFoundation
import Combine

class SpeechRecognitionService: ObservableObject {
    @Published var transcriptionProgress: Double = 0.0
    @Published var isTranscribing = false
    
    private let settings: Settings
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    
    init(settings: Settings) {
        self.settings = settings
        setupRecognizer()
    }
    
    private func setupRecognizer() {
        let locale = Locale(identifier: settings.language)
        recognizer = SFSpeechRecognizer(locale: locale)
        
        guard recognizer?.isAvailable == true else {
            print("Speech recognizer not available for locale: \(settings.language)")
            return
        }
    }
    
    func requestSpeechRecognitionPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            completion(status == .authorized)
        }
    }
    
    func transcribeAudio(from url: URL, completion: @escaping (Result<Transcript, Error>) -> Void) {
        guard !isTranscribing else {
            completion(.failure(SpeechRecognitionError.alreadyTranscribing))
            return
        }
        
        // Check permission
        requestSpeechRecognitionPermission { [weak self] hasPermission in
            guard let self = self else { return }
            
            guard hasPermission else {
                completion(.failure(SpeechRecognitionError.permissionDenied))
                return
            }
            
            // Setup recognizer for current language
            self.setupRecognizer()
            
            guard let recognizer = self.recognizer, recognizer.isAvailable else {
                completion(.failure(SpeechRecognitionError.recognizerUnavailable))
                return
            }
            
            // Get audio file duration
            do {
                let audioFile = try AVAudioFile(forReading: url)
                let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
                
                DispatchQueue.main.async {
                    self.isTranscribing = true
                    self.transcriptionProgress = 0.0
                }
                
                let request = SFSpeechURLRecognitionRequest(url: url)
                request.shouldReportPartialResults = true
                request.requiresOnDeviceRecognition = false // Use cloud recognition for better accuracy
                
                var finalTranscript: Transcript?
                var segments: [TranscriptSegment] = []
            
                self.recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        DispatchQueue.main.async {
                            self.isTranscribing = false
                            self.transcriptionProgress = 0.0
                        }
                        completion(.failure(SpeechRecognitionError.recognitionFailed(error)))
                        return
                    }
                    
                    guard let result = result else { return }
                    
                    // Update progress based on how much audio has been processed
                    let progress = min(1.0, result.bestTranscription.segments.last?.timestamp ?? 0.0 / duration)
                    DispatchQueue.main.async {
                        self.transcriptionProgress = progress
                    }
                    
                    if result.isFinal {
                        // Create transcript segments
                        segments = result.bestTranscription.segments.map { segment in
                            TranscriptSegment(
                                text: segment.substring,
                                startTime: segment.timestamp,
                                endTime: segment.timestamp + segment.duration,
                                confidence: Double(segment.confidence)
                            )
                        }
                        
                        // Calculate overall confidence
                        let overallConfidence = segments.isEmpty ? 0.0 : 
                            segments.map { $0.confidence }.reduce(0, +) / Double(segments.count)
                        
                        finalTranscript = Transcript(
                            text: result.bestTranscription.formattedString,
                            audioURL: url,
                            duration: duration,
                            language: self.settings.language,
                            confidence: overallConfidence,
                            segments: segments
                        )
                        
                        DispatchQueue.main.async {
                            self.isTranscribing = false
                            self.transcriptionProgress = 1.0
                        }
                        
                        if let transcript = finalTranscript {
                            completion(.success(transcript))
                        }
                    }
                }
                
            } catch {
                completion(.failure(SpeechRecognitionError.audioFileError))
            }
        }
    }
    
    // Note: transcribeAudioLive requires Swift 5.5+ for AsyncThrowingStream
    // Commented out for compatibility with Swift 5.4
    /*
    func transcribeAudioLive(from audioEngine: AVAudioEngine) async throws -> AsyncThrowingStream<String, Error> {
        guard !isTranscribing else {
            throw SpeechRecognitionError.alreadyTranscribing
        }
        
        // Check permission
        let hasPermission = await requestSpeechRecognitionPermission()
        guard hasPermission else {
            throw SpeechRecognitionError.permissionDenied
        }
        
        setupRecognizer()
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerUnavailable
        }
        
        return AsyncThrowingStream { continuation in
            DispatchQueue.main.async {
                self.isTranscribing = true
            }
            
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = false
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }
            
            recognitionTask = recognizer.recognize(request) { [weak self] result, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.isTranscribing = false
                    }
                    continuation.finish(throwing: SpeechRecognitionError.recognitionFailed(error))
                    return
                }
                
                guard let result = result else { return }
                
                continuation.yield(result.bestTranscription.formattedString)
                
                if result.isFinal {
                    DispatchQueue.main.async {
                        self?.isTranscribing = false
                    }
                    continuation.finish()
                }
            }
            
            continuation.onTermination = { [weak self] _ in
                self?.recognitionTask?.cancel()
                self?.recognitionTask = nil
                inputNode.removeTap(onBus: 0)
                DispatchQueue.main.async {
                    self?.isTranscribing = false
                }
            }
        }
    }
    */
    
    func cancelTranscription() {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        DispatchQueue.main.async {
            self.isTranscribing = false
            self.transcriptionProgress = 0.0
        }
    }
    
    func isLanguageSupported(_ languageCode: String) -> Bool {
        let locale = Locale(identifier: languageCode)
        return SFSpeechRecognizer(locale: locale)?.isAvailable == true
    }
    
    func getSupportedLanguages() -> [String] {
        return settings.availableLanguages.filter { isLanguageSupported($0) }
    }
}

enum SpeechRecognitionError: LocalizedError {
    case alreadyTranscribing
    case permissionDenied
    case recognizerUnavailable
    case recognitionFailed(Error)
    case audioFileError
    
    var errorDescription: String? {
        switch self {
        case .alreadyTranscribing:
            return "Transcription already in progress"
        case .permissionDenied:
            return "Speech recognition permission denied"
        case .recognizerUnavailable:
            return "Speech recognizer not available for selected language"
        case .recognitionFailed(let error):
            return "Speech recognition failed: \(error.localizedDescription)"
        case .audioFileError:
            return "Could not read audio file"
        }
    }
}