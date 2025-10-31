import SwiftUI

struct TranscriptListView: View {
    @ObservedObject var viewModel: MainViewModel
    @ObservedObject var settings: Settings
    
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .dateDescending
    @State private var showingDeleteAlert = false
    @State private var transcriptToDelete: Transcript?
    
    enum SortOrder: String, CaseIterable {
        case dateDescending = "Date (Newest)"
        case dateAscending = "Date (Oldest)"
        case durationDescending = "Duration (Longest)"
        case durationAscending = "Duration (Shortest)"
        case alphabetical = "Alphabetical"
        
        var systemImage: String {
            switch self {
            case .dateDescending: return "calendar.badge.minus"
            case .dateAscending: return "calendar.badge.plus"
            case .durationDescending: return "clock.badge.minus"
            case .durationAscending: return "clock.badge.plus"
            case .alphabetical: return "textformat.abc"
            }
        }
    }
    
    var filteredAndSortedTranscripts: [Transcript] {
        let filtered = searchText.isEmpty ? viewModel.transcripts : viewModel.transcripts.filter { transcript in
            transcript.text.localizedCaseInsensitiveContains(searchText) ||
            transcript.formattedDate.localizedCaseInsensitiveContains(searchText)
        }
        
        return filtered.sorted { first, second in
            switch sortOrder {
            case .dateDescending:
                return first.createdAt > second.createdAt
            case .dateAscending:
                return first.createdAt < second.createdAt
            case .durationDescending:
                return first.duration > second.duration
            case .durationAscending:
                return first.duration < second.duration
            case .alphabetical:
                return first.text.localizedCaseInsensitiveCompare(second.text) == .orderedAscending
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search and controls
            VStack(spacing: 8) {
                HStack {
                    Text("Transcripts")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(viewModel.transcripts.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                }
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search transcripts...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Sort controls
                HStack {
                    Menu {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Button(action: { sortOrder = order }) {
                                Label(order.rawValue, systemImage: order.systemImage)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: sortOrder.systemImage)
                            Text("Sort")
                            Image(systemName: "chevron.down")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .menuStyle(BorderlessButtonMenuStyle())
                    
                    Spacer()
                    
                    // New recording button
                    Button(action: {
                        viewModel.startRecording()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Start new recording")
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Transcript list
            if filteredAndSortedTranscripts.isEmpty {
                EmptyStateView(hasTranscripts: !viewModel.transcripts.isEmpty, searchText: searchText)
            } else {
                List(filteredAndSortedTranscripts, id: \.id, selection: $viewModel.selectedTranscript) { transcript in
                    TranscriptRowView(
                        transcript: transcript,
                        isSelected: viewModel.selectedTranscript?.id == transcript.id,
                        onDelete: {
                            transcriptToDelete = transcript
                            showingDeleteAlert = true
                        }
                    )
                    .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Transcript"),
                message: Text("Are you sure you want to delete this transcript? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    if let transcript = transcriptToDelete {
                        viewModel.deleteTranscript(transcript)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct TranscriptRowView: View {
    let transcript: Transcript
    let isSelected: Bool
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with date and duration
            HStack {
                Text(transcript.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(transcript.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Transcript preview
            Text(transcript.text)
                .font(.body)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            // Footer with metadata
            HStack {
                Label("\(transcript.wordCount)", systemImage: "textformat")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if transcript.confidence > 0 {
                    Label("\(Int(transcript.confidence * 100))%", systemImage: "checkmark.circle")
                        .font(.caption2)
                        .foregroundColor(confidenceColor)
                }
                
                Spacer()
                
                // Action buttons (shown on hover)
                if isHovered {
                    HStack(spacing: 4) {
                        Button(action: {}) {
                            Image(systemName: "play.circle")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .help("Play audio")
                        
                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .help("Export")
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .foregroundColor(.red)
                        .help("Delete")
                    }
                    .font(.caption)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.2) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contextMenu(ContextMenu {
            Button("Play Audio") {
                NSWorkspace.shared.open(transcript.audioURL)
            }
            
            Button("Export...") {
                // Export action
            }
            
            Divider()
            
            Button("Delete") {
                onDelete()
            }
        })
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
}

struct EmptyStateView: View {
    let hasTranscripts: Bool
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasTranscripts ? "magnifyingglass" : "mic.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(hasTranscripts ? "No matching transcripts" : "No transcripts yet")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                if hasTranscripts {
                    Text("Try adjusting your search terms")
                        .font(.body)
                        .foregroundColor(.secondary)
                } else {
                    Text("Start your first recording to see transcripts here")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            if !hasTranscripts {
                Button("Start Recording") {
                    // This would trigger a new recording
                }
                .buttonStyle(DefaultButtonStyle())
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
}

// Preview removed for Swift 5.4 compatibility
// #Preview {
//     NavigationSplitView {
//         TranscriptListView(
//             viewModel: {
//                 let vm = MainViewModel(settings: Settings())
//                 vm.transcripts = [
//                     Transcript(
//                         text: "This is a sample transcript with some content to show how it looks in the list view.",
//                         audioURL: URL(fileURLWithPath: "/tmp/test1.m4a"),
//                         duration: 45.2,
//                         confidence: 0.92
//                     ),
//                     Transcript(
//                         text: "Another transcript with different content and a longer duration to test the display.",
//                         audioURL: URL(fileURLWithPath: "/tmp/test2.m4a"),
//                         duration: 128.7,
//                         confidence: 0.78
//                     )
//                 ]
//                 return vm
//             }(),
//             settings: Settings()
//         )
//         .frame(width: 300)
//     } detail: {
//         Text("Select a transcript")
//     }
// }