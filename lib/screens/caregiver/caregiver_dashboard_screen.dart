import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/database_helper.dart';
import '../../models/caregiver.dart';
import '../../models/user.dart';
import '../../models/caregiver_alert.dart';
import '../../services/alert_service.dart';
import 'activity_summary_screen.dart';
import '../../services/auth_service.dart';
import '../auth/welcome_screen.dart';
import 'link_patient_screen.dart';
import 'audit_logs_screen.dart';
import '../safety_locations_screen.dart';
import '../medications_screen.dart';
import '../daily_routines_screen.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  final Caregiver? caregiver;
  const CaregiverDashboardScreen({super.key, this.caregiver});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  List<CaregiverAlert> _alerts = [];
  bool _isLoading = true;
  String? _linkedPatientId;
  User? _linkedPatient;
  Caregiver? _caregiver;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      _caregiver =
          widget.caregiver ?? await AuthService.instance.getCurrentCaregiver();

      if (_caregiver == null) {
        // Handle no caregiver logged in
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          );
        }
        return;
      }

      // Find the linked patient
      final db = await DatabaseHelper.instance.database;
      final patientResults = await db.query(
        'users',
        where: 'linkedCaregiverId = ?',
        whereArgs: [_caregiver!.id],
      );

      if (patientResults.isNotEmpty) {
        _linkedPatientId = patientResults.first['id'] as String;
        _linkedPatient = await DatabaseHelper.instance.getUserById(
          _linkedPatientId!,
        );
        _alerts = await AlertService.instance.getAlerts(_linkedPatientId!);
        // Sort alerts by timestamp descending
        _alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.instance.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _linkedPatientId == null
          ? _buildNoPatientLinked()
          : _buildDashboard(),
    );
  }

  Widget _buildNoPatientLinked() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.link_off, size: 64, color: AppColors.slate400),
            const SizedBox(height: 16),
            const Text(
              'No Patient Linked',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You haven\'t linked your account to a patient profile yet.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                if (_caregiver != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LinkPatientScreen(caregiver: _caregiver!),
                    ),
                  ).then((_) => _loadDashboard());
                }
              },
              icon: const Icon(Icons.link),
              label: const Text('Link Patient Account'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: _buildPatientSummaryCard(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                _buildQuickActionsGrid(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Alerts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (_alerts.isNotEmpty)
                      TextButton(
                        onPressed: () {}, // Future: View All Alerts screen
                        child: const Text('View All'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        if (_alerts.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: AppColors.emerald500,
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'All systems normal',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'No active alerts for the patient.',
                        style: TextStyle(color: AppColors.slate500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildAlertTile(_alerts[index]),
                childCount: _alerts.length > 3 ? 3 : _alerts.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildActionCard(
          'Activity Log',
          Icons.analytics_rounded,
          AppColors.blue500,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ActivitySummaryScreen(patientId: _linkedPatientId!),
            ),
          ),
        ),
        _buildActionCard(
          'Safety Zones',
          Icons.map_rounded,
          AppColors.emerald500,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SafetyLocationsScreen()),
          ),
        ),
        _buildActionCard(
          'Medications',
          Icons.medication_rounded,
          AppColors.coral500,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedicationsScreen(userId: _linkedPatientId!),
            ),
          ),
        ),
        _buildActionCard(
          'Daily Routine',
          Icons.event_note_rounded,
          AppColors.lavender500,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DailyRoutinesScreen(userId: _linkedPatientId!),
            ),
          ),
        ),
        _buildActionCard(
          'Audit Logs',
          Icons.history_rounded,
          AppColors.slate600,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AuditLogsScreen()),
          ),
        ),
        _buildActionCard(
          'Simulate Alert',
          Icons.warning_rounded,
          Colors.orange,
          () => _simulateAlert(),
        ),
      ],
    );
  }

  void _simulateAlert() async {
    if (_linkedPatientId == null) return;

    await AlertService.instance.createAlert(
      patientId: _linkedPatientId!,
      type: 'Safety Violation',
      message: 'Patient has left the designated "Home" safety zone.',
      severity: 'High',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Geofence Alert Simulated')),
      );
      _loadDashboard();
    }
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.slate800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lavender500,
            AppColors.lavender500.withBlue(255).withRed(150),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.lavender500.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.favorite_rounded,
                size: 150,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person_rounded,
                            color: AppColors.lavender500,
                            size: 35,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MONITORING',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _linkedPatient?.name ?? 'Unknown Patient',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const StatusBadge(
                        label: 'CONNECTED',
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.security_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Safety status is optimal',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTile(CaregiverAlert alert) {
    final isHigh = alert.severity == 'High';
    final color = isHigh ? AppColors.coral400 : AppColors.peach400;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: ListTile(
        leading: Icon(
          isHigh ? Icons.warning_amber_rounded : Icons.info_outline,
          color: color,
          size: 32,
        ),
        title: Text(
          alert.type,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.message),
            const SizedBox(height: 4),
            Text(
              '${alert.timestamp.toLocal()}'.split('.')[0],
              style: const TextStyle(fontSize: 12, color: AppColors.slate400),
            ),
          ],
        ),
        trailing: alert.isResolved
            ? const Icon(Icons.check_circle, color: AppColors.emerald500)
            : IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () async {
                  if (alert.id == null) return;
                  await AlertService.instance.resolveAlert(alert.id!);
                  _loadDashboard();
                },
              ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
