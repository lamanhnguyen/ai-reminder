# AI Reminder

AI Reminder is an iOS app that enables users to create and manage reminders with voice input functionality. Built with SwiftUI, the app offers a clean, intuitive interface inspired by Apple's Reminders app, with enhanced features like voice recognition for hands-free reminder creation.

## Features

- **Multiple List Management**: Create and organize reminders in different color-coded lists
- **Voice Input**: Add reminders using speech recognition
- **Comprehensive Reminder Details**:
  - Title and notes
  - Due dates with time
  - Priority settings
  - Recurrence options (daily, weekly, monthly, yearly)
- **Clean SwiftUI Interface**: Modern UI with smooth transitions and animations
- **Status Tracking**: Mark reminders as completed and view completion status
- **Notifications**: Scheduled notifications for upcoming reminders

## Screenshots

[Screenshots will be added here]

## Technologies Used

- **SwiftUI**: Modern declarative UI framework
- **Speech Recognition**: For voice input functionality
- **AVFoundation**: For audio handling and recording
- **UserDefaults**: For data persistence
- **Swift Concurrency**: For asynchronous operations

## Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 5.7+

## Installation

1. Clone this repository:
```bash
git clone https://github.com/YOUR_USERNAME/ai-reminder.git
cd ai-reminder
```

2. Open the `VoiceReminders.xcodeproj` file in Xcode

3. Select your development team in the Signing & Capabilities tab

4. Build and run the app on your device or simulator

## Usage

### Creating a New List
1. Launch the app
2. Tap the "Add List" button in the main view
3. Enter a name and choose a color for your list
4. Tap "Save"

### Adding a Reminder
1. Select a list from the main view
2. Tap "New Reminder"
3. Enter a title and any additional details
4. Optionally enable voice input to dictate your reminder
5. Set due date, recurrence, and priority as needed
6. Tap "Save"

### Using Voice Input
1. When creating a reminder, toggle "Use Voice Input"
2. Tap the microphone button to start recording
3. Speak clearly to capture your reminder
4. Tap the stop button when finished
5. The recognized text will be inserted as your reminder title

## Future Improvements

- Cloud synchronization with iCloud
- Smart reminders with location-based triggers
- Advanced natural language processing for dates and times
- Task categorization using machine learning
- Sharing lists with other users

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- Speech recognition powered by Apple's Speech Framework
- UI design inspired by Apple's Reminders app
- Developed with SwiftUI 