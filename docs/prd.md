PRD — “VoiceNotes for Mac” (Local Only, Full Window)

Owner: YOU
Date: Oct 31, 2025
Version: 0.2

1. Purpose

Build a simple Mac app that lets users record speech and instantly see on-device transcription using Apple’s Speech framework — no uploads, no cloud, privacy-first.

2. Problem

Mac users can record audio, but turning it into text is still multi-step. We want: open → record → stop → text in under 30 seconds, with everything staying on the Mac.

3. Goals & Success

Start recording in ≤ 2 clicks.

Transcription returned in ≤ 10 seconds for a 5-minute recording (on M-series, clear audio).

100% on-device; no network required after install.

80% of first-time users can do “record → copy text” without help.

4. User Stories

As a writer, I open the app, hit “Record,” talk an idea, stop, and copy the text.

As a privacy-conscious user, I want confirmation my audio never leaves my Mac.

As a student, I want to save the transcript as a text file from the same window.

5. Scope
In Scope (v1)

Full window app (standard macOS window, resizable).

Record audio using AVFoundation.

Transcribe using Apple Speech framework (on-device, English).

Show transcript in an editable text area.

Actions: Copy, Save as .txt, Clear.

Basic Settings inside the app (pane or modal): mic selection, language (if supported), auto-save last transcript.

Optional menu bar icon that just opens the main window.

Out of Scope (v1)

Cloud transcription.

Multi-speaker labeling.

Real-time/live captions.

History / library of many past transcripts (we’ll just keep the last one).

6. UX / UI
6.1 Main Window Layout

Top bar: App name, “New Recording” button, status (Idle / Recording / Transcribing…).

Center (when idle): big “Record” primary button.

While recording: timer, level meter, Stop button (red).

After recording: transcript text view fills the lower 60% of window.

6.2 Transcript Panel

Editable text area.

Footer actions:

Copy to Clipboard

Save…

Clear

Small info label: “Transcribed locally on this Mac.”

6.3 States

Idle: “Click Record to start.”

Recording: red dot + timer (00:00:12) + input level.

Transcribing…: spinner + text “Transcribing on device…”

Error: “Couldn’t transcribe. Check mic and try again.” + “Try Again” button.

7. Functional Requirements
7.1 Recording

FR-1: App shall request microphone permission on first run.

FR-2: App shall record from the selected input device.

FR-3: App shall show live duration.

FR-4: App should limit recording to 👉 30 minutes (configurable constant) to avoid huge transcriptions.

FR-5: App shall store temp audio file until transcription ends.

7.2 Transcription (Apple Local)

FR-6: App shall use Apple Speech framework in on-device mode where available.

FR-7: If device/language doesn’t support fully offline, app shall warn user and either:

fall back to “download speech assets”, or

display “Offline transcription not available for this language.”

FR-8: App shall support English (US) in v1.

FR-9: App shall display the transcription in the main window automatically after completion.

FR-10: App shall allow user to edit the transcription in place.

7.3 Export / Save

FR-11: “Copy” button copies the full transcript to clipboard.

FR-12: “Save…” opens standard macOS save dialog; default format: .txt, default filename: VoiceNotes-YYYY-MM-DD-HHMM.txt.

FR-13: App should auto-save the last transcript to app data folder and reload it on next launch.

7.4 Settings

FR-14: User can choose input device from available mics.

FR-15: User can enable/disable auto-save of last transcript.

FR-16: User can toggle “open app at login.”

FR-17: If Apple Speech offers multiple English variants, show dropdown.

7.5 Windowing

FR-18: App opens as a normal Mac window (not menubar-only).

FR-19: Menu bar icon (optional) just brings window to front.

FR-20: App remembers last window size/position.

8. Non-Functional Requirements
Performance

Transcription for ≤5 min audio: ≤10 sec target.

App launch: ≤2 sec to interactive.

Privacy/Security

NFR-1: App shall not send audio or transcripts over the network.

NFR-2: App shall state in “About/Privacy” that processing is on-device.

NFR-3: All temp files stored under user Library (e.g. ~/Library/Containers/.../Data/) and cleaned when done.

Compatibility

macOS 13+ (Ventura) and Apple Silicon first.

Intel support is “nice-to-have”.

9. Dependencies

AVFoundation for capture.

Speech framework for transcription.

App sandboxing & mic entitlement.

10. Risks / Notes

Some macOS setups require downloading on-device speech models — add onboarding note.

Accuracy depends heavily on mic and noise; may need “speak clearly” tip.

Long audio → longer transcription time; we cap at 30 minutes.

11. Future

Real-time transcription view.

Summaries (“TL;DR”).

History panel.

Multiple languages.

iCloud sync.