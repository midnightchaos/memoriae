# Music & Journal Media Features - Implementation Guide

## Overview
Both Music Therapy and Journal features now support local media files:
- **Music**: Add local MP3/MP4/M4A files + voice recordings
- **Journal**: Add multiple photos + voice notes

## Implementation Status

### ✅ Already Implemented
1. **Models** - Support for media paths
2. **Journal Screen** - Full multi-photo + voice recording
3. **Music Service** - File picker + recording logic
4. **Database** - Storage for all media references

### 🔧 Need to Update
1. Music screen UI - Add buttons for local files/recording
2. Android permissions - Ensure all required

---

## Step 1: Update Music Therapy Screen

Replace `/lib/screens/music_therapy_screen.dart` with enhanced version that includes:
- "Add Local Music" button (file picker)
- "Record Audio" button
- Show user-added tracks separately from presets

### Key Changes Needed:

**Add at top of class:**
```dart
import '../services/music_library_service.dart';

final MusicLibraryService _musicService = MusicLibraryService();
List<MusicTrack> _customTracks = [];
```

**Load custom tracks in initState:**
```dart
@override
void initState() {
  super.initState();
  _loadCustomTracks();
  _setupAudioPlayer();
}

Future<void> _loadCustomTracks() async {
  final tracks = await _musicService.getAllTracks();
  setState(() {
    _customTracks = tracks.where((t) => t.type != 'asset').toList();
  });
}
```

**Add buttons in UI (after header):**
```dart
// Add Music Controls
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  child: Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _addLocalMusic,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add Music'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purple400,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _recordAudio,
          icon: Icon(_isRecordingMusic ? Icons.stop : Icons.mic),
          label: Text(_isRecordingMusic ? 'Stop' : 'Record'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRecordingMusic ? AppColors.coral400 : AppColors.emerald400,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    ],
  ),
),
```

**Add methods:**
```dart
bool _isRecordingMusic = false;

Future<void> _addLocalMusic() async {
  final track = await _musicService.pickAudioFile();
  if (track != null) {
    await _loadCustomTracks();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Added: ${track.name}'),
        backgroundColor: AppColors.emerald500,
      ),
    );
  }
}

Future<void> _recordAudio() async {
  if (_isRecordingMusic) {
    final track = await _musicService.stopRecording();
    setState(() => _isRecordingMusic = false);
    if (track != null) {
      await _loadCustomTracks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Recording saved: ${track.name}'),
          backgroundColor: AppColors.emerald500,
        ),
      );
    }
  } else {
    final started = await _musicService.startRecording();
    if (started) {
      setState(() => _isRecordingMusic = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎤 Recording...'),
          backgroundColor: AppColors.coral400,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Mic permission required'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }
  }
}
```

**Update track list to include custom tracks:**
```dart
// In ListView.builder
itemCount: _tracks.length + _customTracks.length,
itemBuilder: (context, index) {
  if (index < _tracks.length) {
    // Existing preset tracks
    final track = _tracks[index];
    // ... existing code
  } else {
    // Custom tracks
    final customIndex = index - _tracks.length;
    final track = _customTracks[customIndex];
    return _buildCustomTrackTile(track, isDark);
  }
}
```

**Custom track tile with delete:**
```dart
Widget _buildCustomTrackTile(MusicTrack track, bool isDark) {
  return Dismissible(
    key: Key(track.id),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppColors.coral400,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
    ),
    confirmDismiss: (direction) async {
      return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Track?'),
          content: Text('Remove "${track.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral400),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    },
    onDismissed: (direction) async {
      await _musicService.deleteTrack(track.id);
      await _loadCustomTracks();
    },
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _playCustomTrack(track),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slate800 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.slate700 : AppColors.slate200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(track.colorValue ?? 0xFF9333EA).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(track.icon ?? '🎵', style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.subtitle ?? 'Custom audio',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.slate400 : AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                track.type == 'recorded' ? Icons.mic : Icons.music_note,
                color: Color(track.colorValue ?? 0xFF9333EA),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _playCustomTrack(MusicTrack track) async {
  await _audioPlayer.stop();
  setState(() {
    _currentPlayingIndex = null; // Custom track not in main list
    _isPlaying = true;
  });
  
  try {
    await _audioPlayer.play(DeviceFileSource(track.filePath));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎵 Now Playing: ${track.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
    setState(() => _isPlaying = false);
  }
}
```

---

## Step 2: Android Permissions

Update `/android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Existing permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    
    <!-- Media Permissions -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    
    <!-- Storage Access (Android 13+) -->
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"
        tools:ignore="ScopedStorage"/>

    <application>
        <!-- ... existing config ... -->
    </application>
</manifest>
```

---

## Step 3: Testing Checklist

### Music Features
- [ ] Tap "Add Music" → select MP3/MP4 file
- [ ] File appears in custom tracks list
- [ ] Play custom track
- [ ] Tap "Record" → speak → tap "Stop"
- [ ] Recording appears in list with 🎙️ icon
- [ ] Swipe left on custom track → delete
- [ ] Custom tracks persist after app restart

### Journal Features (Already Working)
- [ ] Add entry → tap "Add Photos" → select multiple
- [ ] Images display in grid with X buttons
- [ ] Remove individual images
- [ ] Tap "Record Voice" → speak → stop
- [ ] Voice note shows with play/pause/delete
- [ ] Save entry → reopen → media intact

---

## Step 4: Quick Apply Script

Run this to update the music screen automatically:

```bash
# Backup current
cp lib/screens/music_therapy_screen.dart lib/screens/music_therapy_screen.backup.dart

# Apply changes (manual for now - see implementation above)
```

---

## File Structure Reference

```
lib/
├── models/
│   ├── journal_entry.dart       ✅ Has imagePaths + audioPath
│   └── music_track.dart          ✅ Has type field (local/recorded)
├── services/
│   ├── music_library_service.dart ✅ pickAudioFile() + recording
│   └── journal_service.dart       ✅ Saves media references
├── screens/
│   ├── add_edit_journal_screen.dart ✅ Multi-photo + voice
│   └── music_therapy_screen.dart    🔧 NEEDS: Add local file buttons
```

---

## Usage Examples

### Adding Local Music
1. Open Music Therapy
2. Tap "Add Music"
3. Select MP3/MP4 file from device
4. Track appears in list
5. Tap to play

### Recording Music/Voice Memo
1. Tap "Record" button (turns red)
2. Speak/play music near device
3. Tap "Stop"
4. Recording saved automatically
5. Play anytime

### Journal with Media
1. Create new journal entry
2. Tap "Add Photos" → select multiple
3. Tap mic button → record voice note
4. Photos grid + voice player appear
5. Save entry

---

## Troubleshooting

**"Permission denied" errors:**
- Check `AndroidManifest.xml` has all permissions
- On Android 13+: Manually grant storage permissions in Settings

**Audio files don't play:**
- Verify file format (MP3, MP4, M4A supported)
- Check file path is stored correctly in database
- Use `DeviceFileSource(path)` for local files

**Photos not appearing:**
- Ensure `image_picker` permission granted
- Images copied to app directory, not just referenced

---

## Next Steps

1. **Apply music screen changes** from Step 1
2. **Test on Android device** (permissions critical)
3. **Add iOS permissions** to `Info.plist` if needed:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>Take photos for journal entries</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>Record voice notes and audio</string>
   <key>NSPhotoLibraryUsageDescription</key>
   <string>Select photos for journal entries</string>
   ```

4. **Optional Enhancements:**
   - Edit track names after adding
   - Audio trimming/editing
   - Image compression settings
   - Cloud backup for media

---

## Dependencies Already Installed ✅

```yaml
# pubspec.yaml (already has these)
audioplayers: ^6.0.0       # Play audio
record: ^6.1.2             # Record audio
image_picker: ^1.1.1       # Pick/take photos
file_picker: ^8.1.4        # Pick audio files
permission_handler: ^12.0.1 # Request permissions
path_provider: ^2.1.2      # App directories
```

---

**Status: Ready to implement Step 1 music screen changes**
**Estimated Time: 30 minutes**
**Complexity: Medium** (UI changes + state management)
