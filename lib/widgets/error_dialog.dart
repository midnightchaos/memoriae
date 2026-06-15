import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? retryText;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryText = 'Retry',
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onRetry,
    String? retryText,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        onRetry: onRetry,
        retryText: retryText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    return AlertDialog(
      backgroundColor: isBlackMinimalism ? const Color(0xFF1A1A1A) : null,
      title: Text(
        title,
        style: TextStyle(color: isBlackMinimalism ? Colors.white : null),
      ),
      content: Text(
        message,
        style: TextStyle(color: isBlackMinimalism ? Colors.white70 : null),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'OK',
            style: TextStyle(color: isBlackMinimalism ? Colors.white : null),
          ),
        ),
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: Text(
              retryText!,
              style: TextStyle(color: isBlackMinimalism ? Colors.white : null),
            ),
          ),
      ],
    );
  }
}

extension ErrorDialogExtension on BuildContext {
  void showError({
    required String title,
    required String message,
    VoidCallback? onRetry,
    String? retryText,
  }) {
    ErrorDialog.show(
      context: this,
      title: title,
      message: message,
      onRetry: onRetry,
      retryText: retryText,
    );
  }
}
