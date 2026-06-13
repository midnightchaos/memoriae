import 'package:flutter/material.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../models/familiar_face.dart';

class FamiliarFaceCard extends StatelessWidget {
  final FamiliarFace face;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const FamiliarFaceCard({
    super.key,
    required this.face,
    required this.onTap,
    required this.onDelete,
  });

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendMessage(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      child: ListTile(
        onTap: onTap,
        leading: _buildAvatar(),
        title: Text(
          face.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          face.relation,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              onDelete();
            } else if (value == 'call' && face.phoneNumber != null) {
              _makeCall(face.phoneNumber!);
            } else if (value == 'message' && face.phoneNumber != null) {
              _sendMessage(face.phoneNumber!);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            if (face.phoneNumber != null) ...[
              const PopupMenuItem<String>(
                value: 'call',
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 20),
                    SizedBox(width: 8),
                    Text('Call'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'message',
                child: Row(
                  children: [
                    Icon(Icons.message, size: 20),
                    SizedBox(width: 8),
                    Text('Message'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
            ],
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return ClipOval(
      child: face.photoPath != null
          ? Image.file(
              File(face.photoPath!),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
            )
          : Container(
              width: 80,
              height: 80,
              color: Colors.grey[300],
              child: const Icon(Icons.person, size: 40, color: Colors.grey),
            ),
    );
  }
}
