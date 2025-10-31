import SwiftUI
import UniformTypeIdentifiers
// UniformTypeIdentifiers not available in macOS 10.15, using string constants instead

struct TranscriptView: View {
    let transcript: Transcript
    @ObservedObject var viewModel: MainViewModel
    
    @State private var editedText: String = ""
    @State private var isEditing = false
    @State private var showingExportDialog = false
    @State private var selectedExportFormat: ExportFormat = .text
    @State private var showingShareSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with actions
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transcript")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 16) {
                        Label(transcript.formattedDate, systemImage: "calendar")
                        Label(transcript.formattedDuration, systemImage: "clock")
                        Label("\(transcript.wordCount) words", systemImage: "textformat")
                        
                        if viewModel.settings.showTranscriptionConfidence {
                            Label("\(Int(transcript.confidence * 100))%", systemImage: "checkmark.circle")
                                .foregroundColor(confidenceColor)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Play audio button
                    Button(action: playAudio) {
                        Image(systemName: "play.circle")
                            .font(.title2)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Play audio")
                    
                    // Edit button
                    Button(action: toggleEdit) {
                        Image(systemName: isEditing ? "checkmark.circle" : "pencil.circle")
                            .font(.title2)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help(isEditing ? "Save changes" : "Edit transcript")
                    
                    // Export button
                    Button(action: { showingExportDialog = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Export transcript")
                    
                    // Share button
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up.on.square")
                            .font(.title2)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Share transcript")
                    
                    // New recording button
                    Button(action: {
                        viewModel.startRecording()
                    }) {
                        Image(systemName: "mic.circle")
                            .font(.title2)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Start new recording")
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Transcript content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isEditing {
                        TextEditor(text: $editedText)
                            .font(.body)
                            .padding()
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    } else {
                        Text(editedText.isEmpty ? transcript.text : editedText)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: CGFloat.infinity, alignment: .leading)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                    }
                    
                    // Segments view (if available)
                    if !transcript.segments.isEmpty && viewModel.settings.showTranscriptionConfidence {
                        SegmentsView(segments: transcript.segments)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            editedText = transcript.text
        }
        .fileExporter(
            isPresented: $showingExportDialog,
            document: TranscriptDocument(transcript: transcript, format: selectedExportFormat),
            contentType: selectedExportFormat.contentType,
            defaultFilename: defaultFilename
        ) { result in
            switch result {
            case .success(let url):
                print("Exported to: \(url)")
            case .failure(let error):
                print("Export failed: \(error)")
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [transcript.text])
        }
    }
    
    private var confidenceColor: Color {
        if transcript.confidence >= 0.8 {
            return .green
        } else if transcript.confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var defaultFilename: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let dateString = dateFormatter.string(from: transcript.createdAt)
        return "VoiceNote_\(dateString).\(selectedExportFormat.fileExtension)"
    }
    
    private func toggleEdit() {
        if isEditing {
            // Save changes
            let updatedTranscript = Transcript(
                id: transcript.id,
                text: editedText,
                audioURL: transcript.audioURL,
                createdAt: transcript.createdAt,
                duration: transcript.duration,
                language: transcript.language,
                confidence: transcript.confidence,
                segments: transcript.segments
            )
            viewModel.saveTranscript(updatedTranscript)
        }
        isEditing.toggle()
    }
    
    private func playAudio() {
        // This would integrate with an audio player
        NSWorkspace.shared.open(transcript.audioURL)
    }
}

struct SegmentsView: View {
    let segments: [TranscriptSegment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transcript Segments")
                .font(.headline)
                .padding(.bottom, 4)
            
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(segments) { segment in
                    HStack(alignment: .top, spacing: 12) {
                        Text(segment.formattedTimeRange)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        
                        Text(segment.text)
                            .font(.body)
                        
                        Spacer()
                        
                        // Confidence indicator
                        Circle()
                            .fill(confidenceColor(for: segment.confidence))
                            .frame(width: 8, height: 8)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func confidenceColor(for confidence: Double) -> Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

struct TranscriptDocument: FileDocument {
    static var readableContentTypes: [UTType] = [UTType.plainText, UTType.json]
    
    let transcript: Transcript
    let format: ExportFormat
    
    init(transcript: Transcript, format: ExportFormat) {
        self.transcript = transcript
        self.format = format
    }
    
    init(configuration: ReadConfiguration) throws {
        // This would be used for reading documents, not needed for export-only
        fatalError("Reading not supported")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let content: String
        
        switch format {
        case .text:
            content = generateTextContent()
        case .markdown:
            content = generateMarkdownContent()
        case .json:
            content = generateJSONContent()
        }
        
        return FileWrapper(regularFileWithContents: content.data(using: .utf8)!)
    }
    
    private func generateTextContent() -> String {
        var content = "VoiceNotes Transcript\n"
        content += "=====================\n\n"
        content += "Date: \(transcript.formattedDate)\n"
        content += "Duration: \(transcript.formattedDuration)\n"
        content += "Language: \(transcript.language)\n"
        content += "Word Count: \(transcript.wordCount)\n"
        content += "Confidence: \(String(format: "%.1f%%", transcript.confidence * 100))\n"
        content += "\n--- Transcript ---\n\n"
        content += transcript.text
        
        if !transcript.segments.isEmpty {
            content += "\n\n--- Segments ---\n\n"
            for segment in transcript.segments {
                content += "[\(segment.formattedTimeRange)] \(segment.text)\n"
            }
        }
        
        return content
    }
    
    private func generateMarkdownContent() -> String {
        var content = "# VoiceNotes Transcript\n\n"
        content += "**Date:** \(transcript.formattedDate)  \n"
        content += "**Duration:** \(transcript.formattedDuration)  \n"
        content += "**Language:** \(transcript.language)  \n"
        content += "**Word Count:** \(transcript.wordCount)  \n"
        content += "**Confidence:** \(String(format: "%.1f%%", transcript.confidence * 100))  \n"
        content += "\n## Transcript\n\n"
        content += transcript.text
        
        if !transcript.segments.isEmpty {
            content += "\n\n## Segments\n\n"
            for segment in transcript.segments {
                content += "**\(segment.formattedTimeRange):** \(segment.text)\n\n"
            }
        }
        
        return content
    }
    
    private func generateJSONContent() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(transcript)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Error encoding transcript: \(error)"
        }
    }
}

struct ShareSheet: NSViewRepresentable {
    let items: [Any]
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        DispatchQueue.main.async {
            let picker = NSSharingServicePicker(items: items)
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension ExportFormat {
    var contentType: UTType {
        switch self {
        case .text:
            return UTType.plainText
        case .markdown:
            return UTType(filenameExtension: "md") ?? UTType.plainText
        case .json:
            return UTType.json
        }
    }
}

// Preview removed for Swift 5.4 compatibility
// #Preview {
//     TranscriptView(
//         transcript: Transcript(
//             text: "This is a sample transcript that demonstrates how the transcript view looks with some content. It includes multiple sentences to show the text wrapping and formatting.",
//             audioURL: URL(fileURLWithPath: "/tmp/test.m4a"),
//             duration: 125.5,
//             confidence: 0.85,
//             segments: [
//                 TranscriptSegment(text: "This is a sample transcript", startTime: 0, endTime: 2.5, confidence: 0.9),
//                 TranscriptSegment(text: "that demonstrates how the transcript view looks", startTime: 2.5, endTime: 5.0, confidence: 0.8)
//             ]
//         ),
//         viewModel: MainViewModel(settings: Settings())
//     )
// }