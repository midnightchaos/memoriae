import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:record/record.dart';

class MediaPickerService {
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();

  // Pick multiple images
  Future<List<String>?> pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isEmpty) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${appDir.path}/journal_images');
      await imageDir.create(recursive: true);

      List<String> savedPaths = [];
      for (var img in images) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(img.path)}';
        final savePath = '${imageDir.path}/$fileName';
        await File(img.path).copy(savePath);
        savedPaths.add(savePath);
      }
      return savedPaths;
    } catch (e) {
      return null;
    }
  }

  // Pick audio/music files (mp3, m4a, mp4 audio)
  Future<String?> pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'mp4', 'wav', 'aac'],
      );
      
      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.single.path!);
      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${appDir.path}/music_files');
      await audioDir.create(recursive: true);

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final savePath = '${audioDir.path}/$fileName';
      await file.copy(savePath);
      
      return savePath;
    } catch (e) {
      return null;
    }
  }

  // Record audio
  Future<String?> recordAudio() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${appDir.path}/recordings');
      await audioDir.create(recursive: true);

      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final savePath = '${audioDir.path}/$fileName';

      if (await _recorder.hasPermission()) {
        await _recorder.start(const RecordConfig(), path: savePath);
        return savePath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> stopRecording() async {
    await _recorder.stop();
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  void dispose() {
    _recorder.dispose();
  }
}
