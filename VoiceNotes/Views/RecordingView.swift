import SwiftUI

struct RecordingView: View {
    let startTime: Date
    let duration: TimeInterval
    @ObservedObject var viewModel: MainViewModel
    
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Recording indicator with pulse animation
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    Circle()
                        .fill(Color.red)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                .onAppear {
                    pulseAnimation = true
                }
                
                Text("Recording...")
                    .font(.title)
                    .fontWeight(.medium)
                
                Text(formatDuration(duration))
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundColor(.primary)
            }
            
            // Audio level visualization
            AudioLevelVisualization()
                .frame(height: 60)
                .padding(.horizontal, 40)
            
            // Stop button
            Button(action: {
                viewModel.stopRecording()
            }) {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("Stop Recording")
                }
                .font(.title3)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
            .buttonStyle(DefaultButtonStyle())
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
            .keyboardShortcut(" ", modifiers: [])
            
            Spacer()
            
            // Recording info
            VStack(spacing: 8) {
                HStack {
                    Text("Started:")
                    Spacer()
                    Text(DateFormatter.timeFormatter.string(from: startTime))
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                HStack {
                    Text("Format:")
                    Spacer()
                    Text(viewModel.settings.audioFormat.displayName)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                HStack {
                    Text("Quality:")
                    Spacer()
                    Text(viewModel.settings.audioQuality.displayName)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .padding()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

struct AudioLevelVisualization: View {
    @State private var audioLevels: [Float] = Array(repeating: 0.0, count: 50)
    @State private var animationTimer: Timer?
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<audioLevels.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.blue)
                    .frame(width: 3)
                    .frame(height: CGFloat(audioLevels[index]) * 60)
                    .animation(.easeInOut(duration: 0.1), value: audioLevels[index])
            }
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // Simulate audio levels with random values
            // In a real implementation, this would come from the AudioRecordingService
            for i in 0..<audioLevels.count {
                audioLevels[i] = Float.random(in: 0.1...1.0)
            }
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()
}

// Preview removed for Swift 5.4 compatibility
// #Preview {
//     RecordingView(
//         startTime: Date(),
//         duration: 125.5,
//         viewModel: MainViewModel(settings: Settings())
//     )
// }