import XCTest
@testable import VoiceNotes

final class VoiceNotesTests: XCTestCase {
    
    var settings: Settings!
    var viewModel: MainViewModel!
    
    override func setUpWithResult() throws {
        settings = Settings()
        viewModel = MainViewModel(settings: settings)
    }
    
    override func tearDownWithResult() throws {
        settings = nil
        viewModel = nil
    }
    
    // MARK: - Settings Tests
    
    func testSettingsInitialization() throws {
        XCTAssertTrue(settings.showMenuBarIcon)
        XCTAssertFalse(settings.autoStartRecording)
        XCTAssertEqual(settings.audioFormat, .m4a)
        XCTAssertEqual(settings.audioQuality, .high)
        XCTAssertEqual(settings.language, "auto")
        XCTAssertEqual(settings.transcriptionConfidence, 0.7, accuracy: 0.01)
        XCTAssertTrue(settings.autoSaveTranscripts)
        XCTAssertEqual(settings.maxRecordingDuration, 1800.0, accuracy: 0.01)
        XCTAssertTrue(settings.showNotifications)
        XCTAssertEqual(settings.theme, .system)
    }
    
    func testSettingsValidation() throws {
        // Test confidence bounds
        settings.transcriptionConfidence = -0.1
        XCTAssertEqual(settings.transcriptionConfidence, 0.0, accuracy: 0.01)
        
        settings.transcriptionConfidence = 1.1
        XCTAssertEqual(settings.transcriptionConfidence, 1.0, accuracy: 0.01)
        
        // Test max recording duration bounds
        settings.maxRecordingDuration = -10
        XCTAssertEqual(settings.maxRecordingDuration, 60.0, accuracy: 0.01) // Should default to minimum
        
        settings.maxRecordingDuration = 10000
        XCTAssertEqual(settings.maxRecordingDuration, 3600.0, accuracy: 0.01) // Should cap at maximum
    }
    
    // MARK: - Transcript Tests
    
    func testTranscriptInitialization() throws {
        let transcript = Transcript(
            text: "Hello, world!",
            audioURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            duration: 5.5,
            confidence: 0.95
        )
        
        XCTAssertEqual(transcript.text, "Hello, world!")
        XCTAssertEqual(transcript.duration, 5.5, accuracy: 0.01)
        XCTAssertEqual(transcript.confidence, 0.95, accuracy: 0.01)
        XCTAssertEqual(transcript.wordCount, 2)
        XCTAssertEqual(transcript.formattedDuration, "0:05")
    }
    
    func testTranscriptWordCount() throws {
        let transcript1 = Transcript(
            text: "This is a test transcript with multiple words.",
            audioURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            duration: 10.0
        )
        XCTAssertEqual(transcript1.wordCount, 8)
        
        let transcript2 = Transcript(
            text: "",
            audioURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            duration: 0.0
        )
        XCTAssertEqual(transcript2.wordCount, 0)
        
        let transcript3 = Transcript(
            text: "   Multiple   spaces   between   words   ",
            audioURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            duration: 5.0
        )
        XCTAssertEqual(transcript3.wordCount, 4)
    }
    
    func testTranscriptAverageWPM() throws {
        let transcript = Transcript(
            text: "This is a test transcript with exactly twelve words in total.",
            audioURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            duration: 60.0 // 1 minute
        )
        XCTAssertEqual(transcript.averageWPM, 12.0, accuracy: 0.01)
    }
    
    // MARK: - MainViewModel Tests
    
    func testMainViewModelInitialization() throws {
        XCTAssertEqual(viewModel.appState, .idle)
        XCTAssertTrue(viewModel.transcripts.isEmpty)
        XCTAssertNil(viewModel.selectedTranscript)
        XCTAssertNil(viewModel.currentError)
        XCTAssertFalse(viewModel.isRecording)
    }
    
    func testAppStateTransitions() throws {
        // Test state transitions
        viewModel.appState = .recording
        XCTAssertTrue(viewModel.isRecording)
        
        viewModel.appState = .transcribing
        XCTAssertFalse(viewModel.isRecording)
        
        viewModel.appState = .ready
        XCTAssertFalse(viewModel.isRecording)
        
        viewModel.appState = .idle
        XCTAssertFalse(viewModel.isRecording)
    }
    
    func testTranscriptManagement() throws {
        let transcript1 = Transcript(
            text: "First transcript",
            audioURL: URL(fileURLWithPath: "/tmp/test1.m4a"),
            duration: 10.0
        )
        
        let transcript2 = Transcript(
            text: "Second transcript",
            audioURL: URL(fileURLWithPath: "/tmp/test2.m4a"),
            duration: 15.0
        )
        
        // Test adding transcripts
        viewModel.transcripts = [transcript1, transcript2]
        XCTAssertEqual(viewModel.transcripts.count, 2)
        
        // Test selecting transcript
        viewModel.selectedTranscript = transcript1
        XCTAssertEqual(viewModel.selectedTranscript?.id, transcript1.id)
        
        // Test removing transcript
        viewModel.transcripts.removeAll { $0.id == transcript1.id }
        XCTAssertEqual(viewModel.transcripts.count, 1)
        XCTAssertEqual(viewModel.transcripts.first?.id, transcript2.id)
    }
    
    // MARK: - Extension Tests
    
    func testTimeIntervalFormatting() throws {
        XCTAssertEqual(TimeInterval(65).formattedDuration, "1:05")
        XCTAssertEqual(TimeInterval(3661).formattedDuration, "1:01:01")
        XCTAssertEqual(TimeInterval(30).formattedDuration, "0:30")
        XCTAssertEqual(TimeInterval(0).formattedDuration, "0:00")
    }
    
    func testStringWordCount() throws {
        XCTAssertEqual("Hello world".wordCount, 2)
        XCTAssertEqual("".wordCount, 0)
        XCTAssertEqual("   ".wordCount, 0)
        XCTAssertEqual("One".wordCount, 1)
        XCTAssertEqual("Multiple   spaces   between".wordCount, 3)
    }
    
    func testStringTruncation() throws {
        let longString = "This is a very long string that needs to be truncated"
        XCTAssertEqual(longString.truncated(to: 10), "This is a ...")
        XCTAssertEqual(longString.truncated(to: 100), longString)
        XCTAssertEqual("Short".truncated(to: 10), "Short")
    }
    
    // MARK: - Audio Format Tests
    
    func testAudioFormatProperties() throws {
        XCTAssertEqual(AudioFormat.m4a.fileExtension, "m4a")
        XCTAssertEqual(AudioFormat.wav.fileExtension, "wav")
        XCTAssertEqual(AudioFormat.mp3.fileExtension, "mp3")
        
        XCTAssertTrue(AudioFormat.m4a.isCompressed)
        XCTAssertFalse(AudioFormat.wav.isCompressed)
        XCTAssertTrue(AudioFormat.mp3.isCompressed)
    }
    
    func testAudioQualityBitRates() throws {
        XCTAssertEqual(AudioQuality.low.bitRate, 64000)
        XCTAssertEqual(AudioQuality.medium.bitRate, 128000)
        XCTAssertEqual(AudioQuality.high.bitRate, 256000)
        XCTAssertEqual(AudioQuality.lossless.bitRate, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorTypeLocalization() throws {
        let micError = ErrorType.microphonePermissionDenied
        XCTAssertFalse(micError.localizedDescription.isEmpty)
        
        let recordingError = ErrorType.recordingFailed("Test error")
        XCTAssertTrue(recordingError.localizedDescription.contains("Test error"))
        
        let transcriptionError = ErrorType.transcriptionFailed("Network timeout")
        XCTAssertTrue(transcriptionError.localizedDescription.contains("Network timeout"))
    }
    
    // MARK: - Performance Tests
    
    func testTranscriptListPerformance() throws {
        // Create a large number of transcripts
        var transcripts: [Transcript] = []
        for i in 0..<1000 {
            let transcript = Transcript(
                text: "Test transcript number \(i) with some content",
                audioURL: URL(fileURLWithPath: "/tmp/test\(i).m4a"),
                duration: Double(i % 100 + 10)
            )
            transcripts.append(transcript)
        }
        
        measure {
            // Test sorting performance
            let sorted = transcripts.sorted { $0.createdAt > $1.createdAt }
            XCTAssertEqual(sorted.count, 1000)
        }
    }
    
    func testWordCountPerformance() throws {
        let longText = String(repeating: "word ", count: 10000)
        
        measure {
            let count = longText.wordCount
            XCTAssertEqual(count, 10000)
        }
    }
    
    // MARK: - Integration Tests
    
    func testSettingsAndViewModelIntegration() throws {
        // Test that settings changes are reflected in view model
        settings.autoSaveTranscripts = false
        XCTAssertFalse(viewModel.settings.autoSaveTranscripts)
        
        settings.maxRecordingDuration = 600.0
        XCTAssertEqual(viewModel.settings.maxRecordingDuration, 600.0, accuracy: 0.01)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyTranscriptHandling() throws {
        let emptyTranscript = Transcript(
            text: "",
            audioURL: URL(fileURLWithPath: "/tmp/empty.m4a"),
            duration: 0.0
        )
        
        XCTAssertEqual(emptyTranscript.wordCount, 0)
        XCTAssertEqual(emptyTranscript.averageWPM, 0.0, accuracy: 0.01)
        XCTAssertEqual(emptyTranscript.formattedDuration, "0:00")
    }
    
    func testInvalidAudioURLHandling() throws {
        let transcript = Transcript(
            text: "Test transcript",
            audioURL: URL(fileURLWithPath: "/nonexistent/path.m4a"),
            duration: 10.0
        )
        
        // Should not crash with invalid URL
        XCTAssertNotNil(transcript.audioURL)
        XCTAssertEqual(transcript.text, "Test transcript")
    }
}