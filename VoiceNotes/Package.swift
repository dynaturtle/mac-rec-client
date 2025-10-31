// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "VoiceNotes",
    platforms: [
        .macOS(.v11_0)
    ],
    products: [
        .executable(name: "VoiceNotes", targets: ["VoiceNotes"])
    ],
    targets: [
        .target(
            name: "VoiceNotes",
            path: ".",
            sources: [
                "VoiceNotesApp.swift",
                "Models",
                "Views", 
                "ViewModels",
                "Services",
                "Controllers",
                "Utils"
            ]
        )
    ]
)