import 'dart:io';
import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import 'package:provider/provider.dart';

class RoundedImagePicker extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onImagePicked;
  final double radius;
  final Color borderColor;
  final double borderWidth;

  const RoundedImagePicker({
    super.key,
    this.imagePath,
    required this.onImagePicked,
    this.radius = 50.0,
    this.borderColor = const Color(0xFF9E9E9E),
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isBlackMinimalism = themeService.themeMode == AppThemeMode.blackMinimalism;
    final defaultBorderColor = isBlackMinimalism ? Colors.white24 : Colors.grey;

    return GestureDetector(
      onTap: onImagePicked,
      child: Stack(
        children: [
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor ?? defaultBorderColor,
                width: borderWidth,
              ),
              boxShadow: isBlackMinimalism
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ClipOval(
              child: _buildImage(isBlackMinimalism),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isBlackMinimalism ? Colors.white : Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isBlackMinimalism ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 16,
                color: isBlackMinimalism ? Colors.black : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(bool isBlackMinimalism) {
    if (imagePath != null && File(imagePath!).existsSync()) {
      return Image.file(
        File(imagePath!),
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(isBlackMinimalism),
      );
    }
    return _buildPlaceholder(isBlackMinimalism);
  }

  Widget _buildPlaceholder(bool isBlackMinimalism) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: isBlackMinimalism ? const Color(0xFF1A1A1A) : Colors.grey[200],
      child: Icon(
        Icons.person,
        size: radius,
        color: isBlackMinimalism ? Colors.white10 : Colors.grey[400],
      ),
    );
  }
}
