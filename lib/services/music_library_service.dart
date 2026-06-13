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
    'mp3', 'mp4', 'm4a', 'wav', 'aac', 'ogg', 'flac', 'wma'
  ];

  // Get all tracks (assets + custom)
  Future<List<MusicTrack>> getAllTracks() async {
    try {
      return await _db.getAllMusicTracks();
    } catch (e) {
      print('Error getting all tracks: $e');
      return [];
    }
  }

  // Get tracks by type
  Future<List<MusicTrack>> getTracksByType(String type) async {
    try {
      final allTracks = await getAllTracks();
      return allTracks.where((track) => track.type == type).toList();
    } catch (e) {
      print('Error getting tracks by type: $e');
      return [];
    }
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
        final sanitizedFileName = fileName.replaceAll(RegExp(r'[^\w\s.-]'), '_');
        final newPath = '${musicDir.path}/${timestamp}_$sanitizedFileName';
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
        final recordingsDir = Directory('${appDir.path}/music_recordings');
        if (!await recordingsDir.exists()) {
          await recordingsDir.create(recursive: true);
        }
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = '${recordingsDir.path}/recording_$timestamp.m4a';
        
        await _recorder.start(const RecordConfig(), path: path);
        return true;
      } else {
        print('No recording permission');
        return false;
      }
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  // Stop recording and save
  Future<MusicTrack?> stopRecording({String? customName}) async {
    try {
      final path = await _recorder.stop();
      
      if (path != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final defaultName = 'Recording ${DateTime.now().toString().substring(0, 16)}';
        
        final track = MusicTrack(
          id: timestamp.toString(),
          name: customName ?? defaultName,
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

  // Cancel recording
  Future<void> cancelRecording() async {
    try {
      final path = await _recorder.stop();
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Error canceling recording: $e');
    }
  }

  // Update track name
  Future<void> updateTrackName(String trackId, String newName) async {
    try {
      final track = await _db.getMusicTrack(trackId);
      if (track != null) {
        final updatedTrack = track.copyWith(name: newName);
        await _db.updateMusicTrack(updatedTrack);
      }
    } catch (e) {
      print('Error updating track name: $e');
    }
  }

  // Delete track
  Future<void> deleteTrack(String trackId) async {
    try {
      final track = await _db.getMusicTrack(trackId);
      if (track != null && track.type != 'asset') {
        // Delete file from filesystem
        final file = File(track.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      // Delete from database
      await _db.deleteMusicTrack(trackId);
    } catch (e) {
      print('Error deleting track: $e');
    }
  }

  // Check if recording
  Future<bool> isRecording() async {
    try {
      return await _recorder.isRecording();
    } catch (e) {
      return false;
    }
  }

  // Get track by ID
  Future<MusicTrack?> getTrack(String id) async {
    try {
      return await _db.getMusicTrack(id);
    } catch (e) {
      print('Error getting track: $e');
      return null;
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}
