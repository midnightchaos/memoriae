# Memoriae App - Phase Implementation Plan

## Current Status
✅ **Chat Feature (Connect Screen)** - Complete with Gemini API integration
✅ **Basic UI Screens** - Splash, Home, Navigation, Drawing, Faces, Relax, Profile
✅ **Database Helper** - Base schema with Users and Journal entries
✅ **Theme System** - Complete with colors and gradients

## Implementation Phases

### Phase 1: Authentication System (HIGH PRIORITY) 🔴
**Status**: Not Started
**Estimated Time**: 3-4 hours

#### Components to Create:
1. **Authentication Service** (`lib/services/auth_service.dart`)
   - Password hashing (bcrypt/crypto)
   - User registration
   - User login
   - Guest mode
   - Session management
   
2. **Auth Screens**:
   - Login Screen (`lib/screens/auth/login_screen.dart`)
   - Registration Screen (`lib/screens/auth/registration_screen.dart`)
   - Welcome Screen (`lib/screens/auth/welcome_screen.dart`)

3. **Models**: 
   - Update User model with authentication fields

4. **Dependencies to Add**:
   ```yaml
   crypto: ^3.0.3  # For password hashing
   ```

#### Implementation Steps:
- [ ] Create AuthService with password hashing
- [ ] Create Welcome Screen (Choose login/register/guest)
- [ ] Create Login Screen with form validation
- [ ] Create Registration Screen with form validation  
- [ ] Update splash screen to check auth status
- [ ] Add guest mode functionality
- [ ] Test full authentication flow

---

### Phase 2: Database Schema Expansion (HIGH PRIORITY) 🔴
**Status**: Not Started
**Estimated Time**: 2-3 hours

#### New Tables to Add:
1. **Familiar Faces**
   ```sql
   id, name, relation, phoneNumber, email, photoPath, notes, createdAt
   ```

2. **Medications**
   ```sql
   id, name, dosage, frequency, time, notes, isActive, createdAt
   ```

3. **Daily Routines**
   ```sql
   id, title, description, time, days, isActive, createdAt
   ```

4. **Safety Locations**
   ```sql
   id, name, address, latitude, longitude, radius, isHome, createdAt
   ```

5. **Memory Games Progress**
   ```sql
   id, gameType, score, completedAt, duration
   ```

#### Implementation Steps:
- [ ] Update database version
- [ ] Add migration logic
- [ ] Create new tables
- [ ] Add CRUD operations for each table
- [ ] Test database operations

---

### Phase 3: Complete Missing Screens (MEDIUM PRIORITY) 🟡
**Status**: Partially Complete
**Estimated Time**: 4-5 hours

#### 1. Faces Screen - Full Implementation
- [ ] Add photo upload functionality
- [ ] Implement call/message actions
- [ ] Add edit/delete face
- [ ] Search and filter faces

#### 2. Medications Screen (NEW)
**Location**: `lib/screens/medications_screen.dart`
- [ ] List all medications
- [ ] Add new medication
- [ ] Edit medication
- [ ] Delete medication
- [ ] Medication reminders
- [ ] Track taken/missed doses

#### 3. Daily Routine Screen (NEW)
**Location**: `lib/screens/routine_screen.dart`
- [ ] View daily schedule
- [ ] Add new routine item
- [ ] Edit routine
- [ ] Check off completed tasks
- [ ] Weekly view

#### 4. Location Safety Screen (NEW)
**Location**: `lib/screens/location_safety_screen.dart`
- [ ] View safe locations on map
- [ ] Add new safe location
- [ ] Edit location
- [ ] Set geofencing alerts
- [ ] Current location tracking

#### 5. Memory Games Screen (NEW)
**Location**: `lib/screens/games_screen.dart`
- [ ] Game selection menu
- [ ] Memory matching game
- [ ] Pattern recall game
- [ ] Word association game
- [ ] Progress tracking

#### 6. Complete Relax Activities
Currently has basic structure, needs:
- [ ] Music therapy player
- [ ] Guided meditation audio
- [ ] Art therapy templates
- [ ] Breathing exercise animations

---

### Phase 4: Home Screen Navigation (HIGH PRIORITY) 🔴
**Status**: Needs Update
**Estimated Time**: 1-2 hours

#### Updates Required:
```dart
// Connect each feature card to its screen:
1. Memory Journal → MemoryScreen (exists)
2. Familiar Faces → FacesScreen (exists, needs completion)
3. Daily Routine → RoutineScreen (needs creation)
4. Location Safety → LocationSafetyScreen (needs creation)
5. Memory Games → GamesScreen (needs creation)
6. My Meds → MedicationsScreen (needs creation)
```

#### Implementation Steps:
- [ ] Add navigation routes
- [ ] Connect all feature cards
- [ ] Test navigation flow
- [ ] Add back button handling

---

### Phase 5: Memory Journal Enhancement (MEDIUM PRIORITY) 🟡
**Status**: Basic structure exists
**Estimated Time**: 3-4 hours

#### Features to Add:
- [ ] Create new journal entry screen
- [ ] Voice-to-text entry
- [ ] Photo attachment
- [ ] Audio recording
- [ ] Edit existing entries
- [ ] Delete entries
- [ ] Search and filter
- [ ] Export entries

---

### Phase 6: Settings & Configuration (MEDIUM PRIORITY) 🟡
**Status**: Basic profile screen exists
**Estimated Time**: 2-3 hours

#### Features to Add:
- [ ] Complete Personal Information editing
- [ ] Notification settings
- [ ] Dark mode toggle implementation
- [ ] Caregiver access setup
- [ ] Emergency contacts
- [ ] Data backup/export
- [ ] Privacy settings
- [ ] About page

---

### Phase 7: Notifications System (LOW PRIORITY) 🟢
**Status**: Not Started
**Estimated Time**: 3-4 hours

#### Features:
- [ ] Medication reminders
- [ ] Routine reminders
- [ ] Location alerts
- [ ] Custom reminders
- [ ] Notification history

**Dependencies**:
```yaml
flutter_local_notifications: ^16.0.0
```

---

### Phase 8: Location Services (MEDIUM PRIORITY) 🟡
**Status**: Not Started
**Estimated Time**: 3-4 hours

#### Features:
- [ ] Real-time location tracking
- [ ] Geofencing
- [ ] Safe zone alerts
- [ ] Location history
- [ ] Share location with caregivers

**Dependencies**:
```yaml
geolocator: ^10.1.0
google_maps_flutter: ^2.5.0
permission_handler: ^11.0.1
```

---

### Phase 9: Media & Files (LOW PRIORITY) 🟢
**Status**: Partially implemented in Drawing
**Estimated Time**: 2-3 hours

#### Features:
- [ ] Photo gallery for memories
- [ ] Audio recordings
- [ ] File management
- [ ] Cloud backup integration

**Dependencies**:
```yaml
image_picker: ^1.0.5  # Already added
audioplayers: ^5.2.1  # Already added  
record: ^5.0.4        # Already added
path_provider: ^2.1.1  # Already added
```

---

### Phase 10: Testing & Polish (HIGH PRIORITY) 🔴
**Status**: Ongoing
**Estimated Time**: Continuous

#### Testing Areas:
- [ ] Unit tests for services
- [ ] Widget tests for screens
- [ ] Integration tests for flows
- [ ] Accessibility testing
- [ ] Performance testing
- [ ] Error handling testing

---

## Priority Implementation Order

### Week 1: Core Foundation
1. ✅ Phase 1: Authentication (3-4 hrs)
2. ✅ Phase 2: Database Expansion (2-3 hrs)
3. ✅ Phase 4: Home Navigation (1-2 hrs)

### Week 2: Essential Features
4. Phase 3.2: Medications Screen (4-5 hrs)
5. Phase 3.3: Daily Routine Screen (4-5 hrs)
6. Phase 5: Memory Journal Enhancement (3-4 hrs)

### Week 3: Additional Features
7. Phase 3.4: Location Safety Screen (4-5 hrs)
8. Phase 3.5: Memory Games Screen (4-5 hrs)
9. Phase 8: Location Services (3-4 hrs)

### Week 4: Polish & Testing
10. Phase 6: Settings Completion (2-3 hrs)
11. Phase 7: Notifications (3-4 hrs)
12. Phase 10: Comprehensive Testing (Ongoing)

---

## Dependencies Summary

### Already Added ✅
```yaml
cupertino_icons: ^1.0.8
intl: ^0.19.0
sqflite: ^2.3.0
path: ^1.8.3
image_picker: ^1.0.5
audioplayers: ^5.2.1
record: ^5.0.4
path_provider: ^2.1.1
shared_preferences: ^2.2.2
http: ^1.2.0
flutter_markdown: ^0.7.4+1
permission_handler: ^11.0.1
```

### To Be Added 📋
```yaml
crypto: ^3.0.3  # Phase 1: Password hashing
flutter_local_notifications: ^16.0.0  # Phase 7: Notifications
geolocator: ^10.1.0  # Phase 8: Location
google_maps_flutter: ^2.5.0  # Phase 8: Maps
```

---

## Database Schema Status

### Existing Tables ✅
- `users` - User accounts
- `user_credentials` - Password hashes
- `journal_entries` - Memory journal

### To Be Created 📋
- `familiar_faces` - Contact management
- `medications` - Medicine tracking
- `daily_routines` - Schedule management
- `safety_locations` - Safe zones
- `game_progress` - Game statistics

---

## Current File Structure
```
lib/
├── main.dart ✅
├── models/
│   ├── user.dart ✅
│   ├── journal_entry.dart ✅
│   ├── chat_message.dart ✅
│   ├── face.dart 📋 (to create)
│   ├── medication.dart 📋 (to create)
│   ├── routine.dart 📋 (to create)
│   └── location.dart 📋 (to create)
├── screens/
│   ├── splash_screen.dart ✅
│   ├── main_navigation_screen.dart ✅
│   ├── home_screen.dart ✅
│   ├── connect_screen.dart ✅
│   ├── drawing_therapy_screen.dart ✅
│   ├── faces_screen.dart ⚠️ (needs completion)
│   ├── relax_screen.dart ⚠️ (needs completion)
│   ├── profile_screen.dart ⚠️ (needs completion)
│   ├── memory_screen.dart ✅ (basic)
│   ├── auth/
│   │   ├── welcome_screen.dart 📋
│   │   ├── login_screen.dart 📋
│   │   └── registration_screen.dart 📋
│   ├── medications_screen.dart 📋
│   ├── routine_screen.dart 📋
│   ├── location_safety_screen.dart 📋
│   └── games_screen.dart 📋
├── services/
│   ├── database_helper.dart ⚠️ (needs expansion)
│   ├── gemini_service.dart ✅
│   ├── settings_service.dart ✅
│   ├── journal_service.dart ✅
│   ├── auth_service.dart 📋
│   ├── notification_service.dart 📋
│   └── location_service.dart 📋
└── theme/
    └── app_theme.dart ✅
```

**Legend:**
- ✅ Complete
- ⚠️ Partially complete
- 📋 To be created

---

## Notes
- Each phase is independent and can be worked on separately
- Authentication (Phase 1) should be completed first as other features depend on user identity
- Database expansion (Phase 2) should be done early to support all features
- Testing should be continuous throughout development
- Documentation should be updated as features are added

---

**Last Updated**: December 11, 2024
**Status**: Ready to begin Phase 1 implementation
