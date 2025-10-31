import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: Settings
    @StateObject private var viewModel: MainViewModel
    
    init() {
        let settings = Settings()
        _viewModel = StateObject(wrappedValue: MainViewModel(settings: settings))
    }
    
    var body: some View {
        NavigationView {
            // Sidebar with transcript list
            TranscriptListView(viewModel: viewModel, settings: settings)
                .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
            
            // Main content area
            MainContentView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            SettingsView(settings: settings)
        }
        .alert(isPresented: $viewModel.showingError) {
            Alert(
                title: Text("Error"),
                message: {
                    if let (errorType, context) = viewModel.currentError {
                        return Text(context ?? errorType.localizedDescription)
                    } else {
                        return Text("An error occurred")
                    }
                }(),
                primaryButton: .default(Text("OK")) {
                    viewModel.dismissError()
                },
                secondaryButton: {
                    if case .error(let errorType, _) = viewModel.appState,
                       errorType == .microphonePermissionDenied || errorType == .speechPermissionDenied {
                        return .default(Text("Open Settings")) {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
                            viewModel.dismissError()
                        }
                    } else {
                        return .cancel()
                    }
                }()
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .startRecordingFromMenuBar)) { _ in
            viewModel.startRecording()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettingsFromMenuBar)) { _ in
            viewModel.showingSettings = true
        }
        .environmentObject(viewModel)
    }
}

struct MainContentView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        VStack {
            switch viewModel.appState {
            case .idle:
                IdleView(viewModel: viewModel)
                
            case .recording(let startTime, let duration):
                RecordingView(startTime: startTime, duration: duration, viewModel: viewModel)
                
            case .transcribing(let audioURL, let progress):
                TranscribingView(audioURL: audioURL, progress: progress, viewModel: viewModel)
                
            case .ready(let transcript):
                TranscriptView(transcript: transcript, viewModel: viewModel)
                
            case .error(let errorType, let context):
                ErrorView(errorType: errorType, context: context, viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct IdleView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "mic.circle")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Ready to Record")
                    .font(.title)
                    .fontWeight(.medium)
                
                Text("Click the record button or press ⌘R to start recording")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                viewModel.startRecording()
            }) {
                HStack {
                    Image(systemName: "mic.fill")
                    Text("Start Recording")
                }
                .font(.title3)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
            .buttonStyle(DefaultButtonStyle())
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .keyboardShortcut("r", modifiers: .command)
            
            Spacer()
            
            if !viewModel.transcripts.isEmpty {
                VStack(spacing: 8) {
                    Text("Recent Transcripts")
                        .font(.headline)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(Array(viewModel.transcripts.prefix(6))) { transcript in
                            TranscriptCard(transcript: transcript) {
                                viewModel.selectTranscript(transcript)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct TranscriptCard: View {
    let transcript: Transcript
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text(transcript.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(String(transcript.text.prefix(60)) + (transcript.text.count > 60 ? "..." : ""))
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(transcript.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .frame(height: 80)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ErrorView: View {
    let errorType: ErrorType
    let context: String?
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("Error")
                    .font(.title)
                    .fontWeight(.medium)
                
                Text(context ?? errorType.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Try Again") {
                viewModel.dismissError()
            }
            .buttonStyle(DefaultButtonStyle())
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            
            Spacer()
        }
        .padding()
    }
}

// Preview removed for Swift 5.4 compatibility
// #Preview {
//     ContentView()
//         .environmentObject(Settings())
// }