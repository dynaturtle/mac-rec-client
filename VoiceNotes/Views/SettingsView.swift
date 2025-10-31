import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedTab: SettingsTab? = .general
    
    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case recording = "Recording"
        case transcription = "Transcription"
        case shortcuts = "Shortcuts"
        case advanced = "Advanced"
        
        var icon: String {
            switch self {
            case .general: return "gear"
            case .recording: return "mic"
            case .transcription: return "text.bubble"
            case .shortcuts: return "keyboard"
            case .advanced: return "slider.horizontal.3"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            // Sidebar
            List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .frame(minWidth: 150, idealWidth: 180)
            
            // Detail view
            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsView(settings: settings)
                case .recording:
                    RecordingSettingsView(settings: settings)
                case .transcription:
                    TranscriptionSettingsView(settings: settings)
                case .shortcuts:
                    ShortcutsSettingsView(settings: settings)
                case .advanced:
                    AdvancedSettingsView(settings: settings)
                case .none:
                    Text("Select a settings category")
                        .foregroundColor(.secondary)
                }
            }
            .frame(minWidth: 400, minHeight: 300)
        }
        .frame(width: 600, height: 500)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var settings: Settings
    
    var body: some View {
        Form {
            Section(header: Text("Menu Bar")) {
                Toggle("Show menu bar icon", isOn: $settings.showMenuBarIcon)
                    .help("Display VoiceNotes icon in the menu bar for quick access")
                
                Toggle("Auto-start recording on launch", isOn: $settings.autoStartRecording)
                    .help("Automatically begin recording when the app launches")
            }
            
            Section(header: Text("Files & Storage")) {
                HStack {
                    Text("Save location:")
                    Spacer()
                    Button(URL(fileURLWithPath: settings.saveLocation).lastPathComponent) {
                        selectSaveLocation()
                    }
                    .buttonStyle(DefaultButtonStyle())
                }
                .help("Choose where to save your recordings and transcripts")
                
                Toggle("Auto-save transcripts", isOn: $settings.autoSaveTranscripts)
                    .help("Automatically save transcripts after transcription completes")
            }
            
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $settings.theme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .help("Choose the app's appearance theme")
            }
            
            Section(header: Text("Notifications")) {
                Toggle("Show notifications", isOn: $settings.showNotifications)
                    .help("Display system notifications for recording and transcription events")
            }
        }
        .navigationTitle("General")
    }
    
    private func selectSaveLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = settings.saveLocationURL
        
        if panel.runModal() == .OK, let url = panel.url {
            settings.setSaveLocation(url)
        }
    }
}

struct RecordingSettingsView: View {
    @ObservedObject var settings: Settings
    
    var body: some View {
        Form {
            Section(header: Text("Audio Format")) {
                Picker("Format", selection: $settings.audioFormat) {
                    ForEach(AudioFormat.allCases, id: \.self) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .help("Choose the audio file format for recordings")
                
                Picker("Quality", selection: $settings.audioQuality) {
                    ForEach(AudioQuality.allCases, id: \.self) { quality in
                        Text(quality.displayName).tag(quality)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .help("Select audio recording quality")
            }
            
            Section(header: Text("Recording Limits")) {
                HStack {
                    Text("Maximum duration:")
                    Spacer()
                    TextField("Minutes", value: $settings.maxRecordingDuration, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    Text("minutes")
                }
                .help("Set the maximum recording duration (0 for unlimited)")
            }
            
            Section(header: Text("Audio Input")) {
                // This would show available audio input devices
                Text("Input device selection would be implemented here")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Recording")
    }
}

struct TranscriptionSettingsView: View {
    @ObservedObject var settings: Settings
    
    var body: some View {
        Form {
            Section(header: Text("Language & Recognition")) {
                Picker("Language", selection: $settings.language) {
                    Text("Auto-detect").tag("auto")
                    Text("English").tag("en-US")
                    Text("Spanish").tag("es-ES")
                    Text("French").tag("fr-FR")
                    Text("German").tag("de-DE")
                    Text("Italian").tag("it-IT")
                    Text("Portuguese").tag("pt-BR")
                    Text("Chinese (Simplified)").tag("zh-CN")
                    Text("Japanese").tag("ja-JP")
                }
                .help("Select the primary language for speech recognition")
            }
            
            Section(header: Text("Quality & Confidence")) {
                HStack {
                    Text("Minimum confidence:")
                    Spacer()
                    Slider(value: $settings.transcriptionConfidence, in: 0.0...1.0, step: 0.1)
                    Text("\(Int(settings.transcriptionConfidence * 100))%")
                        .frame(width: 40)
                }
                .help("Set minimum confidence threshold for transcription results")
                
                Toggle("Show confidence indicators", isOn: $settings.showTranscriptionConfidence)
                    .help("Display confidence scores for transcribed text segments")
            }
            
            Section(header: Text("Processing")) {
                Toggle("Real-time transcription", isOn: .constant(true))
                    .disabled(true)
                    .help("Process speech in real-time during recording (always enabled)")
                
                Toggle("Auto-punctuation", isOn: .constant(true))
                    .disabled(true)
                    .help("Automatically add punctuation to transcripts (always enabled)")
            }
        }
        .navigationTitle("Transcription")
    }
}

struct ShortcutsSettingsView: View {
    @ObservedObject var settings: Settings
    
    var body: some View {
        Form {
            Section(header: Text("Global Shortcuts")) {
                HStack {
                    Text("Start/Stop Recording:")
                    Spacer()
                    KeyboardShortcutView(shortcut: $settings.recordingShortcut)
                }
                
                HStack {
                    Text("Open Settings:")
                    Spacer()
                    KeyboardShortcutView(shortcut: $settings.settingsShortcut)
                }
            }
            
            Section(header: Text("Menu Bar Shortcuts")) {
                Text("Left click: Open quick actions")
                    .foregroundColor(.secondary)
                Text("Right click: Show context menu")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Shortcuts")
    }
}

struct AdvancedSettingsView: View {
    @ObservedObject var settings: Settings
    
    var body: some View {
        Form {
            Section(header: Text("Performance")) {
                Toggle("Hardware acceleration", isOn: .constant(true))
                    .disabled(true)
                    .help("Use hardware acceleration for audio processing (always enabled)")
                
                Toggle("Background processing", isOn: .constant(true))
                    .disabled(true)
                    .help("Allow processing to continue in background (always enabled)")
            }
            
            Section(header: Text("Privacy")) {
                Toggle("Local processing only", isOn: .constant(true))
                    .disabled(true)
                    .help("All processing happens locally on your device (always enabled)")
                
                Button("Reset Privacy Permissions") {
                    resetPrivacyPermissions()
                }
                .help("Reset microphone and file access permissions")
            }
            
            Section(header: Text("Data Management")) {
                Button("Clear All Data") {
                    clearAllData()
                }
                .foregroundColor(.red)
                .help("Delete all recordings, transcripts, and app data")
                
                Button("Export Settings") {
                    exportSettings()
                }
                .help("Export current settings to a file")
                
                Button("Import Settings") {
                    importSettings()
                }
                .help("Import settings from a file")
            }
        }
        .navigationTitle("Advanced")
    }
    
    private func resetPrivacyPermissions() {
        // This would reset privacy permissions
        print("Reset privacy permissions")
    }
    
    private func clearAllData() {
        // This would clear all app data
        print("Clear all data")
    }
    
    private func exportSettings() {
        // This would export settings
        print("Export settings")
    }
    
    private func importSettings() {
        // This would import settings
        print("Import settings")
    }
}

struct KeyboardShortcutView: View {
    @Binding var shortcut: String
    @State private var isRecording = false
    
    var body: some View {
        Button(action: {
            isRecording.toggle()
        }) {
            Text(isRecording ? "Press keys..." : shortcut)
                .frame(minWidth: 100)
        }
        .buttonStyle(DefaultButtonStyle())
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray, lineWidth: 1)
        )
        .foregroundColor(isRecording ? .blue : .primary)
    }
}

// Preview removed for Swift 5.4 compatibility
// #Preview {
//     SettingsView(settings: Settings())
// }