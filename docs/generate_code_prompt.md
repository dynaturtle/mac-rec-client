You are an expert macOS engineer (Swift/SwiftUI, macOS 13+). Your job is to turn the technical design document below into working code.

Goal: produce a minimal but complete Xcode project structure (files + Swift code) that implements the features described in the design. Prioritize correctness, clarity, and matching the design. Avoid features not in the design.

Source of truth

Technical Design Doc:

[PASTE YOUR TECH DESIGN DOC HERE]

Requirements

Platform & Stack

Language: Swift 5+

UI: SwiftUI

Target: macOS 13+

Local-only transcription using Apple Speech framework

Recording using AVFoundation

No networking, no 3rd-party deps

Architecture

MVVM

Separate layers:

Recording layer (AVFoundation)

Transcription layer (Speech)

Storage layer (autosave / export)

UI (SwiftUI views)

ViewModel (app state + actions)

Implement the state machine described in the design (idle → recording → transcribing → ready | error)

Features to implement

Start/stop recording

Transcribe recorded audio on-device

Show transcript in editable text area

Copy to clipboard

Save transcript to file

Basic settings (even if minimal / stubbed)

Handle errors (mic, speech permission, transcription failure)

What to output

1. Project structure (text)
List the files/folders you will create, for example:

VoiceNotesApp.swift (entry point)

Models/AppState.swift

Recording/RecordingController.swift

Transcription/TranscriptionService.swift

Storage/StorageManager.swift

ViewModels/MainViewModel.swift

Views/ContentView.swift

Views/SettingsView.swift

Utilities/Extensions.swift (if needed)

2. Code files (full content) — in this order

VoiceNotesApp.swift — @main app, create MainViewModel, inject into root view.

AppState.swift — enums/models for app state, transcript model, settings model.

RecordingController.swift — AVFoundation-based recorder to temp file, mic permission, 30-min cap.

TranscriptionService.swift — Speech framework (SFSpeechRecognizer, SFSpeechURLRecognitionRequest), request permission, return String or throw.

StorageManager.swift — autosave last transcript, save to .txt, app-support directory.

MainViewModel.swift — ObservableObject that wires everything together:

startRecording()

stopRecording()

transcribe(url:)

copyTranscript()

saveTranscript()

publishes @Published var appState, @Published var transcript, @Published var errorMessage

ContentView.swift — SwiftUI UI showing:

Idle: big Record button

Recording: timer + Stop button

Transcribing: progress

Ready: TextEditor + buttons (Copy, Save…, Clear)

Show error banner if errorMessage is set

SettingsView.swift — simple view to change input device (placeholder), toggle autosave, and show “processing on device”.

3. Notes / TODOs
At the end, add TODOs for areas that depend on runtime conditions (e.g. listing real input devices).

Coding style guidelines

Use clear, idiomatic Swift; no unnecessary abstraction.

Add short comments for platform-specific parts (permissions, container dirs).

Make async parts async/await where reasonable (transcription).

Keep file paths safe (use FileManager.default.urls(for: .applicationSupportDirectory, ...)).

Important behaviors to implement

On first record: request microphone permission.

On first transcription: request speech recognition permission.

If speech cannot run offline for selected locale: return user-facing error message.

After transcription succeeds: update transcript, set state to .ready.

Always clean up temp audio after use (or note TODO if skipping).