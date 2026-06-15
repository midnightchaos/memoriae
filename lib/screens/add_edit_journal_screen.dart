import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../services/activity_monitoring_service.dart';
import '../models/journal_entry.dart';

/// Add/Edit Journal Entry with multi-image & voice support
class AddEditJournalScreenV2 extends StatefulWidget {
  final JournalEntry? entry;

  const AddEditJournalScreenV2({super.key, this.entry});

  @override
  State<AddEditJournalScreenV2> createState() => _AddEditJournalScreenV2State();
}

class _AddEditJournalScreenV2State extends State<AddEditJournalScreenV2> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagController;

  String _selectedMood = '😊';
  List<String> _tags = [];
  String? _imagePath;
  List<String> _imagesPaths = [];
  String? _audioPath;

  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPlayingAudio = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  final List<String> _moods = ['😊', '😔', '😌', '😄', '😴', '🤔', '😍', '😎'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(
      text: widget.entry?.content ?? '',
    );
    _tagController = TextEditingController();
    _selectedMood = widget.entry?.mood ?? '😊';
    _tags = List.from(widget.entry?.tags ?? []);
    _imagePath = widget.entry?.imagePath;
    _imagesPaths = List.from(widget.entry?.imagesPaths ?? []);
    _audioPath = widget.entry?.audioPath;

    _setupAudioPlayer();

    // Record interaction on screen open
    ActivityMonitoringService.instance.recordInteraction();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen(
      (d) => setState(() => _audioDuration = d),
    );
    _audioPlayer.onPositionChanged.listen(
      (p) => setState(() => _audioPosition = p),
    );
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlayingAudio = false;
        _audioPosition = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickMultipleImages() async {
    try {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        _showPermissionError('Photo library access required');
        return;
      }

      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
      );
      if (images.isEmpty) return;

      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/journal_images');
      await imagesDir.create(recursive: true);

      for (var img in images) {
        final fileName =
            'img_${DateTime.now().millisecondsSinceEpoch}_${_imagesPaths.length}.jpg';
        final targetPath = '${imagesDir.path}/$fileName';
        await File(img.path).copy(targetPath);
        _imagesPaths.add(targetPath);
      }

      setState(() {});
      _showSuccess('${images.length} photo(s) added!');
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _showPermissionError('Camera access required');
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/journal_images');
      await imagesDir.create(recursive: true);

      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetPath = '${imagesDir.path}/$fileName';
      await File(image.path).copy(targetPath);

      setState(() => _imagesPaths.add(targetPath));
      _showSuccess('Photo added!');
    } catch (e) {
      _showError('Failed to take photo: $e');
    }
  }

  void _removeImageAtIndex(int index) {
    setState(() => _imagesPaths.removeAt(index));
  }

  Future<void> _startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _showPermissionError('Microphone access required');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/temp_rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: tempPath);
      setState(() => _isRecording = true);
      _showSuccess('🎤 Recording...');
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null) {
        final directory = await getApplicationDocumentsDirectory();
        final audioDir = Directory('${directory.path}/journal_audio');
        await audioDir.create(recursive: true);

        final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final targetPath = '${audioDir.path}/$fileName';
        await File(path).copy(targetPath);

        setState(() => _audioPath = targetPath);
        _showSuccess('Voice recording saved!');
      }
    } catch (e) {
      setState(() => _isRecording = false);
      _showError('Failed to stop recording: $e');
    }
  }

  Future<void> _playPauseAudio() async {
    if (_audioPath == null) return;

    try {
      if (_isPlayingAudio) {
        await _audioPlayer.pause();
      } else {
        if (_audioPosition.inSeconds == 0) {
          await _audioPlayer.play(DeviceFileSource(_audioPath!));
        } else {
          await _audioPlayer.resume();
        }
      }
      setState(() => _isPlayingAudio = !_isPlayingAudio);
    } catch (e) {
      _showError('Failed to play audio: $e');
    }
  }

  Future<void> _deleteAudio() async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isBlackMinimalism ? const Color(0xFF1A1A1A) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete Recording?',
          style: TextStyle(color: isBlackMinimalism ? Colors.white : null),
        ),
        content: Text(
          'Permanently delete this voice recording?',
          style: TextStyle(color: isBlackMinimalism ? Colors.white70 : null),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isBlackMinimalism ? Colors.white70 : null,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral400,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (_audioPath != null) {
          final file = File(_audioPath!);
          if (await file.exists()) await file.delete();
        }
        setState(() {
          _audioPath = null;
          _isPlayingAudio = false;
          _audioPosition = Duration.zero;
        });
        await _audioPlayer.stop();
      } catch (e) {}
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  void _saveEntry() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Please enter a title');
      return;
    }

    // Log activity
    ActivityMonitoringService.instance.logActivity(
      type: ActivityMonitoringService.TYPE_JOURNAL,
      description: 'Patient created/updated a journal entry: $title',
    );

    final entry = JournalEntry(
      id: widget.entry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: _contentController.text.trim(),
      date: widget.entry?.date ?? DateTime.now(),
      imagePath: _imagePath,
      imagesPaths: _imagesPaths,
      audioPath: _audioPath,
      tags: _tags,
      mood: _selectedMood,
    );

    Navigator.pop(context, entry);
  }

  void _showError(String msg) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.coral400),
      );
  }

  void _showSuccess(String msg) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.emerald500),
      );
  }

  void _showPermissionError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $msg'),
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

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeService = context.watch<ThemeService>();
    final isDark = theme.brightness == Brightness.dark;
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'New Entry' : 'Edit Entry'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveEntry),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isBlackMinimalism
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [AppColors.slate900, AppColors.slate800]
                      : [AppColors.lavender50, AppColors.blue50],
                ),
          color: isBlackMinimalism ? Colors.black : null,
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMoodSelector(isDark, isBlackMinimalism),
            const SizedBox(height: 16),
            _buildTitleField(isDark, isBlackMinimalism),
            const SizedBox(height: 16),
            _buildContentField(isDark, isBlackMinimalism),
            const SizedBox(height: 16),
            _buildMultipleImagesSection(isDark, isBlackMinimalism),
            const SizedBox(height: 16),
            _buildAudioSection(isDark, isBlackMinimalism),
            const SizedBox(height: 16),
            _buildTagsSection(isDark, isBlackMinimalism),
            const SizedBox(height: 16),
            _buildMediaButtons(isDark, isBlackMinimalism),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector(bool isDark, bool isBlackMinimalism) {
    return Container(
      decoration: BoxDecoration(
        color: isBlackMinimalism
            ? const Color(0xFF0A0A0A)
            : (isDark ? AppColors.slate800 : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: isBlackMinimalism ? Border.all(color: Colors.white10) : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isBlackMinimalism ? Colors.white : null,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _moods.map((mood) {
              final isSelected = mood == _selectedMood;
              return InkWell(
                onTap: () => setState(() => _selectedMood = mood),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isBlackMinimalism
                              ? Colors.white24
                              : AppColors.lavender100)
                        : (isBlackMinimalism
                              ? Colors.white10
                              : AppColors.slate50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? (isBlackMinimalism
                                ? Colors.white70
                                : AppColors.lavender500)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(mood, style: const TextStyle(fontSize: 32)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField(bool isDark, bool isBlackMinimalism) {
    return Container(
      decoration: BoxDecoration(
        color: isBlackMinimalism
            ? const Color(0xFF0A0A0A)
            : (isDark ? AppColors.slate800 : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: isBlackMinimalism ? Border.all(color: Colors.white10) : null,
      ),
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: 'Title',
          labelStyle: TextStyle(
            color: isBlackMinimalism ? Colors.white70 : null,
          ),
          hintText: 'Give your memory a title...',
          hintStyle: TextStyle(
            color: isBlackMinimalism ? Colors.white24 : null,
          ),
          border: InputBorder.none,
        ),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isBlackMinimalism ? Colors.white : null,
        ),
      ),
    );
  }

  Widget _buildContentField(bool isDark, bool isBlackMinimalism) {
    return Container(
      decoration: BoxDecoration(
        color: isBlackMinimalism
            ? const Color(0xFF0A0A0A)
            : (isDark ? AppColors.slate800 : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: isBlackMinimalism ? Border.all(color: Colors.white10) : null,
      ),
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _contentController,
        decoration: InputDecoration(
          labelText: 'What happened today?',
          labelStyle: TextStyle(
            color: isBlackMinimalism ? Colors.white70 : null,
          ),
          hintText: 'Write your thoughts...',
          hintStyle: TextStyle(
            color: isBlackMinimalism ? Colors.white24 : null,
          ),
          border: InputBorder.none,
        ),
        maxLines: 10,
        style: TextStyle(
          fontSize: 16,
          color: isBlackMinimalism ? Colors.white : null,
        ),
      ),
    );
  }

  Widget _buildMultipleImagesSection(bool isDark, bool isBlackMinimalism) {
    if (_imagesPaths.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: isBlackMinimalism
            ? const Color(0xFF0A0A0A)
            : (isDark ? AppColors.slate800 : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: isBlackMinimalism ? Border.all(color: Colors.white10) : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library,
                color: isBlackMinimalism ? Colors.white70 : AppColors.blue500,
              ),
              const SizedBox(width: 8),
              Text(
                'Photos (${_imagesPaths.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isBlackMinimalism ? Colors.white : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _imagesPaths.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_imagesPaths[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(28, 28),
                      ),
                      onPressed: () => _removeImageAtIndex(index),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAudioSection(bool isDark, bool isBlackMinimalism) {
    if (_audioPath == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: isBlackMinimalism
            ? const Color(0xFF0A0A0A)
            : (isDark ? AppColors.slate800 : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: isBlackMinimalism ? Border.all(color: Colors.white10) : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic,
                color: isBlackMinimalism ? Colors.white70 : AppColors.coral400,
              ),
              const SizedBox(width: 8),
              Text(
                'Voice Recording',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isBlackMinimalism ? Colors.white : null,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: isBlackMinimalism
                      ? Colors.white70
                      : AppColors.coral400,
                ),
                onPressed: _deleteAudio,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isPlayingAudio ? Icons.pause_circle : Icons.play_circle,
                  size: 48,
                  color: isBlackMinimalism ? Colors.white : AppColors.coral400,
                ),
                onPressed: _playPauseAudio,
              ),
              Expanded(
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: isBlackMinimalism
                            ? Colors.white
                            : AppColors.coral400,
                        inactiveTrackColor: isBlackMinimalism
                            ? Colors.white24
                            : AppColors.coral100,
                        thumbColor: isBlackMinimalism
                            ? Colors.white
                            : AppColors.coral400,
                        trackHeight: 2,
                      ),
                      child: Slider(
                        value: _audioPosition.inSeconds.toDouble(),
                        max: _audioDuration.inSeconds > 0
                            ? _audioDuration.inSeconds.toDouble()
                            : 100,
                        onChanged: (v) async => await _audioPlayer.seek(
                          Duration(seconds: v.toInt()),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_audioPosition),
                            style: TextStyle(
                              fontSize: 12,
                              color: isBlackMinimalism
                                  ? Colors.white60
                                  : AppColors.slate600,
                            ),
                          ),
                          Text(
                            _formatDuration(_audioDuration),
                            style: TextStyle(
                              fontSize: 12,
                              color: isBlackMinimalism
                                  ? Colors.white60
                                  : AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(bool isDark, bool isBlackMinimalism) {
    return Container(
      decoration: BoxDecoration(
        color: isBlackMinimalism
            ? const Color(0xFF0A0A0A)
            : (isDark ? AppColors.slate800 : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: isBlackMinimalism ? Border.all(color: Colors.white10) : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isBlackMinimalism ? Colors.white : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    hintText: 'Add a tag...',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    enabledBorder: isBlackMinimalism
                        ? const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          )
                        : null,
                    hintStyle: TextStyle(
                      color: isBlackMinimalism ? Colors.white38 : null,
                    ),
                  ),
                  style: TextStyle(
                    color: isBlackMinimalism ? Colors.white70 : null,
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addTag,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBlackMinimalism
                      ? Colors.white24
                      : AppColors.lavender500,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeTag(tag),
                      backgroundColor: isBlackMinimalism
                          ? Colors.white12
                          : AppColors.mint100,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaButtons(bool isDark, bool isBlackMinimalism) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _pickMultipleImages,
            icon: const Icon(Icons.photo_library),
            label: const Text('Add Photos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlackMinimalism
                  ? Colors.white24
                  : AppColors.blue400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _takePhoto,
          style: ElevatedButton.styleFrom(
            backgroundColor: isBlackMinimalism
                ? Colors.white24
                : AppColors.emerald400,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Icon(Icons.camera_alt, size: 28),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isRecording ? _stopRecording : _startRecording,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRecording
                ? AppColors.coral400
                : (isBlackMinimalism ? Colors.white : AppColors.purple400),
            foregroundColor: _isRecording || !isBlackMinimalism
                ? Colors.white
                : Colors.black,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Icon(_isRecording ? Icons.stop : Icons.mic, size: 28),
        ),
      ],
    );
  }
}
