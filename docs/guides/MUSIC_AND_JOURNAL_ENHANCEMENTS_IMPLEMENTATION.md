# Music & Journal Enhancements Implementation Guide

## Overview
This guide implements two major features:
1. **Music Therapy**: Add local MP4/audio files and recordings
2. **Memory Journal**: Add voice recordings and image uploads

## Features to Implement

### 1. Music Therapy Enhancements
- ✅ Upload local MP4/audio files from device
- ✅ Record audio directly in the app
- ✅ Play uploaded/recorded audio files
- ✅ Manage custom music library
- ✅ Delete custom tracks

### 2. Memory Journal Enhancements
- ✅ Record voice notes for journal entries
- ✅ Upload/capture images for journal entries
- ✅ Play back voice recordings in journal
- ✅ View full-size images
- ✅ Support multiple images per entry

## Implementation Steps

### Phase 1: Update Models

#### 1.1 Create Music Track Model
File: `lib/models/music_track.dart`

```dart
class MusicTrack {
  final String id;
  final String name;
  final String filePath;
  final String type; // 'asset', 'local', 'recorded'
  final DateTime dateAdded;
  final Duration? duration;
  final String? subtitle;
  final String? icon;
  final int? colorValue;

  MusicTrack({
    required this.id,
    required this.name,
    required this.filePath,
    required this.type,
    required this.dateAdded,
    this.duration,
    this.subtitle,
    this.icon,
    this.colorValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'type': type,
      'dateAdded': dateAdded.toIso8601String(),
      'duration': duration?.inSeconds,
      'subtitle': subtitle,
      'icon': icon,
      'colorValue': colorValue,
    };
  }

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: json['id'] as String,
      name: json['name'] as String,
      filePath: json['filePath'] as String,
      type: json['type'] as String,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      duration: json['duration'] != null 
          ? Duration(seconds: json['duration'] as int)
          : null,
      subtitle: json['subtitle'] as String?,
      icon: json['icon'] as String?,
      colorValue: json['colorValue'] as int?,
    );
  }
}
```

#### 1.2 Update Journal Entry Model
The model already supports `imagePath` and `audioPath`, but we'll enhance it to support multiple images.

Update: `lib/models/journal_entry.dart`
- Change `imagePath` to `imagePaths` (List<String>)
- Keep `audioPath` for single voice recording

### Phase 2: Create Services

#### 2.1 Music Library Service
File: `lib/services/music_library_service.dart`

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import '../models/music_track.dart';
import 'database_helper.dart';

class MusicLibraryService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final AudioRecorder _recorder = AudioRecorder();
  
  static const List<String> _supportedAudioFormats = [
    'mp3', 'mp4', 'm4a', 'wav', 'aac', 'ogg'
  ];

  // Get all tracks (assets + custom)
  Future<List<MusicTrack>> getAllTracks() async {
    return await _db.getAllMusicTracks();
  }

  // Pick audio file from device
  Future<MusicTrack?> pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _supportedAudioFormats,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        
        // Copy to app directory
        final appDir = await getApplicationDocumentsDirectory();
        final musicDir = Directory('${appDir.path}/music');
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final newPath = '${musicDir.path}/$timestamp\_$fileName';
        final copiedFile = await file.copy(newPath);
        
        final track = MusicTrack(
          id: timestamp.toString(),
          name: fileName.split('.').first,
          filePath: copiedFile.path,
          type: 'local',
          dateAdded: DateTime.now(),
          subtitle: 'Custom music',
          icon: '🎵',
          colorValue: 0xFF9333EA, // purple
        );
        
        await _db.createMusicTrack(track);
        return track;
      }
    } catch (e) {
      print('Error picking audio file: $e');
    }
    return null;
  }

  // Start recording
  Future<bool> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final appDir = await getApplicationDocumentsDirectory();
        final recordingsDir = Directory('${appDir.path}/recordings');
        if (!await recordingsDir.exists()) {
          await recordingsDir.create(recursive: true);
        }
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = '${recordingsDir.path}/recording_$timestamp.m4a';
        
        await _recorder.start(const RecordConfig(), path: path);
        return true;
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
    return false;
  }

  // Stop recording and save
  Future<MusicTrack?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      
      if (path != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final track = MusicTrack(
          id: timestamp.toString(),
          name: 'Recording ${DateTime.now().toString().substring(0, 16)}',
          filePath: path,
          type: 'recorded',
          dateAdded: DateTime.now(),
          subtitle: 'Voice recording',
          icon: '🎙️',
          colorValue: 0xFFEC4899, // pink
        );
        
        await _db.createMusicTrack(track);
        return track;
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
    return null;
  }

  // Delete track
  Future<void> deleteTrack(String trackId) async {
    final track = await _db.getMusicTrack(trackId);
    if (track != null && track.type != 'asset') {
      // Delete file
      final file = File(track.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _db.deleteMusicTrack(trackId);
  }

  // Check if recording
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  void dispose() {
    _recorder.dispose();
  }
}
```

#### 2.2 Update Database Helper
Add to: `lib/services/database_helper.dart`

Add these methods to DatabaseHelper:

```dart
// Music Tracks Table
Future<void> _createMusicTracksTable(Database db) async {
  await db.execute('''
    CREATE TABLE music_tracks(
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      filePath TEXT NOT NULL,
      type TEXT NOT NULL,
      dateAdded TEXT NOT NULL,
      duration INTEGER,
      subtitle TEXT,
      icon TEXT,
      colorValue INTEGER
    )
  ''');
}

// CRUD for Music Tracks
Future<void> createMusicTrack(MusicTrack track) async {
  final db = await database;
  await db.insert('music_tracks', track.toJson());
}

Future<List<MusicTrack>> getAllMusicTracks() async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query('music_tracks');
  return List.generate(maps.length, (i) => MusicTrack.fromJson(maps[i]));
}

Future<MusicTrack?> getMusicTrack(String id) async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    'music_tracks',
    where: 'id = ?',
    whereArgs: [id],
  );
  if (maps.isNotEmpty) {
    return MusicTrack.fromJson(maps.first);
  }
  return null;
}

Future<void> deleteMusicTrack(String id) async {
  final db = await database;
  await db.delete('music_tracks', where: 'id = ?', whereArgs: [id]);
}
```

#### 2.3 Enhanced Journal Service
Update: `lib/services/journal_service.dart`

Add methods for handling voice recordings:

```dart
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class JournalService {
  final AudioRecorder _recorder = AudioRecorder();
  
  // ... existing methods ...

  // Start voice recording
  Future<bool> startVoiceRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final appDir = await getApplicationDocumentsDirectory();
        final voiceDir = Directory('${appDir.path}/journal_voice');
        if (!await voiceDir.exists()) {
          await voiceDir.create(recursive: true);
        }
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = '${voiceDir.path}/voice_$timestamp.m4a';
        
        await _recorder.start(const RecordConfig(), path: path);
        return true;
      }
    } catch (e) {
      print('Error starting voice recording: $e');
    }
    return false;
  }

  // Stop voice recording
  Future<String?> stopVoiceRecording() async {
    try {
      final path = await _recorder.stop();
      return path;
    } catch (e) {
      print('Error stopping voice recording: $e');
    }
    return null;
  }

  // Check if recording
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  // Delete voice recording file
  Future<void> deleteVoiceRecording(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting voice recording: $e');
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}
```

### Phase 3: Update UI Screens

#### 3.1 Enhanced Music Therapy Screen
Update: `lib/screens/music_therapy_screen_enhanced.dart`

This will be the new enhanced version with:
- Local file uploads
- Recording functionality
- Custom track management

#### 3.2 Enhanced Memory Journal Screen
Update: `lib/screens/memory_screen_enhanced.dart`

Add:
- Voice recording button
- Image picker with multiple selection
- Audio playback in entries
- Image gallery view

### Phase 4: Update Dependencies

Update `pubspec.yaml` to include:

```yaml
dependencies:
  # Existing...
  
  # File Picker
  file_picker: ^8.1.4  # For selecting audio files
  
  # The rest are already included:
  # record: ^6.1.2
  # audioplayers: ^6.0.0
  # image_picker: ^1.1.1
  # path_provider: ^2.1.2
  # permission_handler: ^12.0.1
```

### Phase 5: Permissions Setup

#### Android Permissions
Update `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Audio Recording -->
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>

<!-- Storage -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" android:minSdkVersion="33"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" android:minSdkVersion="33"/>

<!-- Camera (optional if you want to take photos) -->
<uses-permission android:name="android.permission.CAMERA"/>
```

## Testing Checklist

### Music Therapy
- [ ] Upload MP3 file from device
- [ ] Upload MP4/M4A file from device
- [ ] Start audio recording
- [ ] Stop audio recording
- [ ] Play uploaded file
- [ ] Play recorded audio
- [ ] Delete custom track
- [ ] Play asset tracks (original functionality)

### Memory Journal
- [ ] Add photo from gallery
- [ ] Take photo with camera
- [ ] Add multiple photos
- [ ] Record voice note
- [ ] Play voice note in entry
- [ ] View full-size images
- [ ] Delete image from entry
- [ ] Delete voice recording

## File Structure

```
lib/
├── models/
│   ├── journal_entry.dart (updated)
│   └── music_track.dart (new)
├── services/
│   ├── journal_service.dart (updated)
│   ├── music_library_service.dart (new)
│   └── database_helper.dart (updated)
└── screens/
    ├── music_therapy_screen_enhanced.dart (new)
    └── memory_screen_enhanced.dart (new)
```

## Notes

1. **File Storage**: All user files stored in app documents directory
2. **Permissions**: Request at runtime when needed
3. **File Formats**: Support MP3, MP4, M4A, WAV, AAC, OGG
4. **Database**: SQLite for metadata, filesystem for actual files
5. **Cleanup**: Delete files when entries/tracks are deleted

## Next Steps

1. Create the model files
2. Implement services
3. Create enhanced UI screens
4. Add permissions
5. Test thoroughly on Android device
6. Handle edge cases and errors

Would you like me to start implementing these files?
