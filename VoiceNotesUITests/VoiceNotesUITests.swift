import XCTest

final class VoiceNotesUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithResult() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithResult() throws {
        app = nil
    }
    
    // MARK: - App Launch Tests
    
    func testAppLaunch() throws {
        // Test that the app launches successfully
        XCTAssertTrue(app.windows.firstMatch.exists)
        
        // Test that main UI elements are present
        XCTAssertTrue(app.staticTexts["VoiceNotes"].exists || app.navigationBars.firstMatch.exists)
    }
    
    func testMainWindowElements() throws {
        // Test that key UI elements are present in the main window
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists)
        
        // Check for navigation split view or main content
        let splitView = app.splitGroups.firstMatch
        if splitView.exists {
            XCTAssertTrue(splitView.exists)
        }
        
        // Look for transcript list or empty state
        let transcriptsList = app.tables.firstMatch
        let emptyStateText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'No transcripts'")).firstMatch
        
        XCTAssertTrue(transcriptsList.exists || emptyStateText.exists)
    }
    
    // MARK: - Recording Flow Tests
    
    func testRecordingButtonExists() throws {
        // Look for recording button in various possible locations
        let recordButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Record' OR identifier CONTAINS 'record'")).firstMatch
        let micButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'mic' OR identifier CONTAINS 'mic'")).firstMatch
        let startButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Start'")).firstMatch
        
        XCTAssertTrue(recordButton.exists || micButton.exists || startButton.exists, "Recording button should be present")
    }
    
    func testRecordingWorkflow() throws {
        // Find and tap the record button
        let recordButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Record' OR identifier CONTAINS 'record'")).firstMatch
        
        if recordButton.exists {
            recordButton.tap()
            
            // Wait for recording state to appear
            let recordingIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Recording'")).firstMatch
            let stopButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Stop'")).firstMatch
            
            // Check that we're in recording state
            XCTAssertTrue(recordingIndicator.waitForExistence(timeout: 2) || stopButton.waitForExistence(timeout: 2))
            
            // Stop recording if we found a stop button
            if stopButton.exists {
                stopButton.tap()
                
                // Wait for transcription or completion state
                let transcribingText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Transcribing'")).firstMatch
                let completedText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Complete'")).firstMatch
                
                XCTAssertTrue(transcribingText.waitForExistence(timeout: 2) || completedText.waitForExistence(timeout: 5))
            }
        }
    }
    
    // MARK: - Settings Tests
    
    func testSettingsAccess() throws {
        // Look for settings button or menu
        let settingsButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Settings' OR identifier CONTAINS 'settings'")).firstMatch
        let preferencesButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Preferences'")).firstMatch
        
        // Try menu bar access
        let menuBar = app.menuBars.firstMatch
        if menuBar.exists {
            let appMenu = menuBar.menuBarItems.firstMatch
            if appMenu.exists {
                appMenu.click()
                let preferencesMenuItem = app.menuItems["Preferences..."]
                if preferencesMenuItem.exists {
                    preferencesMenuItem.click()
                    
                    // Check that settings window opened
                    let settingsWindow = app.windows.containing(NSPredicate(format: "title CONTAINS 'Settings' OR title CONTAINS 'Preferences'")).firstMatch
                    XCTAssertTrue(settingsWindow.waitForExistence(timeout: 2))
                    return
                }
            }
        }
        
        // Try direct button access
        if settingsButton.exists {
            settingsButton.tap()
        } else if preferencesButton.exists {
            preferencesButton.tap()
        }
        
        // Verify settings interface appeared
        let settingsWindow = app.windows.containing(NSPredicate(format: "title CONTAINS 'Settings' OR title CONTAINS 'Preferences'")).firstMatch
        let settingsView = app.groups.containing(NSPredicate(format: "identifier CONTAINS 'settings'")).firstMatch
        
        XCTAssertTrue(settingsWindow.waitForExistence(timeout: 2) || settingsView.waitForExistence(timeout: 2))
    }
    
    func testSettingsNavigation() throws {
        // Open settings first
        testSettingsAccess()
        
        // Look for settings tabs or sections
        let generalTab = app.buttons.containing(NSPredicate(format: "label CONTAINS 'General'")).firstMatch
        let recordingTab = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Recording'")).firstMatch
        let transcriptionTab = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Transcription'")).firstMatch
        
        if generalTab.exists {
            generalTab.tap()
            XCTAssertTrue(generalTab.isSelected)
        }
        
        if recordingTab.exists {
            recordingTab.tap()
            XCTAssertTrue(recordingTab.isSelected)
        }
        
        if transcriptionTab.exists {
            transcriptionTab.tap()
            XCTAssertTrue(transcriptionTab.isSelected)
        }
    }
    
    // MARK: - Transcript Management Tests
    
    func testTranscriptListInteraction() throws {
        let transcriptsList = app.tables.firstMatch
        
        if transcriptsList.exists && transcriptsList.cells.count > 0 {
            // Test selecting a transcript
            let firstCell = transcriptsList.cells.firstMatch
            firstCell.tap()
            
            // Verify selection or detail view
            XCTAssertTrue(firstCell.isSelected || app.textViews.firstMatch.exists)
        }
    }
    
    func testTranscriptContextMenu() throws {
        let transcriptsList = app.tables.firstMatch
        
        if transcriptsList.exists && transcriptsList.cells.count > 0 {
            let firstCell = transcriptsList.cells.firstMatch
            firstCell.rightClick()
            
            // Look for context menu items
            let exportMenuItem = app.menuItems.containing(NSPredicate(format: "title CONTAINS 'Export'")).firstMatch
            let deleteMenuItem = app.menuItems.containing(NSPredicate(format: "title CONTAINS 'Delete'")).firstMatch
            let playMenuItem = app.menuItems.containing(NSPredicate(format: "title CONTAINS 'Play'")).firstMatch
            
            XCTAssertTrue(exportMenuItem.exists || deleteMenuItem.exists || playMenuItem.exists)
            
            // Dismiss context menu
            app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        }
    }
    
    // MARK: - Menu Bar Tests
    
    func testMenuBarIntegration() throws {
        // Test main menu bar items
        let menuBar = app.menuBars.firstMatch
        XCTAssertTrue(menuBar.exists)
        
        // Test File menu
        let fileMenu = menuBar.menuBarItems["File"]
        if fileMenu.exists {
            fileMenu.click()
            
            let newRecordingItem = app.menuItems.containing(NSPredicate(format: "title CONTAINS 'New Recording'")).firstMatch
            let openItem = app.menuItems["Open..."]
            
            XCTAssertTrue(newRecordingItem.exists || openItem.exists)
            
            // Dismiss menu
            app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        }
        
        // Test Edit menu
        let editMenu = menuBar.menuBarItems["Edit"]
        if editMenu.exists {
            editMenu.click()
            
            let copyItem = app.menuItems["Copy"]
            let pasteItem = app.menuItems["Paste"]
            
            XCTAssertTrue(copyItem.exists || pasteItem.exists)
            
            // Dismiss menu
            app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        }
    }
    
    // MARK: - Keyboard Shortcuts Tests
    
    func testKeyboardShortcuts() throws {
        // Test Command+R for recording (if implemented)
        app.typeKey("r", modifierFlags: .command)
        
        // Wait a moment for the action to process
        sleep(1)
        
        // Check if recording started
        let recordingIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Recording'")).firstMatch
        let stopButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Stop'")).firstMatch
        
        // If recording started, stop it
        if recordingIndicator.exists || stopButton.exists {
            app.typeKey(".", modifierFlags: .command) // Command+. to stop
        }
        
        // Test Command+, for settings
        app.typeKey(",", modifierFlags: .command)
        
        let settingsWindow = app.windows.containing(NSPredicate(format: "title CONTAINS 'Settings' OR title CONTAINS 'Preferences'")).firstMatch
        if settingsWindow.waitForExistence(timeout: 2) {
            // Close settings
            app.typeKey("w", modifierFlags: .command)
        }
    }
    
    // MARK: - Export Functionality Tests
    
    func testExportFunctionality() throws {
        let transcriptsList = app.tables.firstMatch
        
        if transcriptsList.exists && transcriptsList.cells.count > 0 {
            let firstCell = transcriptsList.cells.firstMatch
            firstCell.tap()
            
            // Look for export button
            let exportButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Export' OR identifier CONTAINS 'export'")).firstMatch
            let shareButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Share'")).firstMatch
            
            if exportButton.exists {
                exportButton.tap()
                
                // Look for file dialog or export options
                let saveDialog = app.sheets.firstMatch
                let exportDialog = app.windows.containing(NSPredicate(format: "title CONTAINS 'Export'")).firstMatch
                
                XCTAssertTrue(saveDialog.waitForExistence(timeout: 2) || exportDialog.waitForExistence(timeout: 2))
                
                // Cancel the dialog
                let cancelButton = app.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                }
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorDialogHandling() throws {
        // This test would need to trigger an error condition
        // For now, we'll just check that error dialogs can be dismissed if they appear
        
        let errorAlert = app.alerts.firstMatch
        if errorAlert.exists {
            let okButton = errorAlert.buttons["OK"]
            let dismissButton = errorAlert.buttons["Dismiss"]
            
            if okButton.exists {
                okButton.tap()
            } else if dismissButton.exists {
                dismissButton.tap()
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launch()
            app.terminate()
        }
    }
    
    func testScrollingPerformance() throws {
        let transcriptsList = app.tables.firstMatch
        
        if transcriptsList.exists {
            measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric]) {
                transcriptsList.swipeUp()
                transcriptsList.swipeDown()
            }
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityElements() throws {
        // Test that key UI elements have accessibility labels
        let recordButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Record' OR identifier CONTAINS 'record'")).firstMatch
        
        if recordButton.exists {
            XCTAssertFalse(recordButton.label.isEmpty, "Record button should have accessibility label")
        }
        
        // Test that transcript list items are accessible
        let transcriptsList = app.tables.firstMatch
        if transcriptsList.exists && transcriptsList.cells.count > 0 {
            let firstCell = transcriptsList.cells.firstMatch
            XCTAssertTrue(firstCell.isHittable, "Transcript cells should be accessible")
        }
    }
    
    // MARK: - Window Management Tests
    
    func testWindowResizing() throws {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists)
        
        // Get initial frame
        let initialFrame = window.frame
        
        // Try to resize (this might not work in all test environments)
        window.resize(withSizeOffset: CGVector(dx: 100, dy: 100))
        
        // Verify window still exists and is functional
        XCTAssertTrue(window.exists)
        XCTAssertTrue(window.frame.width >= initialFrame.width || window.frame.height >= initialFrame.height)
    }
    
    func testMultipleWindowHandling() throws {
        // Test opening settings window while main window is open
        testSettingsAccess()
        
        // Verify both windows exist
        let mainWindow = app.windows.element(boundBy: 0)
        let settingsWindow = app.windows.element(boundBy: 1)
        
        if app.windows.count > 1 {
            XCTAssertTrue(mainWindow.exists)
            XCTAssertTrue(settingsWindow.exists)
            
            // Close settings window
            settingsWindow.buttons[XCUIIdentifierCloseWindow].tap()
        }
    }
}