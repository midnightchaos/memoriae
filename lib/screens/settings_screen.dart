import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/theme_extensions.dart';
import '../services/theme_service.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/medication_notification_service.dart';
import '../services/daily_routine_notification_service.dart';
import '../services/alert_service.dart';
import '../services/gemini_service.dart';
import '../widgets/animated_page_wrapper.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'about_screen.dart';
import 'caregiver/caregiver_register_screen.dart';
import 'caregiver/caregiver_dashboard_screen.dart';
import 'main_navigation_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _medicationReminders = true;
  bool _dailyRoutineReminders = true;
  bool _biometricAuth = false;
  String _selectedLanguage = 'English';
  double _textSize = 1.0;
  late final GeminiService _geminiService;

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final profileService = context.watch<ProfileService>();
    final pageStyle = Theme.of(context).extension<AppPageStyle>()!;
    final patientId = profileService.profile?.id ?? 'Not set';

    return Scaffold(
      body: AnimatedPageWrapper(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: pageStyle.sectionHeaderColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                children: [
                  // Caregiver Section
                  const SectionHeader(title: 'Caregiver & Monitoring', icon: Icons.family_restroom_rounded),
                  const SizedBox(height: AppSpacing.md),
                  _buildActionTile(
                    title: 'Caregiver Portal',
                    subtitle: 'Access monitoring and alerts',
                    icon: Icons.hub_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CaregiverRegisterScreen()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: pageStyle.iconBackgroundColor.withOpacity(0.5),
                        borderRadius: AppRadius.sm,
                      ),
                      child: Text(
                        'Your Patient ID: $patientId',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: pageStyle.subtitleColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Demo Section
                  const SectionHeader(title: 'Demo Mode', icon: Icons.developer_mode_rounded),
                  const SizedBox(height: AppSpacing.md),
                  _buildActionTile(
                    title: 'Switch Role',
                    subtitle: 'Toggle to ${AuthService.instance.currentRole == UserRole.patient ? 'Caregiver' : 'Patient'} View',
                    icon: Icons.swap_horizontal_circle_rounded,
                    onTap: _handleRoleSwitch,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Test Notifications Section
                  const SectionHeader(title: 'Test Notifications', icon: Icons.notifications_active_rounded),
                  const SizedBox(height: AppSpacing.md),
                  _buildActionTile(
                    title: 'Medication Reminder',
                    subtitle: 'Trigger a real medication notification',
                    icon: Icons.medication_rounded,
                    onTap: () => _fireTestNotification('medication'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildActionTile(
                    title: 'Daily Routine',
                    subtitle: 'Trigger a routine notification',
                    icon: Icons.schedule_rounded,
                    onTap: () => _fireTestNotification('routine'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildActionTile(
                    title: 'Caregiver Alert',
                    subtitle: 'Trigger an inactivity alert',
                    icon: Icons.warning_amber_rounded,
                    onTap: () => _fireTestNotification('alert'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildActionTile(
                    title: 'Custom Notification',
                    subtitle: 'Send arbitrary notification',
                    icon: Icons.notification_important_rounded,
                    onTap: () => _fireTestNotification('custom'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildActionTile(
                    title: 'Pending List',
                    subtitle: 'List all scheduled tasks',
                    icon: Icons.list_alt_rounded,
                    onTap: _showPendingNotifications,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Appearance Section
                  const SectionHeader(title: 'Appearance', icon: Icons.palette_rounded),
                  const SizedBox(height: AppSpacing.md),
                  _buildActionTile(
                    title: 'App Theme',
                    subtitle: _getThemeLabel(themeService.themeMode),
                    icon: Icons.brush_rounded,
                    onTap: () => _showThemeDialog(themeService),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildActionTile(
                    title: 'Text Size',
                    subtitle: _getTextSizeLabel(),
                    icon: Icons.format_size_rounded,
                    onTap: _showTextSizeDialog,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildActionTile(
                    title: 'Language',
                    subtitle: _selectedLanguage,
                    icon: Icons.language_rounded,
                    onTap: _showLanguageDialog,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Notifications Logic Section
                  const SectionHeader(title: 'Preferences', icon: Icons.settings_suggest_rounded),
                  const SizedBox(height: AppSpacing.md),
                  _buildSwitchTile(
                    title: 'Master Notifications',
                    subtitle: 'Receive all app alerts',
                    icon: Icons.notifications_rounded,
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSwitchTile(
                    title: 'Medication Alerts',
                    subtitle: 'Specific medicine reminders',
                    icon: Icons.medical_information_rounded,
                    value: _medicationReminders,
                    enabled: _notificationsEnabled,
                    onChanged: (v) => setState(() => _medicationReminders = v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSwitchTile(
                    title: 'Routine Alerts',
                    subtitle: 'Daily schedule prompts',
                    icon: Icons.event_repeat_rounded,
                    value: _dailyRoutineReminders,
                    enabled: _notificationsEnabled,
                    onChanged: (v) => setState(() => _dailyRoutineReminders = v),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Security Section
                  const SectionHeader(title: 'Security', icon: Icons.security_rounded),
                  const SizedBox(height: AppSpacing.md),
                  _buildSwitchTile(
                    title: 'Biometrics',
                    subtitle: 'Fingerprint or Face ID',
                    icon: Icons.fingerprint_rounded,
                    value: _biometricAuth,
                    onChanged: (v) => setState(() => _biometricAuth = v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildActionTile(
                    title: 'Update PIN',
                    subtitle: 'Change access code',
                    icon: Icons.lock_rounded,
                    onTap: _showChangePinDialog,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Data Section
                  const SectionHeader(title: 'Data & Backup', icon: Icons.storage_rounded),
                  const SizedBox(height: AppSpacing.md),
                  _buildActionTile(title: 'Cloud Backup', subtitle: 'Sync to server', icon: Icons.cloud_upload_rounded, onTap: () {}),
                  const SizedBox(height: AppSpacing.sm),
                  _buildActionTile(title: 'Export JSON', subtitle: 'Download data', icon: Icons.download_rounded, onTap: _exportData),
                  const SizedBox(height: AppSpacing.sm),
                  _buildActionTile(title: 'Clear Cache', subtitle: 'Free up space', icon: Icons.delete_sweep_rounded, onTap: () {}, isDestructive: true),
                  const SizedBox(height: AppSpacing.xl),

                  // API Section
                  const SectionHeader(title: 'Menta AI', icon: Icons.auto_awesome_rounded),
                  const SizedBox(height: AppSpacing.md),
                  _buildActionTile(
                    title: 'Gemini API Key',
                    subtitle: _geminiKeyStatus(),
                    icon: Icons.api_rounded,
                    onTap: _showApiKeyDialog,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // About Section
                  const SectionHeader(title: 'Information', icon: Icons.info_rounded),
                  const SizedBox(height: AppSpacing.md),
                  _buildActionTile(
                    title: 'About Memoriae',
                    subtitle: 'Our mission & team',
                    icon: Icons.favorite_rounded,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildActionTile(title: 'Privacy Policy', subtitle: 'Terms & usage', icon: Icons.privacy_tip_rounded, onTap: () {}),
                  const SizedBox(height: AppSpacing.xl),

                  // Logout
                  _buildActionTile(
                    title: 'Sign Out',
                    subtitle: 'Exit your account',
                    icon: Icons.logout_rounded,
                    onTap: () async {
                      await AuthService.instance.logout();
                      if (mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      }
                    },
                    isDestructive: true,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final pageStyle = Theme.of(context).extension<AppPageStyle>()!;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDestructive 
                  ? AppColors.coral500.withOpacity(0.1) 
                  : pageStyle.iconBackgroundColor,
              borderRadius: AppRadius.md,
            ),
            child: Icon(
              icon,
              color: isDestructive ? AppColors.coral500 : pageStyle.iconAccentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? AppColors.coral500 : pageStyle.sectionHeaderColor,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: pageStyle.subtitleColor,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: pageStyle.subtitleColor.withOpacity(0.3),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    final pageStyle = Theme.of(context).extension<AppPageStyle>()!;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: pageStyle.iconBackgroundColor,
                borderRadius: AppRadius.md,
              ),
              child: Icon(
                icon,
                color: pageStyle.iconAccentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: pageStyle.sectionHeaderColor,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: pageStyle.subtitleColor,
                        ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: AppColors.lavender500,
            ),
          ],
        ),
      ),
    );
  }

  // --- Logic Helpers ---

  Future<void> _handleRoleSwitch() async {
    final auth = AuthService.instance;
    final newRole = auth.currentRole == UserRole.patient ? UserRole.caregiver : UserRole.patient;
    await auth.switchRole(newRole);
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => newRole == UserRole.patient ? const MainNavigationScreen() : const CaregiverDashboardScreen()),
        (route) => false,
      );
    }
  }

  String _geminiKeyStatus() {
    final key = _geminiService.apiKey;
    return (key != null && key.isNotEmpty) ? 'Key Configured ✓' : 'Tap to set API Key';
  }

  String _getTextSizeLabel() {
    if (_textSize < 0.9) return 'Small';
    if (_textSize > 1.1) return 'Large';
    return 'Medium';
  }

  String _getThemeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light: return 'Light Calm';
      case AppThemeMode.dark: return 'Deep Slate';
      case AppThemeMode.blackMinimalism: return 'Black Minimalism';
    }
  }

  // --- Dialogs (Restored & Styled) ---

  void _showThemeDialog(ThemeService themeService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SectionHeader(title: 'Choose Theme', icon: Icons.palette_rounded),
            const SizedBox(height: AppSpacing.md),
            ...AppThemeMode.values.map((mode) => ListTile(
              title: Text(_getThemeLabel(mode)),
              leading: Radio<AppThemeMode>(
                value: mode,
                groupValue: themeService.themeMode,
                onChanged: (v) {
                  if (v != null) {
                    themeService.setTheme(v);
                    Navigator.pop(context);
                  }
                },
              ),
              onTap: () => themeService.setTheme(mode),
            )),
          ],
        ),
      ),
    );
  }

  void _showTextSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xl),
        title: const Text('Text Size'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sample Text Appearance', style: TextStyle(fontSize: 16 * _textSize)),
              Slider(
                value: _textSize,
                min: 0.8, max: 1.4, divisions: 6,
                activeColor: AppColors.lavender500,
                onChanged: (v) {
                  setDialogState(() => _textSize = v);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
      ),
    );
  }

  void _showLanguageDialog() {
    final langs = ['English', 'Spanish', 'French', 'German'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xl),
        title: const Text('Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: langs.map((l) => ListTile(
            title: Text(l),
            onTap: () {
              setState(() => _selectedLanguage = l);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: _geminiService.apiKey);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gemini API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter API Key'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _geminiService.setApiKey(controller.text);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change PIN'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Old PIN'), obscureText: true),
            TextField(decoration: InputDecoration(labelText: 'New PIN'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Update')),
        ],
      ),
    );
  }

  void _exportData() async {
    await Share.share('Memoriae Data Export\nGenerated on ${DateTime.now()}');
  }

  Future<void> _fireTestNotification(String type) async {
    switch (type) {
      case 'medication':
        await MedicationNotificationService.instance.showTestNotification();
        break;
      case 'routine':
        await DailyRoutineNotificationService.instance.showTestNotification();
        break;
      case 'alert':
        final profileService = context.read<ProfileService>();
        await AlertService.instance.createAlert(
          patientId: profileService.profile?.id ?? 'demo_user',
          type: 'Inactivity',
          message: 'The patient has been inactive for 2 hours.',
          severity: 'high',
        );
        break;
      case 'custom':
        _showCustomNotificationDialog();
        break;
    }
  }

  void _showCustomNotificationDialog() {
    final titleController = TextEditingController(text: 'Test Notification');
    final bodyController = TextEditingController(text: 'This is a test notification body.');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: bodyController, decoration: const InputDecoration(labelText: 'Body')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final profileService = context.read<ProfileService>();
              AlertService.instance.createAlert(
                patientId: profileService.profile?.id ?? 'demo_user',
                type: 'Custom',
                message: '${titleController.text}: ${bodyController.text}',
                severity: 'medium',
              );
              Navigator.pop(context);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPendingNotifications() async {
    final notifications = await MedicationNotificationService.instance.getPendingNotifications();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pending Notifications'),
        content: notifications.isEmpty 
            ? const Text('No pending notifications.') 
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) => ListTile(title: Text(notifications[index].title ?? 'No Title')),
                ),
              ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
