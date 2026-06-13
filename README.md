# Memoriae

AI-powered memory care companion focused on privacy, accessibility, and secure local-first data storage.

Built with Flutter + Gemini + SQLCipher.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9%2B-blue?logo=dart)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/SQLite-3-lightgrey?logo=sqlite)](https://sqlite.org)
[![SQLCipher](https://img.shields.io/badge/SQLCipher-Encrypted-red?logo=sqlite)](https://www.zetetic.net/sqlcipher)
[![Gemini](https://img.shields.io/badge/Gemini-AI-orange?logo=google)](https://ai.google.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## What is Memoriae?

Memoriae is a dedicated memory care companion application designed for individuals living with dementia or cognitive impairment, and their caregivers. By utilizing a local-first design and structured therapeutic tools, Memoriae assists users in orienting themselves, tracking daily routines, managing medications, and engaging in cognitive exercises. 

Menta features **Menta**, an intelligent, context-aware chatbot helper that assists users in accessing their personal history (journals, routines, medications, and family members) through conversational queries.

---

## Key Features

### 🔒 Privacy & Security
- **SQLCipher Encrypted Local Database**: All data is encrypted on-device.
- **AES-256 Encryption**: Field-level encryption for sensitive user history.
- **Biometric Authentication**: Fingerprint/face authentication for profile protection.
- **Secure API Key Storage**: Stored securely in native keychain/SharedPreferences.
- **Offline-First Architecture**: Functions fully without cloud dependency.

### 🧠 Memory Support
- **Memory Journal**: Document daily logs with photo attachments and voice notes.
- **Medication Management**: Full CRUD scheduling with automatic dose logs and refill alerts.
- **Daily Routines**: Morning/evening routines with completing checklists and reminders.
- **Familiar Faces**: A photo directory matching caregiver and family relationships.

### 💬 AI Assistance
- **Menta conversational assistant**: Empathetic multi-turn chatbot.
- **Gemini-powered responses**: Powered by direct REST integration.
- **Robust Error Handling**: Real-time retry mechanism and model fallback strategies.
- **Context-Aware Conversations**: Dynamically injects patient database context into the prompt safely.

### ♿ Accessibility
- **Large Text Support**: Optimised for senior readability.
- **Screen-Reader Friendly**: Native semantic labels across all widgets.
- **High-Contrast Design**: Clean Material 3 visual styling.
- **Voice Support**: Full text-to-speech option for audibly reading chatbot answers.

---

## Screenshots

### Main Dashboard & Conversational Assistant

| Dashboard | Menta Chat Assistant |
|---|---|
| ![Dashboard](docs/screenshots/dashboard.jpg) | ![Chatbot](docs/screenshots/chatbot.jpg) |

### Memory Journal & Medication Tracking

| Memory Journal | Medication Tracking |
|---|---|
| ![Journal](docs/screenshots/journal.jpg) | ![Medication](docs/screenshots/medication.jpg) |

### Settings & Authentication

| Accessibility & Settings | Biometrics & Security |
|---|---|
| ![Settings](docs/screenshots/settings.jpg) | ![Security](docs/screenshots/security.jpg) |

---

## Architecture

Menta uses a structured multi-layer architecture optimized for local state management and services:

```
Flutter UI
    ↓
Services Layer (Provider Dependency Injection)
    ↓
Repositories / Service Implementations
    ↓
SQLCipher Database (Local Storage)
```

For AI interactions:
```
Flutter UI → MentaService / GeminiService → Google Gemini API (REST over HTTP) → Response
```

*For more details, see [ARCHITECTURE.md](docs/ARCHITECTURE.md).*

---

## Security

Menta is built with patient data security as its highest priority:
- **SQLCipher Database Encryption**: The entire database is encrypted using a unique, securely generated key.
- **AES-256 encryption**: Specifically encrypts sensitive fields before storage.
- **Biometric Protection**: Optional biometric lock screens safeguard caregiver views and settings.
- **No Hardcoded Credentials**: Runtime API key configuration allows users to input their own keys without exposure.

*For more details, see [SECURITY.md](docs/SECURITY.md).*

---

## AI Assistant

Menta integrates Google's Gemini models through direct REST API calls. The application intentionally avoids heavyweight SDK dependencies in favor of a lightweight HTTP-based approach with explicit retry and error handling. 

System prompt personalization dynamically matches patient journals, daily agendas, and medication timings to respond empathetically and accurately to any memory recall queries.

---

## Installation

### Prerequisites
- Flutter SDK >= 3.0
- Dart SDK >= 3.9
- A Google Gemini API key

### Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/midnightchaos/menta.git
   cd menta
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure your API key. Create the gitignored `lib/config/env_config.dart` file:
   ```dart
   class EnvConfig {
     static const String geminiApiKey = 'YOUR_API_KEY_HERE';
     static bool get hasDefaultApiKey => geminiApiKey.isNotEmpty;
   }
   ```

---

## Development

Run code generation for mock classes:
```bash
dart run build_runner build --delete-conflicting-outputs
```

To run the application locally:
```bash
flutter run
```

---

## Testing

Menta uses a robust test suite covering services, business logic, and UI widgets:

```bash
# Run all unit and widget tests
flutter test
```

### Current Test Coverage:
- **Core services**: Authentication, database helper methods.
- **Widget behavior**: Routines checklist, main navigation elements.
- **Database validation**: Verification of encryption and schema constraints.

Additional test coverage for migration scripts and edge case AI timeouts is under development.

---

## Roadmap

### Near Term
- [ ] CI/CD pipeline automation
- [ ] Expanded unit & widget test coverage
- [ ] Caregiver secure remote synchronization
- [ ] Full accessibility validation (WCAG 2.1 AA)

### Future
- [ ] Offline local speech-to-text models
- [ ] End-to-end encrypted backup to patient's own cloud storage
- [ ] Caregiver collaborative note-taking hub

---

## Contributing

We welcome contributions to improve Menta. Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on branching, styles, and pull requests.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
