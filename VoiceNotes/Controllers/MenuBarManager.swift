import SwiftUI
import AppKit

class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    func setupMenuBar() {
        guard statusItem == nil else { return }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "mic.circle", accessibilityDescription: "VoiceNotes")
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        setupPopover()
    }
    
    func removeMenuBar() {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
        popover = nil
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: MenuBarContentView())
    }
    
    @objc private func statusItemClicked() {
        guard statusItem?.button != nil else { return }
        
        let event = NSApp.currentEvent
        
        if event?.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }
    
    private func togglePopover() {
        guard let button = statusItem?.button,
              let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    private func showContextMenu() {
        guard statusItem?.button != nil else { return }
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Open VoiceNotes", action: #selector(openMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Start Recording", action: #selector(startRecording), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit VoiceNotes", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        
        // Find and bring main window to front
        for window in NSApp.windows {
            if window.contentViewController is NSHostingController<ContentView> {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
    }
    
    @objc private func startRecording() {
        // Post notification to start recording
        NotificationCenter.default.post(name: .startRecordingFromMenuBar, object: nil)
        openMainWindow()
    }
    
    @objc private func openSettings() {
        // Post notification to open settings
        NotificationCenter.default.post(name: .openSettingsFromMenuBar, object: nil)
        openMainWindow()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    func updateIcon(for state: AppState) {
        guard let button = statusItem?.button else { return }
        
        let iconName: String
        switch state {
        case .idle:
            iconName = "mic.circle"
        case .recording:
            iconName = "mic.circle.fill"
        case .transcribing:
            iconName = "waveform.circle"
        case .ready:
            iconName = "checkmark.circle"
        case .error:
            iconName = "exclamationmark.circle"
        }
        
        button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "VoiceNotes")
    }
}

struct MenuBarContentView: View {
    @StateObject private var settings = Settings()
    @StateObject private var viewModel: MainViewModel
    
    init() {
        let settings = Settings()
        _viewModel = StateObject(wrappedValue: MainViewModel(settings: settings))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            headerView
            Divider()
            mainContentView
            Spacer()
            footerView
        }
        .frame(width: 300, height: 400)
        .onReceive(NotificationCenter.default.publisher(for: .startRecordingFromMenuBar)) { _ in
            startRecordingAction()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettingsFromMenuBar)) { _ in
            viewModel.showingSettings = true
        }
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: "mic.circle.fill")
                .foregroundColor(.blue)
                .font(.title2)
            
            Text("VoiceNotes")
                .font(.headline)
            
            Spacer()
            
            Button(action: {
                NSApp.activate(ignoringOtherApps: true)
            }) {
                Image(systemName: "arrow.up.right.square")
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var mainContentView: some View {
        VStack(spacing: 12) {
            recordingControlView
            recentTranscriptsView
        }
        .padding(.horizontal)
    }
    
    private var recordingControlView: some View {
        Group {
            if viewModel.canStartRecording {
                startRecordingButton
            } else if viewModel.isRecording {
                stopRecordingButton
            } else if viewModel.isTranscribing {
                transcribingView
            }
        }
    }
    
    private var startRecordingButton: some View {
        Button(action: startRecordingAction) {
            HStack {
                Image(systemName: "mic.fill")
                Text("Start Recording")
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
    
    private var stopRecordingButton: some View {
        Button(action: stopRecordingAction) {
            HStack {
                Image(systemName: "stop.fill")
                    .foregroundColor(.red)
                Text("Stop Recording")
                Spacer()
                Text(formatDuration(viewModel.recordingDuration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
    
    private var transcribingView: some View {
        VStack {
            HStack {
                Image(systemName: "waveform")
                Text("Transcribing...")
                Spacer()
            }
            
            ProgressView(value: viewModel.transcriptionProgress)
                .progressViewStyle(LinearProgressViewStyle())
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private var recentTranscriptsView: some View {
        if !viewModel.transcripts.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(Array(viewModel.transcripts.prefix(3))) { transcript in
                    transcriptRowView(transcript)
                }
            }
        }
    }
    
    private func transcriptRowView(_ transcript: Transcript) -> some View {
        Button(action: {
            viewModel.selectTranscript(transcript)
            NSApp.activate(ignoringOtherApps: true)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(transcript.text.prefix(40)) + (transcript.text.count > 40 ? "..." : ""))
                        .font(.caption)
                        .lineLimit(1)
                    
                    Text(transcript.formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(transcript.formattedDuration)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
    
    private var footerView: some View {
        HStack {
            Button("Settings") {
                viewModel.showingSettings = true
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            Spacer()
            
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private func startRecordingAction() {
        viewModel.startRecording()
    }
    
    private func stopRecordingAction() {
        viewModel.stopRecording()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension Notification.Name {
    static let startRecordingFromMenuBar = Notification.Name("startRecordingFromMenuBar")
    static let openSettingsFromMenuBar = Notification.Name("openSettingsFromMenuBar")
}