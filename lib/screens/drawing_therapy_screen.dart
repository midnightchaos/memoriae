import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../services/activity_monitoring_service.dart';

class DrawingTherapyScreen extends StatefulWidget {
  const DrawingTherapyScreen({super.key});

  @override
  State<DrawingTherapyScreen> createState() => _DrawingTherapyScreenState();
}

class _DrawingTherapyScreenState extends State<DrawingTherapyScreen> {
  final List<DrawingPoint> _points = [];
  Color _selectedColor = Colors.purple;
  final GlobalKey _canvasKey = GlobalKey();
  bool _isSaving = false;

  final List<Color> colors = [
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    // Record interaction on screen open
    ActivityMonitoringService.instance.recordInteraction();
  }

  Future<void> _saveDrawing() async {
    if (_points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to save! Draw something first.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Create image from canvas
      final boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      // Save to device
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/drawing_$timestamp.png';
      final file = File(path);
      await file.writeAsBytes(buffer);

      // Log activity
      ActivityMonitoringService.instance.logActivity(
        type: ActivityMonitoringService.TYPE_THERAPY,
        description: 'Patient saved a drawing therapy session',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Drawing saved successfully!'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => _showGalleryDialog(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _shareDrawing() async {
    if (_points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to share! Draw something first.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Create image from canvas
      final boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      // Save to temp directory
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/drawing_$timestamp.png';
      final file = File(path);
      await file.writeAsBytes(buffer);

      // Log activity
      ActivityMonitoringService.instance.logActivity(
        type: ActivityMonitoringService.TYPE_THERAPY,
        description: 'Patient shared a drawing therapy session',
      );

      // Share the file
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Check out my drawing from Drawing Therapy!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _showGalleryDialog() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory
        .listSync()
        .where((f) => f.path.endsWith('.png') && f.path.contains('drawing_'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path)); // Most recent first

    if (!mounted) return;

    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved drawings yet!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saved Drawings'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = File(files[index].path);
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showImagePreview(file);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      file,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(File file) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(file),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await Share.shareXFiles([XFile(file.path)]);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await file.delete();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Drawing deleted')),
                      );
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                    : [AppColors.cream50, AppColors.lavender50, AppColors.mint50]),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    const Spacer(),
                    Text(
                      'Drawing Therapy',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isBlackMinimalism ? Colors.white : null,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.photo_library, size: 28),
                      onPressed: _showGalleryDialog,
                      tooltip: 'View Gallery',
                    ),
                  ],
                ),
              ),

              // Drawing Prompt
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isBlackMinimalism ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isBlackMinimalism ? Colors.white10 : AppColors.lavender200),
                  ),
                  child: Row(
                    children: [
                      const Text('🎨', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Therapy Suggestion:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isBlackMinimalism ? Colors.white38 : AppColors.lavender500,
                              ),
                            ),
                            const Text(
                              'Draw something that makes you feel happy today.',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () {
                          // In a real app, this would cycle through prompts
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: RepaintBoundary(
                    key: _canvasKey,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isBlackMinimalism ? const Color(0xFFE0E0E0) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: isBlackMinimalism 
                                ? Colors.black.withOpacity(0.5) 
                                : AppColors.lavender400.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              _points.add(DrawingPoint(
                                details.localPosition,
                                _selectedColor,
                              ));
                            });
                          },
                          onPanEnd: (details) {
                            setState(() {
                              _points.add(DrawingPoint(null, _selectedColor));
                            });
                          },
                          child: CustomPaint(
                            painter: DrawingPainter(_points),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Color Palette
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: colors.map((color) {
                    final isSelected = color == _selectedColor;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: isSelected ? 56 : 48,
                        height: isSelected ? 56 : 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? (isBlackMinimalism ? Colors.white : Colors.white) : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: isSelected ? 12 : 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveDrawing,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isBlackMinimalism ? Colors.white : AppColors.lavender500,
                          foregroundColor: isBlackMinimalism ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Save'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _shareDrawing,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: isBlackMinimalism ? const BorderSide(color: Colors.white24) : null,
                          foregroundColor: isBlackMinimalism ? Colors.white : null,
                        ),
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 28),
                      onPressed: () {
                        if (_points.isEmpty) return;
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear Canvas'),
                            content: const Text('Are you sure you want to clear your drawing?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() => _points.clear());
                                  Navigator.pop(context);
                                },
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        );
                      },
                      tooltip: 'Clear Canvas',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawingPoint {
  final Offset? offset;
  final Color color;

  DrawingPoint(this.offset, this.color);
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].offset != null && points[i + 1].offset != null) {
        final paint = Paint()
          ..color = points[i].color
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(points[i].offset!, points[i + 1].offset!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
