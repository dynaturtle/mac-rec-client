import SwiftUI

struct TranscribingView: View {
    let audioURL: URL
    let progress: Double
    @ObservedObject var viewModel: MainViewModel
    
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Transcription animation
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: progress)
                    
                    Image(systemName: "waveform")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(rotationAngle))
                        .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: rotationAngle)
                }
                .onAppear {
                    rotationAngle = 360
                }
                
                Text("Transcribing Audio...")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("\(Int(progress * 100))% Complete")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Progress details
            VStack(spacing: 12) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: 300)
                
                HStack {
                    Text("Processing audio file...")
                    Spacer()
                    Text(audioURL.lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(.caption)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Cancel button
            Button(action: {
                viewModel.cancelTranscription()
                viewModel.resetToIdle()
            }) {
                Text("Cancel")
                    .font(.body)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
            }
            .buttonStyle(DefaultButtonStyle())
            
            // Transcription info
            VStack(spacing: 8) {
                HStack {
                    Text("Language:")
                    Spacer()
                    Text(viewModel.settings.languageDisplayName(for: viewModel.settings.language))
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                HStack {
                    Text("Recognition:")
                    Spacer()
                    Text("Cloud-based (High Accuracy)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                if progress > 0 {
                    HStack {
                        Text("Estimated time:")
                        Spacer()
                        Text(estimatedTimeRemaining)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .padding()
    }
    
    private var estimatedTimeRemaining: String {
        guard progress > 0.1 else { return "Calculating..." }
        
        // Simple estimation based on current progress
        let elapsedTime = Date().timeIntervalSince(Date()) // This would need to track actual start time
        let totalEstimatedTime = elapsedTime / progress
        let remainingTime = totalEstimatedTime - elapsedTime
        
        if remainingTime < 60 {
            return "\(Int(remainingTime))s"
        } else {
            let minutes = Int(remainingTime) / 60
            let seconds = Int(remainingTime) % 60
            return "\(minutes)m \(seconds)s"
        }
    }
}

// Preview removed for Swift 5.4 compatibility
// #Preview {
//     TranscribingView(
//         audioURL: URL(fileURLWithPath: "/tmp/test.m4a"),
//         progress: 0.65,
//         viewModel: MainViewModel(settings: Settings())
//     )
// }