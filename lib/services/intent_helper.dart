import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:developer' as developer;

/// Centralized helper for safely launching external app intents
/// with proper validation and user-friendly error handling
class IntentHelper {
  /// Check if a package is installed on the device
  /// Returns true if installed, false otherwise
  static Future<bool> isPackageInstalled(String packageName) async {
    try {
      if (Platform.isAndroid) {
        // For Android, we check if the URL scheme can be launched
        final testUrl = _getTestUrlForPackage(packageName);
        if (testUrl != null) {
          return await canLaunchUrl(testUrl);
        }
      }
      return false;
    } catch (e) {
      developer.log('Error checking package: $packageName - $e', 
        name: 'IntentHelper',
        error: e
      );
      return false;
    }
  }

  /// Get test URL for package detection
  static Uri? _getTestUrlForPackage(String packageName) {
    switch (packageName) {
      case 'com.whatsapp':
        return Uri.parse('whatsapp://send');
      case 'com.google.android.gm':
        return Uri.parse('mailto:');
      default:
        return null;
    }
  }

  /// Launch WhatsApp with pre-filled text
  /// Shows user-friendly error if WhatsApp is not installed
  static Future<bool> launchWhatsApp(
    BuildContext context, 
    String message, {
    String? phoneNumber,
  }) async {
    try {
      // Build WhatsApp URL
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = phoneNumber != null
          ? Uri.parse('whatsapp://send?phone=$phoneNumber&text=$encodedMessage')
          : Uri.parse('whatsapp://send?text=$encodedMessage');

      developer.log('Attempting to launch WhatsApp...', name: 'IntentHelper');

      // Check if WhatsApp is installed
      final canLaunch = await canLaunchUrl(whatsappUrl);
      
      if (!canLaunch) {
        if (context.mounted) {
          _showAppNotInstalledDialog(
            context,
            'WhatsApp',
            'WhatsApp is not installed on your device.',
            _getPlayStoreUrl('com.whatsapp'),
          );
        }
        return false;
      }

      // Launch WhatsApp
      final launched = await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        _showLaunchFailedDialog(context, 'WhatsApp');
      }

      return launched;
    } catch (e) {
      developer.log('WhatsApp launch error: $e', 
        name: 'IntentHelper',
        error: e,
        stackTrace: StackTrace.current
      );
      
      if (context.mounted) {
        _showLaunchErrorDialog(context, 'WhatsApp', e.toString());
      }
      return false;
    }
  }

  /// Launch Gmail/Email client with pre-filled content
  /// Shows user-friendly error if no email client is available
  static Future<bool> launchEmail(
    BuildContext context, {
    String? recipient,
    String? subject,
    String? body,
  }) async {
    try {
      // Build mailto URL
      final params = <String, String>{};
      if (subject != null) params['subject'] = subject;
      if (body != null) params['body'] = body;

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final emailUrl = Uri.parse(
        recipient != null 
            ? 'mailto:$recipient${queryString.isNotEmpty ? '?$queryString' : ''}'
            : 'mailto:${queryString.isNotEmpty ? '?$queryString' : ''}'
      );

      developer.log('Attempting to launch email client...', name: 'IntentHelper');

      // Check if email client is available
      final canLaunch = await canLaunchUrl(emailUrl);
      
      if (!canLaunch) {
        if (context.mounted) {
          _showEmailClientMissingDialog(context);
        }
        return false;
      }

      // Launch email client
      final launched = await launchUrl(
        emailUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        _showLaunchFailedDialog(context, 'Email');
      }

      return launched;
    } catch (e) {
      developer.log('Email launch error: $e', 
        name: 'IntentHelper',
        error: e,
        stackTrace: StackTrace.current
      );
      
      if (context.mounted) {
        _showLaunchErrorDialog(context, 'Email', e.toString());
      }
      return false;
    }
  }

  /// Launch SMS with pre-filled message
  static Future<bool> launchSms(
    BuildContext context, 
    String message, {
    String? phoneNumber,
  }) async {
    try {
      final smsUrl = phoneNumber != null
          ? Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}')
          : Uri.parse('sms:?body=${Uri.encodeComponent(message)}');

      developer.log('Attempting to launch SMS...', name: 'IntentHelper');

      final canLaunch = await canLaunchUrl(smsUrl);
      
      if (!canLaunch) {
        if (context.mounted) {
          _showSimpleError(context, 'SMS is not available on this device');
        }
        return false;
      }

      final launched = await launchUrl(
        smsUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        _showLaunchFailedDialog(context, 'SMS');
      }

      return launched;
    } catch (e) {
      developer.log('SMS launch error: $e', 
        name: 'IntentHelper',
        error: e,
        stackTrace: StackTrace.current
      );
      
      if (context.mounted) {
        _showLaunchErrorDialog(context, 'SMS', e.toString());
      }
      return false;
    }
  }

  /// Get Play Store URL for a package
  static String _getPlayStoreUrl(String packageName) {
    return 'https://play.google.com/store/apps/details?id=$packageName';
  }

  /// Show dialog when app is not installed
  static void _showAppNotInstalledDialog(
    BuildContext context,
    String appName,
    String message,
    String storeUrl,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Text('$appName Not Found'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final url = Uri.parse(storeUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Install'),
          ),
        ],
      ),
    );
  }

  /// Show dialog when launch fails
  static void _showLaunchFailedDialog(BuildContext context, String appName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Text('Unable to Open'),
          ],
        ),
        content: Text(
          'Could not open $appName. The app may be installed but encountered an error.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show dialog for email client missing
  static void _showEmailClientMissingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email_outlined, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('No Email Client'),
          ],
        ),
        content: const Text(
          'No email client is available on your device. Please install Gmail or another email app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final url = Uri.parse(_getPlayStoreUrl('com.google.android.gm'));
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Install Gmail'),
          ),
        ],
      ),
    );
  }

  /// Show dialog with detailed error
  static void _showLaunchErrorDialog(
    BuildContext context,
    String appName,
    String error,
  ) {
    // Simplify error message for user
    String userMessage = 'An unexpected error occurred while trying to open $appName.';
    
    if (error.contains('ActivityNotFoundException')) {
      userMessage = '$appName is not installed or not configured correctly.';
    } else if (error.contains('SecurityException')) {
      userMessage = 'Permission denied to open $appName.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(userMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show simple error snackbar
  static void _showSimpleError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show sharing options dialog
  static Future<String?> showShareMethodDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Share Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.message, color: Colors.green, size: 32),
              title: const Text('WhatsApp'),
              subtitle: const Text('Share via WhatsApp'),
              onTap: () => Navigator.pop(context, 'whatsapp'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.red, size: 32),
              title: const Text('Email'),
              subtitle: const Text('Share via email client'),
              onTap: () => Navigator.pop(context, 'email'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.message_outlined, color: Colors.blue, size: 32),
              title: const Text('SMS'),
              subtitle: const Text('Share via text message'),
              onTap: () => Navigator.pop(context, 'sms'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.purple, size: 32),
              title: const Text('Other'),
              subtitle: const Text('Use system share menu'),
              onTap: () => Navigator.pop(context, 'other'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
