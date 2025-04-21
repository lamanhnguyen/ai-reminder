// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "VoiceReminders",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(name: "VoiceReminders", targets: ["VoiceReminders"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "VoiceReminders",
            dependencies: []
        ),
        .testTarget(
            name: "VoiceRemindersTests",
            dependencies: ["VoiceReminders"]
        )
    ]
) 