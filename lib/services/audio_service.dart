import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static const String _customTracksKey = 'custom_audio_tracks';

  /// Save an audio file to the app's documents directory
  Future<String> saveAudioFile(File sourceFile, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${directory.path}/audio');

    // Create audio directory if it doesn't exist
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    // Create unique filename if it already exists
    String finalFileName = fileName;
    int counter = 1;
    while (await File('${audioDir.path}/$finalFileName').exists()) {
      final nameWithoutExt = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
      final ext = fileName.split('.').last;
      finalFileName = '${nameWithoutExt}_$counter.$ext';
      counter++;
    }

    final targetPath = '${audioDir.path}/$finalFileName';
    await sourceFile.copy(targetPath);
    return targetPath;
  }

  /// Load saved custom tracks from SharedPreferences
  Future<List<Map<String, dynamic>>> loadCustomTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tracksJson = prefs.getString(_customTracksKey);

      if (tracksJson == null) return [];

      final List<dynamic> tracksList = jsonDecode(tracksJson);
      final tracks = tracksList
          .map((track) => Map<String, dynamic>.from(track))
          .toList();

      // Filter out tracks whose files no longer exist
      final validTracks = <Map<String, dynamic>>[];
      for (final track in tracks) {
        final file = File(track['file'] as String);
        if (await file.exists()) {
          validTracks.add(track);
        }
      }

      // Save back the filtered list if any tracks were removed
      if (validTracks.length != tracks.length) {
        await saveCustomTracks(validTracks);
      }

      return validTracks;
    } catch (e) {
      return [];
    }
  }

  /// Save custom tracks to SharedPreferences
  Future<void> saveCustomTracks(List<Map<String, dynamic>> tracks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tracksJson = jsonEncode(tracks);
      await prefs.setString(_customTracksKey, tracksJson);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Delete an audio file and remove it from saved tracks
  Future<void> deleteAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from saved tracks
      final tracks = await loadCustomTracks();
      tracks.removeWhere((track) => track['file'] == filePath);
      await saveCustomTracks(tracks);
    } catch (e) {
      // Ignore deletion errors
    }
  }

  /// Get the duration of an audio file (if possible)
  Future<Duration?> getAudioDuration(String filePath) async {
    // This would require additional audio processing libraries
    // For now, return null as a placeholder
    return null;
  }

  /// Clear all custom tracks
  Future<void> clearAllCustomTracks() async {
    try {
      // Delete all audio files
      final tracks = await loadCustomTracks();
      for (final track in tracks) {
        final file = File(track['file'] as String);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Clear from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_customTracksKey);
    } catch (e) {
      // Ignore errors
    }
  }
}
