# System Architecture

This document describes the architectural design, layer boundaries, and data flows of the **Menta** memory care application.

## Overview

Menta is designed as a local-first, offline-capable mobile application. It prioritizes data privacy, low-latency interactions, and high accessibility. By avoiding a mandatory cloud backend, it ensures that sensitive patient data remains strictly on the user's device.

---

## Architectural Layers

```
┌────────────────────────────────────────────────────────┐
│                      Presentation                      │
│   (Material 3 UI, Widgets, Multi-Turn Chat Screens)    │
└───────────────────────────┬────────────────────────────┘
                            │ (Uses Provider)
                            ▼
┌────────────────────────────────────────────────────────┐
│                     Service Layer                      │
│   (State management, Event triggers, AI Orchestrator)  │
└───────────────────────────┬────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
┌───────────────────────────┐ ┌───────────────────────────┐
│     Database Helpers      │ │      External Clients     │
│   (SQLCipher, Migrations) │ │   (Gemini API REST, TTS)  │
└─────────────┬─────────────┘ └───────────────────────────┘
              ▼
┌───────────────────────────┐
│       Encrypted DB        │
│    (Secure Local Storage) │
└───────────────────────────┘
```

### 1. Presentation Layer (`lib/screens`, `lib/widgets`)
- Contains all UI layouts built using Material 3 guidelines.
- Adheres to strict accessibility targets (minimum 48x48dp touch targets, readable 16sp font sizes, semantic attributes).
- Uses `Provider` to watch state modifications and interact with the service layer.

### 2. Service Layer (`lib/services`)
- Acts as the controller/business logic layer of the application.
- All services are singletons managed via `Provider`.
- Contains specific components for:
  - **AI Integration**: `GeminiService` and `MentaService`.
  - **Security**: `AuthService`, `EncryptionService`, and `AuditLoggingService`.
  - **Care Management**: `MedicationNotificationService`, `DailyRoutineNotificationService`, and `FamiliarFaceService`.
  - **Safety**: `ActivityMonitoringService` and `InactivityDetectionService`.

### 3. Data Access Layer (`lib/services/database_helper.dart`)
- Implements direct interfaces to the secure local database.
- Coordinates schema migrations via `DatabaseMigrator`.

---

## Core Data Flows

### 1. Context-Aware AI Chat Flow
When a user types a message to the Menta Chatbot:
1. `ChatbotScreen` sends the query to `MentaService`.
2. `GeminiService` is queried and loads fresh data context (journals, active routines, medications, zones) from `DatabaseHelper`.
3. System prompts and database contexts are compiled together with the user prompt.
4. `GeminiService` sends a direct REST request to Gemini models.
5. In case of timeouts or 503 errors, retry logic kicks in. If the primary model fails, the service falls back to a lighter variant (`gemini-flash-lite`).
6. The final response is saved to the local database history and returned to the UI.

### 2. Medication Notification Flow
1. Patient or caregiver schedules a medication.
2. `MedicationNotificationService` writes the medication profile to the database.
3. The service schedules local push notifications using `flutter_local_notifications`.
4. Notifications trigger even if the app is closed or offline.
