# Menta — Documentation Index

## Overview

| Document | Description |
|---|---|
| [README.md](../../README.md) | Project overview, features, architecture, setup |
| [QUICK_START.md](QUICK_START.md) | Get running in 5 minutes |
| [TESTING_GUIDE.md](TESTING_GUIDE.md) | Manual test checklist for the AI chatbot |

## Architecture Reference

The primary architectural reference is the [README](../../README.md), which documents:

- **Feature inventory** — all 15 screens and what each does
- **Tech stack** — Flutter, Provider, sqflite_sqlcipher, Gemini REST, audioplayers
- **Project structure** — annotated directory tree for every module
- **Architecture decisions** — why local-first, REST over SDK, single service pattern
- **Accessibility principles** — touch targets, contrast, cognitive load

## Key Files

```
lib/
├── main.dart                        App entry, provider wiring, service bootstrap
├── services/database_helper.dart    Singleton encrypted SQLite wrapper
├── services/gemini_service.dart     Gemini client — retry logic, conversation history
├── services/menta_service.dart      AI response orchestration
├── services/auth_service.dart       PIN / biometric auth + session management
└── theme/app_theme.dart             Material 3 design tokens
```

## API Key Setup

See [README § Getting Started](../../README.md#getting-started) — the key is:

1. Create `lib/config/env_config.dart` (git-ignored, never committed)
2. Or enter at runtime in **Settings → Gemini API Key**

Keys are stored in `SharedPreferences`, not compiled into the binary.
