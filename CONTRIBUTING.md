# Contributing to Menta

Thank you for your interest in contributing to Menta! As a memory care assistant application, codebase quality, code clarity, and security are our highest priorities.

Please follow these guidelines when submitting patches, features, or bug fixes.

---

## Code of Conduct & Integrity

1. **Security-First**: Never commit or submit changes containing credentials, hardcoded API keys, or personal health identifiers (PHIs).
2. **Offline-First**: All new features must function without relying on an external server or backend databases.
3. **Accessibility Integration**: Ensure UI modifications preserve tactile sizing (minimum 48x48dp touch targets) and include readable descriptive semantic labels for screen readers.

---

## Technical Workflow

### 1. Requirements
- Flutter SDK >= 3.0
- Dart SDK >= 3.9

### 2. Setup
1. Fork and clone the repository.
2. Initialize local dependencies:
   ```bash
   flutter pub get
   ```
3. Generate mock classes:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

### 3. Naming Conventions & Code Style
- **Package references**: Always use the namespace `package:menta/` for internal package imports.
- **Service Layer**: Keep business logic out of the presentation files. Injected services must handle persistence and hardware interactions, communicating state through Provider notifications.

### 4. Tests
Always run our tests and run static analysis before submitting a Pull Request:
```bash
# Verify static analysis
flutter analyze

# Run the test suite
flutter test
```

We expect any new service logic to be covered by corresponding unit tests in the `test/` folder.
