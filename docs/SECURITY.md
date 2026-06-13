# Security & Privacy Policy

This document details the security model, cryptographic controls, and privacy-preservation techniques implemented in the **Menta** application.

## Core Security Pillars

Menta deals with healthcare-adjacent data (dementia patient logs, medication schedules, familiar faces, and safety geofences). To protect patient privacy, the app implements five distinct layers of security:

```
┌────────────────────────────────────────────────────────┐
│                   Caregiver / User                     │
│           Biometric Lock (local_auth PIN)              │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│             Encryption Key Management                  │
│       flutter_secure_storage (Hardware Backed)         │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│              Database Level Protection                 │
│         SQLCipher Database Encryption (SQLite)         │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│               Field-Level Protection                   │
│           AES-256-CBC Field-Level Encryption           │
└────────────────────────────────────────────────────────┘
```

---

## 1. Storage Encryption (SQLCipher)
- **Database Encryption**: Instead of a plain SQLite database, Menta uses `sqflite_sqlcipher`. 
- **Encryption Key**: A unique encryption key is generated upon the first app launch and saved in the device's hardware-backed secure storage (KeyStore on Android, Keychain on iOS) via `flutter_secure_storage`.
- **Database Access**: The database cannot be opened, copied, or read without this securely stored key.

## 2. Field-Level Encryption (AES-256)
- **Sensitive Inputs**: Fields containing highly sensitive patient entries (such as detailed journal logs or address details) undergo secondary field-level encryption using `EncryptionService`.
- **Algorithm**: Standard AES-256 in CBC mode is utilized.

## 3. Biometric Protection
- **Caregiver Views**: Caregiver dashboards and sensitive configurations (e.g. exporting data or deleting safety locations) require authorization.
- **Implementation**: Utilizes `local_auth` to request fingerprint, face scan, or device PIN before displaying restricted views.

## 4. No Hardcoded Secrets
- **API Key Practices**: Menta connects to the Google Gemini API using a user-configured key. This key can be configured:
  1. Individually by the user in the in-app settings screen (stored in `SharedPreferences`).
  2. Via a gitignored configuration file (`lib/config/env_config.dart`) during local builds.
- **Prevention**: Hardcoded keys are explicitly scanned and barred from the source repository.

## 5. Offline-First Privacy
- **No Remote Sync**: No data is sent to external servers except direct, user-prompted requests to the Google Gemini API.
- **Data Sovereignty**: The patient and caregiver retain absolute control over their records. Data can be exported as a JSON archive from the settings pane and deleted permanently from the device at any time.
