import Foundation
import AVFoundation
import Combine

class AudioRecordingService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevels: [Float] = []
    
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingTimer: Timer?
    private var startTime: Date?
    private var currentRecordingURL: URL?
    
    private let settings: Settings
    
    init(settings: Settings) {
        self.settings = settings
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        // On macOS, audio session setup is handled automatically by AVAudioEngine
        // No explicit setup needed like on iOS
    }
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    func startRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        guard !isRecording else {
            completion(.failure(AudioRecordingError.alreadyRecording))
            return
        }
        
        // Check microphone permission
        requestMicrophonePermission { [weak self] hasPermission in
            guard let self = self else { return }
            
            guard hasPermission else {
                completion(.failure(AudioRecordingError.permissionDenied))
                return
            }
            
            do {
                // Create recording URL
                let recordingURL = try self.createRecordingURL()
                self.currentRecordingURL = recordingURL
                
                // Setup audio engine
                self.audioEngine = AVAudioEngine()
                guard let audioEngine = self.audioEngine else {
                    completion(.failure(AudioRecordingError.engineSetupFailed))
                    return
                }
                
                let inputNode = audioEngine.inputNode
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                
                // Create audio file
                do {
                    self.audioFile = try AVAudioFile(forWriting: recordingURL, 
                                               settings: self.getAudioSettings(for: recordingFormat))
                } catch {
                    completion(.failure(AudioRecordingError.fileCreationFailed(error)))
                    return
                }
                
                guard let audioFile = self.audioFile else {
                    completion(.failure(AudioRecordingError.fileCreationFailed(NSError(domain: "AudioFile", code: -1))))
                    return
                }
                
                // Install tap on input node
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                    do {
                        try audioFile.write(from: buffer)
                        
                        // Update audio levels for visualization
                        DispatchQueue.main.async {
                            self?.updateAudioLevels(from: buffer)
                        }
                    } catch {
                        print("Error writing audio buffer: \(error)")
                    }
                }
                
                // Start audio engine
                do {
                    try audioEngine.start()
                } catch {
                    completion(.failure(AudioRecordingError.engineStartFailed(error)))
                    return
                }
                
                // Update state
                DispatchQueue.main.async {
                    self.isRecording = true
                    self.startTime = Date()
                    self.recordingDuration = 0
                    self.startRecordingTimer()
                }
                
                completion(.success(recordingURL))
                
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func stopRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        guard isRecording, let recordingURL = currentRecordingURL else {
            completion(.failure(AudioRecordingError.notRecording))
            return
        }
        
        // Stop audio engine
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        // Close audio file
        audioFile = nil
        
        // Update state
        DispatchQueue.main.async {
            self.isRecording = false
            self.stopRecordingTimer()
            self.audioLevels = []
        }
        
        // Clean up
        audioEngine = nil
        currentRecordingURL = nil
        
        completion(.success(recordingURL))
    }
    
    private func createRecordingURL() throws -> URL {
        let documentsPath = settings.saveLocationURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let timestamp = DateFormatter.fileNameFormatter.string(from: Date())
        let fileName = "VoiceNote_\(timestamp).\(settings.audioFormat.fileExtension)"
        return documentsPath.appendingPathComponent(fileName)
    }
    
    private func getAudioSettings(for format: AVAudioFormat) -> [String: Any] {
        var audioSettings: [String: Any] = [:]
        
        switch self.settings.audioFormat {
        case .m4a:
            audioSettings[AVFormatIDKey] = kAudioFormatMPEG4AAC
            audioSettings[AVEncoderBitRateKey] = self.settings.audioQuality.bitRate
        case .wav:
            audioSettings[AVFormatIDKey] = kAudioFormatLinearPCM
            audioSettings[AVLinearPCMBitDepthKey] = 16
            audioSettings[AVLinearPCMIsBigEndianKey] = false
            audioSettings[AVLinearPCMIsFloatKey] = false
        case .aiff:
            audioSettings[AVFormatIDKey] = kAudioFormatLinearPCM
            audioSettings[AVLinearPCMBitDepthKey] = 16
            audioSettings[AVLinearPCMIsBigEndianKey] = true
            audioSettings[AVLinearPCMIsFloatKey] = false
        }
        
        audioSettings[AVSampleRateKey] = format.sampleRate
        audioSettings[AVNumberOfChannelsKey] = format.channelCount
        
        return audioSettings
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            
            DispatchQueue.main.async {
                self.recordingDuration = Date().timeIntervalSince(startTime)
                
                // Check max recording duration
                if self.recordingDuration >= self.settings.maxRecordingDuration {
                    self.stopRecording { _ in
                        // Auto-stop recording when max duration is reached
                    }
                }
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func updateAudioLevels(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        
        // Calculate RMS (Root Mean Square) for audio level
        let squaredSamples = samples.map { $0 * $0 }
        let sum = squaredSamples.reduce(0, +)
        let mean = sum / Float(samples.count)
        let rms = sqrt(mean)
        let dbLevel = 20 * log10(rms)
        
        // Normalize to 0-1 range (assuming -60dB to 0dB range)
        let normalizedLevel = max(0, min(1, (dbLevel + 60) / 60))
        
        // Keep last 50 samples for visualization
        audioLevels.append(normalizedLevel)
        if audioLevels.count > 50 {
            audioLevels.removeFirst()
        }
    }
}

enum AudioRecordingError: LocalizedError {
    case alreadyRecording
    case notRecording
    case permissionDenied
    case engineSetupFailed
    case engineStartFailed(Error)
    case fileCreationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "Recording is already in progress"
        case .notRecording:
            return "No recording in progress"
        case .permissionDenied:
            return "Microphone permission denied"
        case .engineSetupFailed:
            return "Failed to setup audio engine"
        case .engineStartFailed(let error):
            return "Failed to start audio engine: \(error.localizedDescription)"
        case .fileCreationFailed(let error):
            return "Failed to create audio file: \(error.localizedDescription)"
        }
    }
}

extension DateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}