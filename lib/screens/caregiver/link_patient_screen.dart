import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/database_helper.dart';
import '../../models/caregiver.dart';
import 'caregiver_dashboard_screen.dart';
import '../../services/audit_logging_service.dart';

class LinkPatientScreen extends StatefulWidget {
  final Caregiver caregiver;
  const LinkPatientScreen({super.key, required this.caregiver});

  @override
  State<LinkPatientScreen> createState() => _LinkPatientScreenState();
}

class _LinkPatientScreenState extends State<LinkPatientScreen> {
  final _patientIdController = TextEditingController();
  bool _isLoading = false;

  Future<void> _link() async {
    final patientId = _patientIdController.text.trim();
    if (patientId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // In this local simulation, we link by setting the caregiver ID on the user record
      final db = await DatabaseHelper.instance.database;

      // Update the user profile with the linked caregiver ID
      final count = await db.update(
        'users',
        {'linkedCaregiverId': widget.caregiver.id},
        where: 'id = ?',
        whereArgs: [patientId],
      );

      if (count == 0) {
        throw Exception(
          'Patient ID not found. Please double-check the ID in the Patient\'s Profile tab.',
        );
      }

      // Log audit action
      await AuditLoggingService.instance.logAction(
        action: 'Linked Patient',
        details:
            'Caregiver ${widget.caregiver.name} linked to patient $patientId',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Patient linked successfully!'),
            backgroundColor: AppColors.emerald500,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CaregiverDashboardScreen(caregiver: widget.caregiver),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.coral400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link Patient')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Link to Patient Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter the unique ID of the patient you wish to monitor.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slate600),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _patientIdController,
              decoration: const InputDecoration(
                labelText: 'Patient ID',
                prefixIcon: Icon(Icons.vpn_key_outlined),
                border: OutlineInputBorder(),
                hintText: 'e.g. user_123',
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _link,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.blue500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Link Account', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // For demo purposes, we can show the current user ID if available
                _showDemoNote();
              },
              child: const Text('Where can I find the Patient ID?'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDemoNote() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demo Note'),
        content: const Text(
          'In this application, the Patient ID is usually the ID generated when you first set up the profile. You can find it in the "You" tab of the patient interface.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
