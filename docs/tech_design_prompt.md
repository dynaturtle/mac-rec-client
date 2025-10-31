Goals for the design doc:

Be specific enough that another engineer can start implementing.

Call out key Apple frameworks and why (AVFoundation, Speech).

Describe data flow: record → temp audio → transcription → UI → save.

Identify edge cases and failure handling.

Keep it scoped to the PRD; don’t add features not in the PRD.

Context / PRD (source of truth):

[PASTE THE PRD BELOW — “VoiceNotes for Mac” (Local Only, Full Window)]

What to output:

Overview

One short paragraph restating the product in technical terms.

Mention: macOS 13+, Swift/SwiftUI (or AppKit if more appropriate), local-only transcription.

Architecture

High-level diagram (textual) of main components, e.g.:

RecordingController

TranscriptionService (using Apple Speech)

StorageManager (autosave, export)

MainViewModel / MainWindow

Show main data flow and state transitions: Idle → Recording → Transcribing → Ready/Error.

Key Components (detailed)

RecordingController

Uses AVAudioSession / AVAudioEngine / AVFoundation to capture mic.

Handles mic permission (first-run).

Emits audio file to a temp location.

Enforces max duration (30 min).

TranscriptionService (Apple local)

Uses Speech framework (SFSpeechRecognizer, SFSpeechURLRecognitionRequest).

Runs offline if model available; report if not.

Returns transcript + confidence (if available).

Error model (network unavailable, permissions, model unavailable).

StorageManager

Autosave last transcript to app container.

save(to url: URL) for user-triggered export as .txt.

Cleanup of temp audio.

Settings / Config

Selected input device.

Auto-save toggle.

Open at login.

UI Layer

SwiftUI main window: shows current state, transcript text editor, buttons (Record, Stop, Copy, Save).

Optional menu bar item that brings window to front.

Data Models

AppState (enum): .idle, .recording(startDate, duration), .transcribing(audioURL), .ready(transcript), .error(errorType)

Transcript model: text, createdAt, duration, sourceAudioURL?

Settings model: inputDeviceID, autoSave: Bool, openAtLogin: Bool.

State Machine

Define valid transitions, e.g.:

idle → recording

recording → transcribing

transcribing → ready | error

ready → idle

Define what happens if user quits during transcribing.

Define what happens if transcription fails (fallback to keeping audio + error message).

Permissions & Privacy

Microphone permission flow.

Speech recognition permission flow.

State clearly: no audio leaves device.

File locations in ~/Library/Containers/.../Data/.

Error Handling

Mic not available.

Speech recognizer not available for chosen language / offline.

Recording too long / file too big.

Disk write failure on save.

Show user-friendly message + log technical error.

Performance Considerations

Target: ≤10s transcription for ≤5min audio on M-series.

Run transcription on background queue.

Keep UI responsive.

Clean up temp files after success.

Testing Plan

Unit tests for TranscriptionService (mock Speech).

Unit tests for StorageManager.

UI tests for main flow: record → stop → transcribe → copy.

Manual tests: no mic, revoked permission, offline model not present.

Open Questions

Which speech locale(s) to pre-enable?

Minimum macOS (13 vs 14)?

Do we block UI while downloading on-device speech assets?

Important style rules:

Write in clear, engineering-facing language.

Use headings and bullet lists.

Prefer Swift/SwiftUI terminology.

Don’t include code unless it clarifies a tricky point.