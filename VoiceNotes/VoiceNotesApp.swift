import SwiftUI

@main
struct VoiceNotesApp: App {
    @StateObject private var settings = Settings()
    @StateObject private var menuBarManager = MenuBarManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .onAppear {
                    setupMenuBar()
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Recording") {
                    // Bring window to front and start new recording
                    NSApp.activate(ignoringOtherApps: true)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(after: .appInfo) {
                Button("Settings...") {
                    // Open settings
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
    
    private func setupMenuBar() {
        if settings.showMenuBarIcon {
            menuBarManager.setupMenuBar()
        }
    }
}