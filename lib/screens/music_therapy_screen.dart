import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/database_helper.dart';
import '../models/safety_location.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../services/activity_monitoring_service.dart';
import '../services/music_library_service.dart';
import '../models/music_track.dart';

class MusicTherapyScreen extends StatefulWidget {
  const MusicTherapyScreen({super.key});

  @override
  State<MusicTherapyScreen> createState() => _MusicTherapyScreenState();
}

class _MusicTherapyScreenState extends State<MusicTherapyScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final MusicLibraryService _musicService = MusicLibraryService();
  bool _isPlaying = false;
  int? _currentPlayingIndex;
  MusicTrack? _currentCustomTrack;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 0.7;
  bool _isRecordingMusic = false;
  List<MusicTrack> _customTracks = [];

  final List<Map<String, dynamic>> _tracks = [
    {
      'name': 'For P',
      'subtitle': 'Peaceful melody',
      'file': 'for-p-453681.mp3',
      'icon': '🎵',
      'color': AppColors.lavender400,
    },
    {
      'name': 'Future Design',
      'subtitle': 'Modern ambient',
      'file': 'future-design-344320.mp3',
      'icon': '✨',
      'color': AppColors.teal400,
    },
    {
      'name': 'Groovy Vibe',
      'subtitle': 'Uplifting rhythm',
      'file': 'groovy-vibe-427121.mp3',
      'icon': '🎼',
      'color': AppColors.purple400,
    },
    {
      'name': 'Hype Drill Music',
      'subtitle': 'Energetic beats',
      'file': 'hype-drill-music-438398.mp3',
      'icon': '🔥',
      'color': AppColors.rose400,
    },
    {
      'name': 'Sweet Life Luxury Chill',
      'subtitle': 'Relaxing vibes',
      'file': 'sweet-life-luxury-chill-438146.mp3',
      'icon': '💫',
      'color': AppColors.blue400,
    },
    {
      'name': 'Vlog Beat Background',
      'subtitle': 'Smooth background',
      'file': 'vlog-beat-background-349853.mp3',
      'icon': '🎹',
      'color': AppColors.emerald400,
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    _loadCustomTracks();

    // Record interaction on screen open
    ActivityMonitoringService.instance.recordInteraction();
  }

  Future<void> _loadCustomTracks() async {
    final tracks = await _musicService.getAllTracks();
    setState(() {
      _customTracks = tracks.where((t) => t.type != 'asset').toList();
    });
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _position = position);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
      _playNextTrack();
    });

    _audioPlayer.setVolume(_volume);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _musicService.dispose();
    super.dispose();
  }

  Future<void> _addLocalMusic() async {
    final track = await _musicService.pickAudioFile();
    if (track != null) {
      await _loadCustomTracks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Added: ${track.name}'),
            backgroundColor: AppColors.emerald500,
          ),
        );
      }
    }
  }

  Future<void> _recordAudio() async {
    if (_isRecordingMusic) {
      final track = await _musicService.stopRecording();
      setState(() => _isRecordingMusic = false);
      if (track != null) {
        await _loadCustomTracks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Recording saved: ${track.name}'),
              backgroundColor: AppColors.emerald500,
            ),
          );
        }
      }
    } else {
      final started = await _musicService.startRecording();
      if (started) {
        setState(() => _isRecordingMusic = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎤 Recording...'),
              backgroundColor: AppColors.coral400,
            ),
          );
        }
      } else {
        if (mounted) {
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
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  Future<void> _playTrack(int trackIndex) async {
    final track = _tracks[trackIndex];

    await _audioPlayer.stop();

    setState(() {
      _currentPlayingIndex = trackIndex;
      _currentCustomTrack = null;
      _isPlaying = true;
      _position = Duration.zero;
    });

    try {
      await _audioPlayer.play(AssetSource('audio/${track['file']}'));
      
      // Log activity
      ActivityMonitoringService.instance.logActivity(
        type: ActivityMonitoringService.TYPE_THERAPY,
        description: 'Patient started playing music track: ${track['name']}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎵 Now Playing: ${track['name']}'),
            duration: const Duration(seconds: 2),
            backgroundColor: track['color'],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error playing audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isPlaying = false;
        _currentPlayingIndex = null;
      });
    }
  }

  Future<void> _playCustomTrack(MusicTrack track) async {
    await _audioPlayer.stop();
    setState(() {
      _currentPlayingIndex = null;
      _currentCustomTrack = track;
      _isPlaying = true;
    });
    
    try {
      await _audioPlayer.play(DeviceFileSource(track.filePath));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎵 Now Playing: ${track.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isPlaying = false);
    }
  }

  void _playNextTrack() {
    if (_currentPlayingIndex == null) return;
    
    if (_currentPlayingIndex! + 1 < _tracks.length) {
      _playTrack(_currentPlayingIndex! + 1);
    } else {
      _playTrack(0);
    }
  }

  void _playPreviousTrack() {
    if (_currentPlayingIndex == null) return;
    
    if (_currentPlayingIndex! - 1 >= 0) {
      _playTrack(_currentPlayingIndex! - 1);
    } else {
      _playTrack(_tracks.length - 1);
    }
  }

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _position = Duration.zero;
      _currentPlayingIndex = null;
      _currentCustomTrack = null;
    });
  }

  String _getCurrentTrackName() {
    if (_currentCustomTrack != null) return _currentCustomTrack!.name;
    if (_currentPlayingIndex == null) return 'No track selected';
    return _tracks[_currentPlayingIndex!]['name'];
  }

  String _getCurrentTrackSubtitle() {
    if (_currentCustomTrack != null) return _currentCustomTrack!.subtitle ?? 'Custom audio';
    if (_currentPlayingIndex == null) return 'Select a track to play';
    return _tracks[_currentPlayingIndex!]['subtitle'];
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isBlackMinimalism = themeService.themeMode == AppThemeMode.blackMinimalism;
    final isDark = themeService.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isBlackMinimalism
                ? [Colors.black, const Color(0xFF0A0A0A), Colors.black]
                : (isDark
                    ? [AppColors.slate900, AppColors.slate800, AppColors.slate900]
                    : [AppColors.lavender50, AppColors.blue50, AppColors.mint50]),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Text(
                      'Music Therapy',
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: isBlackMinimalism ? Colors.white : null,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Mood Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildMoodChip('🧘 Relax', AppColors.teal400, isBlackMinimalism),
                      const SizedBox(width: 8),
                      _buildMoodChip('☀️ Energetic', AppColors.rose400, isBlackMinimalism),
                      const SizedBox(width: 8),
                      _buildMoodChip('🌙 Sleep', AppColors.blue500, isBlackMinimalism),
                      const SizedBox(width: 8),
                      _buildMoodChip('🧠 Focus', AppColors.blue400, isBlackMinimalism),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              _buildNowPlayingCard(isDark, isBlackMinimalism),

              const SizedBox(height: 12),

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
                          backgroundColor: isBlackMinimalism ? Colors.white : AppColors.purple400,
                          foregroundColor: isBlackMinimalism ? Colors.black : Colors.white,
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
                          backgroundColor: _isRecordingMusic 
                              ? AppColors.coral400 
                              : (isBlackMinimalism ? Colors.white : AppColors.emerald400),
                          foregroundColor: _isRecordingMusic 
                              ? Colors.white 
                              : (isBlackMinimalism ? Colors.black : Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _tracks.length + _customTracks.length,
                  itemBuilder: (context, index) {
                    if (index < _tracks.length) {
                      final track = _tracks[index];
                      final isCurrentlyPlaying = _currentPlayingIndex == index;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTrackTile(
                          track: track,
                          index: index,
                          isPlaying: isCurrentlyPlaying,
                          onTap: () => _playTrack(index),
                          isDark: isDark,
                          isBlackMinimalism: isBlackMinimalism,
                        ),
                      );
                    } else {
                      final customIndex = index - _tracks.length;
                      final track = _customTracks[customIndex];
                      return _buildCustomTrackTile(track, isDark, isBlackMinimalism);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTrackTile(MusicTrack track, bool isDark, bool isBlackMinimalism) {
    final isPlaying = _currentCustomTrack?.id == track.id;
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
            backgroundColor: isBlackMinimalism ? const Color(0xFF1A1A1A) : null,
            title: Text('Delete Track?', style: TextStyle(color: isBlackMinimalism ? Colors.white : null)),
          content: Text('Remove "${track.name}"?', style: TextStyle(color: isBlackMinimalism ? Colors.white70 : null)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: isBlackMinimalism ? Colors.white70 : null)),
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
              gradient: isPlaying
                  ? LinearGradient(
                      colors: [Color(track.colorValue ?? 0xFF9333EA).withOpacity(0.3), 
                               Color(track.colorValue ?? 0xFF9333EA).withOpacity(0.1)],
                    )
                  : null,
              color: isPlaying ? null : (isBlackMinimalism ? const Color(0xFF0A0A0A) : (isDark ? AppColors.slate800 : Colors.white)),
              borderRadius: BorderRadius.circular(16),
              border: isPlaying 
                  ? Border.all(color: Color(track.colorValue ?? 0xFF9333EA), width: 2)
                  : Border.all(
                      color: isBlackMinimalism ? Colors.white10 : (isDark ? AppColors.slate700 : AppColors.slate200),
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
                        style: TextStyle(
                          fontSize: 17, 
                          fontWeight: FontWeight.bold,
                          color: isBlackMinimalism ? Colors.white : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track.subtitle ?? 'Custom audio',
                        style: TextStyle(
                          fontSize: 13,
                          color: isBlackMinimalism ? Colors.white38 : (isDark ? AppColors.slate400 : AppColors.slate600),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(track.colorValue ?? 0xFF9333EA).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.equalizer : (track.type == 'recorded' ? Icons.mic : Icons.music_note),
                    color: Color(track.colorValue ?? 0xFF9333EA),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNowPlayingCard(bool isDark, bool isBlackMinimalism) {
    final currentTrack = _currentPlayingIndex != null 
        ? _tracks[_currentPlayingIndex!] 
        : null;

    if (_currentPlayingIndex == null && _currentCustomTrack == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: currentTrack != null 
              ? [currentTrack['color'], (currentTrack['color'] as Color).withOpacity(0.7)]
              : [AppColors.lavender400, AppColors.purple400],
        ),
        borderRadius: BorderRadius.circular(24),
        border: isBlackMinimalism ? Border.all(color: Colors.white10) : null,
        boxShadow: isBlackMinimalism ? null : [
          BoxShadow(
            color: (currentTrack?['color'] ?? AppColors.lavender400).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    currentTrack?['icon'] ?? (_currentCustomTrack?.icon ?? '🎵'),
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCurrentTrackName(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCurrentTrackSubtitle(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          SliderTheme(
            data: SliderThemeData(
              thumbColor: Colors.white,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: _position.inSeconds.toDouble(),
              max: _duration.inSeconds.toDouble() > 0
                  ? _duration.inSeconds.toDouble()
                  : 100,
              onChanged: (value) async {
                await _audioPlayer.seek(Duration(seconds: value.toInt()));
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  _volume > 0 ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white,
                ),
                iconSize: 28,
                onPressed: () {
                  setState(() {
                    _volume = _volume > 0 ? 0 : 0.7;
                    _audioPlayer.setVolume(_volume);
                  });
                },
              ),

              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white),
                iconSize: 36,
                onPressed: _currentPlayingIndex != null ? _playPreviousTrack : null,
              ),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: currentTrack?['color'] ?? AppColors.lavender400,
                  ),
                  iconSize: 40,
                  onPressed: (_currentPlayingIndex != null || _currentCustomTrack != null) ? _playPause : null,
                ),
              ),

              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                iconSize: 36,
                onPressed: _currentPlayingIndex != null ? _playNextTrack : null,
              ),

              IconButton(
                icon: const Icon(Icons.stop, color: Colors.white),
                iconSize: 28,
                onPressed: (_currentPlayingIndex != null || _currentCustomTrack != null) ? _stopPlayback : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTile({
    required Map<String, dynamic> track,
    required int index,
    required bool isPlaying,
    required VoidCallback onTap,
    required bool isDark,
    required bool isBlackMinimalism,
  }) {
    final color = track['color'] as Color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isPlaying
              ? LinearGradient(
                  colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                )
              : null,
          color: isPlaying
              ? null
              : (isBlackMinimalism ? const Color(0xFF0A0A0A) : (isDark ? AppColors.slate800 : Colors.white)),
          borderRadius: BorderRadius.circular(16),
          border: isPlaying 
              ? Border.all(color: color, width: 2) 
              : Border.all(
                  color: isBlackMinimalism ? Colors.white10 : (isDark ? AppColors.slate700 : AppColors.slate200),
                  width: 1,
                ),
          boxShadow: isBlackMinimalism ? null : [
            BoxShadow(
              color: (isPlaying ? color : Colors.black).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  track['icon'],
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track['name'],
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isPlaying ? color : (isBlackMinimalism ? Colors.white : null),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track['subtitle'],
                    style: TextStyle(
                      fontSize: 13,
                      color: isBlackMinimalism ? Colors.white38 : (isDark ? AppColors.slate400 : AppColors.slate600),
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.equalizer : Icons.play_arrow,
                color: color,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodChip(String label, Color color, bool isBlackMinimalism) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isBlackMinimalism ? Colors.white.withOpacity(0.05) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBlackMinimalism ? Colors.white10 : color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isBlackMinimalism ? Colors.white70 : color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
