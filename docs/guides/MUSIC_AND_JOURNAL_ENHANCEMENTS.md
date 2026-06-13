# Music and Journal Enhancements Implementation Guide

## Overview
This guide covers adding local MP4/audio file support to Music Therapy and voice recording + image upload to Journal entries.

## Features Being Added

### 1. Music Therapy Enhancements
- Import local MP4 and audio files (MP3, M4A, WAV)
- Play imported files in the app
- Manage custom music library
- Record audio directly in the app

### 2. Journal Entry Enhancements
- Record voice notes and attach to entries
- Upload/capture photos and attach to entries
- Play voice recordings within journal entries
- Display photos in journal entries

## Required Permissions (Android)

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    
    <application>
        ...
    </application>
</manifest>
```

## Implementation Steps

### Step 1: Update Models

The `JournalEntry` model already supports `imagePath` and `audioPath` - no changes needed!

### Step 2: Update Music Therapy Screen

Replace the existing `music_therapy_screen.dart` with the enhanced version that includes:
- File picker for importing audio files
- Audio recorder integration
- Custom tracks management
- Support for MP4, MP3, M4A, WAV formats

### Step 3: Update Journal Entry Screen

The journal entry screen already has placeholder buttons for photos and voice recording. We'll implement:
- Image picker (camera + gallery)
- Audio recorder
- Media preview and playback

### Step 4: Test Features

1. **Music Therapy:**
   - Tap "Import Audio" button
   - Select MP3/MP4/M4A files from device
   - Play imported tracks
   - Record new audio clips

2. **Journal Entry:**
   - Create new journal entry
   - Tap "Add Photo" - select from gallery or camera
   - Tap "Record" - record voice note
   - Save entry and verify media is attached
   - View entry and play voice recording

## File Structure

```
lib/
├── screens/
│   ├── music_therapy_screen.dart (ENHANCED)
│   └── memory_screen.dart (ENHANCED)
├── services/
│   ├── audio_service.dart (NEW)
│   └── media_service.dart (NEW)
└── widgets/
    ├── audio_player_widget.dart (NEW)
    └── image_preview_widget.dart (NEW)
```

## Dependencies Already Installed

All required dependencies are already in `pubspec.yaml`:
- ✅ `audioplayers: ^6.0.0`
- ✅ `record: ^6.1.2`
- ✅ `image_picker: ^1.1.1`
- ✅ `file_selector: ^1.0.3`
- ✅ `permission_handler: ^12.0.1`
- ✅ `path_provider: ^2.1.2`

## Next Steps

Run the following files I'm creating:
1. `enhanced_music_therapy_screen.dart`
2. `enhanced_memory_screen.dart`
3. `audio_service.dart`
4. `media_service.dart`

Then replace the existing files and test!
