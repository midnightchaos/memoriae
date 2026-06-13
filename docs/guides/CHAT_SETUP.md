# Memoriae - Memory Care App

A Flutter application designed to support individuals with memory care needs through various therapeutic activities and AI-powered chat support.

## Features

- 🏠 **Home Dashboard**: Quick access to all features
- 💬 **Connect & Chat**: AI-powered chat using Google's Gemini API for emotional support
- 🧠 **Memory Games**: Cognitive exercises and memory training
- 😊 **Faces Recognition**: Help remember familiar faces
- 🎨 **Drawing Therapy**: Creative expression through art
- 🧘 **Relaxation**: Guided meditation and calming exercises
- 👤 **Profile Management**: Personal settings and preferences

## Setup Instructions

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- A Google Gemini API key

### Getting a Gemini API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click on "Get API Key" or "Create API Key"
4. Copy your API key

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd mem3
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Configuring the Gemini API Key

When you first open the Connect & Chat feature, you'll be prompted to enter your Gemini API key:

1. Tap on the settings icon in the top right corner of the Connect screen
2. Enter your Gemini API key in the dialog
3. Tap "Save"

The API key will be securely stored on your device and used for all chat interactions.

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   └── chat_message.dart    # Chat message model
├── screens/                  # All app screens
│   ├── splash_screen.dart
│   ├── main_navigation_screen.dart
│   ├── home_screen.dart
│   ├── connect_screen.dart  # AI Chat feature
│   ├── memory_screen.dart
│   ├── faces_screen.dart
│   ├── drawing_therapy_screen.dart
│   ├── relax_screen.dart
│   └── profile_screen.dart
├── services/                 # Business logic services
│   ├── gemini_service.dart  # Gemini API integration
│   └── settings_service.dart # Local storage
└── theme/                    # App theming
    └── app_theme.dart       # Colors and styles
```

## Key Dependencies

- `http`: For API requests to Gemini
- `shared_preferences`: For storing API key locally
- `flutter_markdown`: For rendering formatted AI responses
- `intl`: For date/time formatting

## Features in Development

- [ ] Memory games implementation
- [ ] Face recognition with photos
- [ ] Drawing canvas with save functionality
- [ ] Relaxation exercises with audio
- [ ] Profile customization

## Privacy & Security

- API keys are stored locally on the device using encrypted shared preferences
- Chat history is stored only in memory during the session
- No data is sent to external servers except for Gemini API interactions
- All communication with Gemini API is encrypted via HTTPS

## Troubleshooting

### API Key Issues

If you get an API key error:
1. Verify your API key is correct
2. Check that the key has Gemini API access enabled
3. Ensure you have internet connectivity

### Build Errors

If you encounter build errors:
```bash
flutter clean
flutter pub get
flutter run
```

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue in the repository.

## Acknowledgments

- Google Gemini API for AI capabilities
- Flutter community for excellent packages and support
- Material Design for UI guidelines
