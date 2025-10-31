# Technical Design Document: VoiceNotes for Mac

## Goals for the design doc:

- Be specific enough that another engineer can start implementing.
- Call out key Apple frameworks and why (AVFoundation, Speech).
- Describe data flow: record → temp audio → transcription → UI → save.
- Identify edge cases and failure handling.
- Keep it scoped to the PRD; don't add features not in the PRD.

## Context / PRD (source of truth):

PRD — "VoiceNotes for Mac" (Local Only, Full Window)

Owner: YOU
Date: Oct 31, 2025
Version: 0.2

### 1. Purpose

Build a simple Mac app that lets users record speech and instantly see on-device transcription using Apple's Speech framework — no uploads, no cloud, privacy-first.

### 2. Problem

Mac users can record audio, but turning it into text is still multi-step. We want: open → record → stop → text in under 30 seconds, with everything staying on the Mac.

### 3. Goals & Success

- Start recording in ≤ 2 clicks.
- Transcription returned in ≤ 10 seconds for a 5-minute recording (on M-series, clear audio).
- 100% on-device; no network required after install.
- 80% of first-time users can do "record → copy text" without help.

### 4. User Stories

- As a writer, I open the app, hit "Record," talk an idea, stop, and copy the text.
- As a privacy-conscious user, I want confirmation my audio never leaves my Mac.
- As a student, I want to save the transcript as a text file from the same window.

### 5. Scope
#### In Scope (v1)

- Full window app (standard macOS window, resizable).
- Record audio using AVFoundation.
- Transcribe using Apple Speech framework (on-device, English).
- Show transcript in an editable text area.
- Actions: Copy, Save as .txt, Clear.
- Basic Settings inside the app (pane or modal): mic selection, language (if supported), auto-save last transcript.
- Optional menu bar icon that just opens the main window.

#### Out of Scope (v1)

- Cloud transcription.
- Multi-speaker labeling.
- Real-time/live captions.
- History / library of many past transcripts (we'll just keep the last one).

### 6. UX / UI
#### 6.1 Main Window Layout

- Top bar: App name, "New Recording" button, status (Idle / Recording / Transcribing…).
- Center (when idle): big "Record" primary button.
- While recording: timer, level meter, Stop button (red).
- After recording: transcript text view fills the lower 60% of window.

#### 6.2 Transcript Panel

- Editable text area.
- Footer actions: Copy to Clipboard, Save…, Clear
- Small info label: "Transcribed locally on this Mac."

#### 6.3 States

- Idle: "Click Record to start."
- Recording: red dot + timer (00:00:12) + input level.
- Transcribing…: spinner + text "Transcribing on device…"
- Error: "Couldn't transcribe. Check mic and try again." + "Try Again" button.

### 7. Functional Requirements
#### 7.1 Recording

- FR-1: App shall request microphone permission on first run.
- FR-2: App shall record from the selected input device.
- FR-3: App shall show live duration.
- FR-4: App should limit recording to 30 minutes (configurable constant) to avoid huge transcriptions.
- FR-5: App shall store temp audio file until transcription ends.

#### 7.2 Transcription (Apple Local)

- FR-6: App shall use Apple Speech framework in on-device mode where available.
- FR-7: If device/language doesn't support fully offline, app shall warn user and either fall back to "download speech assets", or display "Offline transcription not available for this language."
- FR-8: App shall support English (US) in v1.
- FR-9: App shall display the transcription in the main window automatically after completion.
- FR-10: App shall allow user to edit the transcription in place.

#### 7.3 Export / Save

- FR-11: "Copy" button copies the full transcript to clipboard.
- FR-12: "Save…" opens standard macOS save dialog; default format: .txt, default filename: VoiceNotes-YYYY-MM-DD-HHMM.txt.
- FR-13: App should auto-save the last transcript to app data folder and reload it on next launch.

#### 7.4 Settings

- FR-14: User can choose input device from available mics.
- FR-15: User can enable/disable auto-save of last transcript.
- FR-16: User can toggle "open app at login."
- FR-17: If Apple Speech offers multiple English variants, show dropdown.

#### 7.5 Windowing

- FR-18: App opens as a normal Mac window (not menubar-only).
- FR-19: Menu bar icon (optional) just brings window to front.
- FR-20: App remembers last window size/position.

### 8. Non-Functional Requirements
#### Performance

- Transcription for ≤5 min audio: ≤10 sec target.
- App launch: ≤2 sec to interactive.

#### Privacy/Security

- NFR-1: App shall not send audio or transcripts over the network.
- NFR-2: App shall state in "About/Privacy" that processing is on-device.
- NFR-3: All temp files stored under user Library (e.g. ~/Library/Containers/.../Data/) and cleaned when done.

#### Compatibility

- macOS 13+ (Ventura) and Apple Silicon first.
- Intel support is "nice-to-have".

### 9. Dependencies

- AVFoundation for capture.
- Speech framework for transcription.
- App sandboxing & mic entitlement.

### 10. Risks / Notes

- Some macOS setups require downloading on-device speech models — add onboarding note.
- Accuracy depends heavily on mic and noise; may need "speak clearly" tip.
- Long audio → longer transcription time; we cap at 30 minutes.

### 11. Future

- Real-time transcription view.
- Summaries ("TL;DR").
- History panel.
- Multiple languages.
- iCloud sync.

---

## Technical Design

### Overview

VoiceNotes for Mac is a privacy-first, local-only speech-to-text application built for macOS 13+ using Swift and SwiftUI. The app leverages AVFoundation for audio capture and Apple's Speech framework for on-device transcription, ensuring no audio data leaves the user's Mac. The application provides a simple workflow: record audio with one click, automatically transcribe using local speech recognition models, and export or copy the resulting text.

### Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   MainWindow    │◄──►│  MainViewModel   │◄──►│ RecordingController │
│   (SwiftUI)     │    │                  │    │  (AVFoundation)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                         │
                                ▼                         ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │TranscriptionService│    │   AudioFile     │
                       │  (Speech Framework)│    │  (Temp Storage) │
                       └──────────────────┘    └─────────────────┘
                                │                         │
                                ▼                         ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │ StorageManager   │◄──►│  SettingsStore  │
                       │                  │    │                 │
                       └──────────────────┘    └─────────────────┘
```

**Data Flow:**
1. **Idle → Recording**: User clicks Record → RecordingController starts AVAudioEngine → UI shows timer/level
2. **Recording → Transcribing**: User clicks Stop → Audio saved to temp file → TranscriptionService processes
3. **Transcribing → Ready**: Speech framework returns transcript → UI displays editable text → StorageManager auto-saves
4. **Ready → Export**: User clicks Copy/Save → StorageManager handles clipboard/file operations
5. **Error States**: Any failure → UI shows error message with retry option

### Key Components (Detailed)

#### RecordingController
- **Purpose**: Manages audio capture lifecycle using AVFoundation
- **Key APIs**: 
  - `AVAudioSession` for session configuration
  - `AVAudioEngine` with `AVAudioInputNode` for real-time capture
  - `AVAudioFile` for writing to temporary storage
- **Responsibilities**:
  - Request microphone permissions on first launch
  - Configure audio session for recording (category: `.record`)
  - Monitor input levels for UI feedback
  - Enforce 30-minute maximum recording duration
  - Generate temporary audio files in app container
  - Handle audio interruptions (calls, other apps)
- **Error Handling**: Mic unavailable, permission denied, disk full, audio session conflicts

#### TranscriptionService (Apple Local)
- **Purpose**: Converts audio files to text using Apple's Speech framework
- **Key APIs**:
  - `SFSpeechRecognizer` configured for on-device recognition
  - `SFSpeechURLRecognitionRequest` for file-based transcription
  - `SFSpeechRecognitionTask` for managing async operations
- **Responsibilities**:
  - Check availability of on-device speech models for selected locale
  - Process audio files asynchronously on background queue
  - Return transcription results with confidence scores
  - Handle speech recognition permissions
  - Provide progress updates during long transcriptions
- **Error Handling**: Model unavailable, unsupported language, corrupted audio, recognition timeout

#### StorageManager
- **Purpose**: Handles all file operations and persistence
- **Responsibilities**:
  - Auto-save last transcript to `~/Library/Containers/[AppID]/Data/Documents/last_transcript.txt`
  - Export transcripts via standard macOS save dialog
  - Clean up temporary audio files after transcription
  - Manage app settings persistence using `UserDefaults`
  - Handle file system errors gracefully
- **File Locations**:
  - Temp audio: `~/Library/Containers/[AppID]/Data/tmp/recording_[timestamp].m4a`
  - Auto-saved transcript: `~/Library/Containers/[AppID]/Data/Documents/last_transcript.txt`
  - Settings: `UserDefaults` standard domain

#### Settings / Config
- **Input Device Selection**: Enumerate available audio input devices via `AVCaptureDevice`
- **Auto-save Toggle**: Boolean preference for automatic transcript persistence
- **Login Item**: Integration with `SMLoginItemSetEnabled` for startup behavior
- **Language Selection**: Support for multiple English variants if available in Speech framework

#### UI Layer (SwiftUI)
- **MainWindow**: Primary interface with responsive layout
  - Top toolbar with app title and status indicator
  - Central recording controls (Record/Stop buttons, timer, level meter)
  - Transcript editor (TextEditor with custom styling)
  - Action buttons (Copy, Save, Clear) in bottom toolbar
- **Settings Sheet**: Modal presentation for configuration options
- **Menu Bar Integration**: Optional NSStatusItem that activates main window
- **State-Driven UI**: All interface elements respond to `AppState` changes

### Data Models

#### AppState (Enum)
```swift
enum AppState {
    case idle
    case recording(startTime: Date, duration: TimeInterval)
    case transcribing(audioURL: URL, progress: Double)
    case ready(transcript: Transcript)
    case error(ErrorType, context: String?)
}
```

#### Transcript (Struct)
```swift
struct Transcript {
    let text: String
    let createdAt: Date
    let duration: TimeInterval
    let confidence: Float?
    let sourceAudioURL: URL?
}
```

#### Settings (ObservableObject)
```swift
class Settings: ObservableObject {
    @Published var selectedInputDeviceID: String?
    @Published var autoSaveEnabled: Bool = true
    @Published var openAtLogin: Bool = false
    @Published var selectedLocale: Locale = Locale(identifier: "en-US")
}
```

### State Machine

**Valid Transitions:**
- `idle` → `recording`: User initiates recording
- `recording` → `transcribing`: User stops recording OR 30-minute limit reached
- `transcribing` → `ready`: Transcription completes successfully
- `transcribing` → `error`: Transcription fails
- `ready` → `idle`: User starts new recording OR clears transcript
- `error` → `idle`: User acknowledges error OR starts new recording
- Any state → `error`: Critical failure occurs

**Edge Cases:**
- **App quit during transcribing**: Resume transcription on next launch if temp audio exists
- **Transcription failure**: Preserve audio file and offer retry option
- **Permission revoked**: Gracefully handle mid-recording permission loss
- **Audio interruption**: Pause recording, resume when interruption ends

### Permissions & Privacy

#### Microphone Permission Flow
1. Check `AVCaptureDevice.authorizationStatus(for: .audio)`
2. If `.notDetermined`, request via `AVCaptureDevice.requestAccess(for: .audio)`
3. If `.denied`, show settings deep-link with explanation
4. Monitor permission changes via `AVCaptureDevice` notifications

#### Speech Recognition Permission Flow
1. Check `SFSpeechRecognizer.authorizationStatus()`
2. If `.notDetermined`, request via `SFSpeechRecognizer.requestAuthorization()`
3. Handle `.restricted` and `.denied` states with appropriate messaging
4. Verify on-device availability with `SFSpeechRecognizer.supportsOnDeviceRecognition`

#### Privacy Guarantees
- All audio processing occurs locally using Apple's on-device Speech framework
- No network requests for transcription services
- Temporary files stored in sandboxed app container
- Clear privacy statement in app UI: "All processing happens locally on your Mac"
- Audio files automatically deleted after successful transcription

### Error Handling

#### Microphone Errors
- **Not Available**: "No microphone detected. Please connect a microphone and try again."
- **Permission Denied**: "Microphone access required. Please enable in System Settings > Privacy & Security > Microphone."
- **In Use**: "Microphone is being used by another app. Please close other audio apps and try again."

#### Speech Recognition Errors
- **Model Unavailable**: "Speech recognition not available for selected language. Please check System Settings > General > Language & Region."
- **Recognition Failed**: "Could not transcribe audio. Please ensure clear speech and try again."
- **Timeout**: "Transcription taking longer than expected. The audio file has been saved for manual processing."

#### Storage Errors
- **Disk Full**: "Not enough storage space. Please free up disk space and try again."
- **Write Permission**: "Cannot save file to selected location. Please choose a different location or check permissions."
- **Corrupted Audio**: "Audio file appears corrupted. Please try recording again."

#### User Experience
- All errors display user-friendly messages with actionable next steps
- Technical details logged to system console for debugging
- Retry mechanisms for transient failures
- Graceful degradation when possible (e.g., disable auto-save if storage fails)

### Performance Considerations

#### Transcription Performance
- **Target**: ≤10 seconds for 5-minute audio on Apple Silicon
- **Optimization**: Use `SFSpeechURLRecognitionRequest` for better performance on longer audio
- **Background Processing**: Run transcription on dedicated background queue to maintain UI responsiveness
- **Memory Management**: Stream large audio files rather than loading entirely into memory

#### UI Responsiveness
- **Audio Level Monitoring**: Update level meter at 30fps using `AVAudioPCMBuffer` analysis
- **Progress Indication**: Show indeterminate progress during transcription with periodic updates
- **Async Operations**: All file I/O and transcription operations run off main queue
- **State Updates**: Use `@MainActor` for UI state changes from background operations

#### Resource Cleanup
- **Automatic Cleanup**: Delete temporary audio files immediately after successful transcription
- **App Termination**: Clean up resources in `applicationWillTerminate`
- **Memory Pressure**: Release audio engine resources when not recording
- **Storage Management**: Implement maximum cache size for auto-saved transcripts

### Testing Plan

#### Unit Tests
- **TranscriptionService**: Mock `SFSpeechRecognizer` to test various response scenarios
- **StorageManager**: Test file operations with temporary directories
- **RecordingController**: Mock `AVAudioEngine` for permission and recording state tests
- **Settings**: Verify UserDefaults persistence and validation logic

#### Integration Tests
- **End-to-End Flow**: Record → Transcribe → Save workflow with real audio files
- **Permission Handling**: Test permission request flows and state changes
- **Error Recovery**: Simulate various failure conditions and verify graceful handling
- **Settings Integration**: Verify settings changes affect recording and transcription behavior

#### UI Tests
- **Main Workflow**: Automated test of record → stop → transcribe → copy flow
- **State Transitions**: Verify UI updates correctly for each app state
- **Error States**: Test error message display and recovery actions
- **Settings Interface**: Validate settings sheet functionality and persistence

#### Manual Testing Scenarios
- **No Microphone**: Test behavior with no audio input devices
- **Revoked Permissions**: Test mid-session permission revocation
- **Offline Speech Models**: Test with and without downloaded speech recognition models
- **Audio Interruptions**: Test behavior during phone calls, other audio apps
- **Long Recordings**: Verify 30-minute limit enforcement and performance
- **Various Audio Quality**: Test with different microphones and noise levels

### Open Questions

#### Technical Decisions
1. **Speech Locale Support**: Start with en-US only, or support multiple English variants (en-GB, en-AU) if available?
2. **Minimum macOS Version**: Target macOS 13 (Ventura) for broader compatibility, or macOS 14 (Sonoma) for latest Speech framework features?
3. **Speech Model Downloads**: Block UI during initial model download, or allow background download with degraded functionality?
4. **Audio Format**: Use M4A for smaller files, or WAV for maximum compatibility with Speech framework?

#### User Experience
1. **Recording Limits**: Should 30-minute limit be user-configurable, or fixed for simplicity?
2. **Confidence Scores**: Display transcription confidence to users, or keep internal for quality assessment?
3. **Auto-Save Behavior**: Auto-save after every transcription, or only on user request?
4. **Menu Bar Presence**: Always show menu bar icon, or make it optional in settings?

#### Future Considerations
1. **Real-time Transcription**: Technical feasibility of live captions using `SFSpeechAudioBufferRecognitionRequest`
2. **Multiple Languages**: Framework support for seamless language switching
3. **iCloud Integration**: CloudKit integration for transcript sync across devices
4. **Accessibility**: VoiceOver support and keyboard navigation requirements