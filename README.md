# Menta — AI Memory Care Companion

> A Flutter application designed to support individuals living with dementia and their caregivers. Menta combines therapeutic activities, AI-powered conversation, medication management, and safety features into a calm, accessible mobile experience.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9%2B-blue?logo=dart)](https://dart.dev)
[![Gemini AI](https://img.shields.io/badge/Gemini-AI-orange?logo=google)](https://ai.google.dev)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## Features

### 🧠 Memory Journal
Full-featured journal with photo attachments, voice recordings, mood tracking, and tag-based filtering. Entries are persisted locally via an encrypted SQLite database.

### 👥 Familiar Faces
A photo directory of caregivers, family members, and friends with relationship labels. Helps users maintain social orientation and recognise important people in their lives.

### 🎵 Music Therapy
Curated therapeutic playlist playback using the device audio player. Music selection is tailored to evoke positive memories and reduce anxiety.

### 🎨 Drawing Therapy
Free-form canvas with a colour palette and save-to-gallery capability. Provides a low-barrier creative outlet.

### 🧘 Relaxation Hub
Entry point for all therapeutic modalities: guided meditation, breathing exercises, music therapy, and art therapy — accessible from a single screen.

### 💬 Menta AI Chatbot
Conversational AI assistant powered by the Gemini API. Maintains multi-turn conversation history in the local database and supports retry across multiple model endpoints (`gemini-flash`, `gemini-2.0-flash`, `gemini-2.5-flash`). Requires a user-provided API key stored in `SharedPreferences` — never hardcoded.

### 💊 Medication Manager
Full CRUD for medication schedules with local push notifications via `flutter_local_notifications`. Tracks dose history and surfaces refill reminders.

### 📅 Daily Routines
Configurable morning/evening routines with per-task completion tracking and notification-based reminders.

### 📍 Safety Locations
Geofenced safe-zone management with caregiver alert integration via the `AlertService`.

### 🧩 Memory Games
Cognitive stimulation mini-games (face-matching) with progress tracking via the `MentaGamesService`.

### 🔒 Authentication & Security
- PIN / biometric authentication (`local_auth`)
- Encrypted database via `sqflite_sqlcipher`
- Field-level encryption via `EncryptionService`
- Audit logging for sensitive operations

### 👨‍👩‍👧 Caregiver Mode
Dedicated caregiver screens for monitoring activity, reviewing logs, and configuring alerts.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x / Dart 3.9+ |
| State Management | Provider |
| Local Database | sqflite\_sqlcipher (encrypted SQLite) |
| AI | Google Gemini API (REST via `http`) |
| Notifications | flutter\_local\_notifications + timezone |
| Media | audioplayers, record, image\_picker |
| Security | flutter\_secure\_storage, local\_auth, encrypt |
| Analytics | Custom `AnalyticsService` |

---

## Project Structure

```
lib/
├── main.dart                          # App entry, provider setup, service init
│
├── config/                            # Environment & system prompt configuration
│   ├── env_config.dart                # API key loader (never commit real values)
│   └── menta_system_prompt.dart       # Gemini AI system persona
│
├── models/                            # Pure data classes with toMap/fromMap
│   ├── chat_message.dart
│   ├── journal_entry.dart
│   ├── medication.dart
│   ├── familiar_face.dart
│   ├── daily_routine.dart
│   ├── safety_location.dart
│   └── user_profile.dart
│
├── services/                          # Business logic & data access layer
│   ├── database_helper.dart           # Singleton encrypted SQLite wrapper
│   ├── database_migrator.dart         # Schema version migrations
│   ├── gemini_service.dart            # Gemini REST client with multi-endpoint retry
│   ├── menta_service.dart             # AI response orchestration
│   ├── auth_service.dart              # Auth + session management
│   ├── encryption_service.dart        # AES field encryption
│   ├── analytics_service.dart         # Usage event tracking
│   ├── audit_logging_service.dart     # Tamper-evident operation logs
│   ├── journal_service.dart           # Journal CRUD
│   ├── familiar_face_service.dart     # Faces CRUD
│   ├── music_library_service.dart     # Music catalogue management
│   ├── medication_notification_service.dart
│   ├── daily_routine_notification_service.dart
│   ├── activity_monitoring_service.dart
│   ├── inactivity_detection_service.dart
│   ├── alert_service.dart
│   ├── data_export_service.dart
│   └── profile_service.dart
│
├── screens/                           # One file per screen
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── main_navigation_screen.dart
│   ├── chatbot_screen.dart
│   ├── memory_screen.dart             # Journal list & search
│   ├── add_edit_journal_screen.dart   # Journal editor (voice + photo)
│   ├── familiar_faces_screen.dart
│   ├── add_edit_face_screen.dart
│   ├── music_therapy_screen.dart
│   ├── drawing_therapy_screen.dart
│   ├── meditation_screen.dart
│   ├── breathing_exercise_screen.dart
│   ├── relax_screen.dart
│   ├── daily_routines_screen.dart
│   ├── medications_screen.dart
│   ├── safety_locations_screen.dart
│   ├── face_matching_game_screen.dart
│   ├── settings_screen.dart
│   ├── export_settings_screen.dart
│   ├── edit_profile_screen.dart
│   ├── profile_screen.dart
│   ├── connect_screen.dart
│   ├── about_screen.dart
│   └── auth/                          # Auth flow screens
│       └── caregiver/                 # Caregiver-specific screens
│
├── theme/
│   └── app_theme.dart                 # Material 3 colour tokens, text styles
│
├── providers/
│   └── export_provider.dart           # Data export state
│
└── widgets/                           # Reusable UI components
    ├── glass_card.dart
    ├── familiar_face_card.dart
    ├── feature_tile.dart
    ├── menta_assistant.dart
    ├── animated_page_wrapper.dart
    └── rounded_image_picker.dart

test/
├── gemini_service_test.dart           # GeminiService unit tests
├── routine_notification_test.dart     # Notification scheduling tests
├── routine_ui_test.dart               # Widget tests
└── widget_test.dart
```

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.0 ([install](https://docs.flutter.dev/get-started/install))
- Dart SDK ≥ 3.9
- A [Google Gemini API key](https://aistudio.google.com/app/apikey) (free tier available)

### 1. Clone

```bash
git clone https://github.com/<your-username>/menta.git
cd menta
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure your API key

Create `lib/config/env_config.dart` (excluded from git):

```dart
class EnvConfig {
  static const String geminiApiKey = 'YOUR_API_KEY_HERE';
  static bool get hasDefaultApiKey => geminiApiKey.isNotEmpty;
}
```

> **Security note:** The API key can also be entered at runtime via the in-app Settings screen and is stored in `SharedPreferences` — it is never compiled into the binary.

### 4. Run

```bash
flutter run
```

---

## Running Tests

```bash
# All tests
flutter test

# Single file
flutter test test/gemini_service_test.dart
```

---

## Architecture Decisions

**Local-first.** All user data is stored on-device in an encrypted SQLite database. No backend server, no cloud sync. This was a deliberate choice for the dementia care context: data sovereignty and offline reliability matter more than cross-device sync.

**Service layer over repositories.** Services are singleton classes injected via Provider. They own all I/O (database, network, notifications) and expose clean async methods to UI screens. Screens contain no business logic.

**Single canonical implementation.** Earlier in development, experimental variants of screens and services accumulated (`_enhanced`, `_backup`, `_fixed` suffixes). These have been removed; the codebase now has one authoritative implementation per feature.

**Gemini via REST, not SDK.** The `GeminiService` uses `package:http` directly rather than `package:google_generative_ai`. This gives full control over model endpoint selection, retry logic across fallback models, and explicit timeout handling.

---

## Accessibility

The UI is designed for older adults and users with cognitive impairment:

- Minimum touch targets: 48 × 48 dp
- Minimum body text: 16 sp
- All interactive elements have semantic labels
- Dark/light mode with high-contrast colour palette
- Emoji-based visual cues supplement text labels
- Animations are slow (300–800 ms) and never loop continuously

---

## Roadmap

- [ ] Caregiver remote monitoring dashboard
- [ ] End-to-end encrypted caregiver ↔ patient sync
- [ ] Photo memory timeline view
- [ ] Offline speech-to-text for journal dictation
- [ ] Accessibility audit (WCAG 2.1 AA target)

---

## Contributing

1. Fork and branch from `main`
2. Follow existing service/screen patterns
3. Add tests for any new service methods
4. Keep all API keys out of source — use `env_config.dart`

---

## License

MIT © Menta Contributors
