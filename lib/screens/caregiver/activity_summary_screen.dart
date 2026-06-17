import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/database_helper.dart';
import '../../models/activity_log.dart';
import '../../models/chat_message.dart';
import '../../services/activity_monitoring_service.dart';
import '../../services/audit_logging_service.dart';
import '../../services/theme_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ActivitySummaryScreen extends StatefulWidget {
  final String patientId;
  const ActivitySummaryScreen({super.key, required this.patientId});

  @override
  State<ActivitySummaryScreen> createState() => _ActivitySummaryScreenState();
}

class _ActivitySummaryScreenState extends State<ActivitySummaryScreen> {
  List<ActivityLog> _logs = [];
  Map<String, dynamic>? _todayScore;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _logs = await DatabaseHelper.instance.getActivityLogs(widget.patientId);
      // Sort logs by timestamp descending
      _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _todayScore = await ActivityMonitoringService.instance
          .getTodayEngagementScore(widget.patientId);
      _history = await DatabaseHelper.instance.getEngagementHistory(
        widget.patientId,
      );

      // Log audit action
      await AuditLoggingService.instance.logAction(
        action: 'Viewed Activity Summary',
        details:
            'Caregiver viewed engagement trends and logs for patient ${widget.patientId}',
      );
    } catch (e) {
      debugPrint('Error loading summary data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Activity Summary')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildEngagementSection(),
                  const SizedBox(height: 24),
                  _buildTrendGraph(),
                  const SizedBox(height: 24),
                  _buildActivityTypeBreakdown(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Detailed Activity Log',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // TODO: Send intervention/check-in prompt
                          _sendIntervention();
                        },
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Send Check-in'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_logs.isEmpty)
                    const Center(child: Text('No activities recorded yet.'))
                  else
                    ..._logs.map((log) => _buildActivityTile(log)),
                ],
              ),
            ),
    );
  }

  Widget _buildEngagementSection() {
    double score = _todayScore?['score'] ?? 0.0;
    String status = score > 15 ? 'High' : (score > 5 ? 'Moderate' : 'Low');
    Color color = score > 15
        ? AppColors.emerald500
        : (score > 5 ? AppColors.peach400 : AppColors.coral400);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Engagement Score (Today)',
              style: TextStyle(fontSize: 16, color: AppColors.slate600),
            ),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: (score / 30).clamp(
                      0.0,
                      1.0,
                    ), // Capacity of 30 for visualization
                    strokeWidth: 10,
                    backgroundColor: AppColors.slate100,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      score.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('Chats', '${_todayScore?['chatCount'] ?? 0}'),
                _buildMiniStat(
                  'Journals',
                  '${_todayScore?['journalCount'] ?? 0}',
                ),
                _buildMiniStat('Games', '${_todayScore?['gameCount'] ?? 0}'),
                _buildMiniStat(
                  'Therapy',
                  '${_todayScore?['therapyCount'] ?? 0}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMiniStat(
                  'Feedback',
                  '${_todayScore?['feedbackCount'] ?? 0}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.slate600),
        ),
      ],
    );
  }

  Widget _buildActivityTypeBreakdown() {
    // Simple count per type
    int chats = _logs
        .where((l) => l.activityType == ActivityMonitoringService.typeChat)
        .length;
    int journals = _logs
        .where((l) => l.activityType == ActivityMonitoringService.typeJournal)
        .length;
    int games = _logs
        .where((l) => l.activityType == ActivityMonitoringService.typeGame)
        .length;
    int therapy = _logs
        .where((l) => l.activityType == ActivityMonitoringService.typeTherapy)
        .length;

    return Row(
      children: [
        _buildBreakdownBox('💬 Chats', chats, AppColors.blue400),
        const SizedBox(width: 8),
        _buildBreakdownBox('📝 Journal', journals, AppColors.emerald400),
        const SizedBox(width: 8),
        _buildBreakdownBox('🎮 Games', games, AppColors.purple400),
        const SizedBox(width: 8),
        _buildBreakdownBox('🧘 Therapy', therapy, AppColors.peach400),
      ],
    );
  }

  Widget _buildBreakdownBox(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label.split(' ')[0], style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label.split(' ')[1],
              style: TextStyle(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile(ActivityLog log) {
    IconData icon;
    Color color;
    switch (log.activityType) {
      case ActivityMonitoringService.typeChat:
        icon = Icons.chat_bubble_outline;
        color = AppColors.blue400;
        break;
      case ActivityMonitoringService.typeJournal:
        icon = Icons.edit_note;
        color = AppColors.emerald400;
        break;
      case ActivityMonitoringService.typeGame:
        icon = Icons.sports_esports_outlined;
        color = AppColors.purple400;
        break;
      case ActivityMonitoringService.typeTherapy:
        icon = Icons.self_improvement;
        color = AppColors.peach400;
        break;
      case ActivityMonitoringService.typeFeedback:
        icon = Icons.thumbs_up_down_outlined;
        color = AppColors.slate600;
        break;
      default:
        icon = Icons.history;
        color = AppColors.slate400;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(log.description),
        subtitle: Text(
          DateFormat('MMM d, h:mm a').format(log.timestamp),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: log.durationSeconds > 0
            ? Text('${(log.durationSeconds / 60).ceil()}m')
            : null,
      ),
    );
  }

  Future<void> _sendIntervention() async {
    final TextEditingController messageController = TextEditingController(
      text: 'Hi! Just checking in to see how you are doing today. ❤️',
    );

    final themeService = context.read<ThemeService>();
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isBlackMinimalism ? const Color(0xFF1A1A1A) : null,
        title: Text(
          'Send Check-in Prompt',
          style: TextStyle(color: isBlackMinimalism ? Colors.white : null),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will appear in the patient\'s Menta chat as a message from you.',
              style: TextStyle(
                fontSize: 14,
                color: isBlackMinimalism ? Colors.white70 : AppColors.slate600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 3,
              style: TextStyle(color: isBlackMinimalism ? Colors.white : null),
              decoration: InputDecoration(
                hintText: 'Enter your message...',
                hintStyle: TextStyle(
                  color: isBlackMinimalism ? Colors.white24 : null,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: isBlackMinimalism
                    ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white10),
                      )
                    : null,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isBlackMinimalism ? Colors.white38 : null,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final message = messageController.text.trim();
              if (message.isEmpty) return;

              Navigator.pop(dialogContext);

              // 1. Log Activity
              await DatabaseHelper.instance.insertActivityLog(
                ActivityLog(
                  activityType: 'I', // Intervention
                  description: 'Caregiver sent check-in: $message',
                  patientId: widget.patientId,
                ),
              );

              // 2. Insert into Chat so patient sees it
              await DatabaseHelper.instance.insertChatMessage(
                ChatMessage(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  content: message,
                  isUser: false, // From "system/caregiver"
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  type: 'intervention',
                  metadata: '{"from": "caregiver"}',
                ),
              );

              // 3. Log Audit
              await AuditLoggingService.instance.logAction(
                action: 'Manual Intervention Sent',
                details: 'Caregiver sent message: $message',
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message sent to patient!'),
                    backgroundColor: AppColors.emerald500,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlackMinimalism
                  ? Colors.white
                  : AppColors.lavender500,
              foregroundColor: isBlackMinimalism ? Colors.black : Colors.white,
            ),
            child: const Text('Send Prompt'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendGraph() {
    if (_history.isEmpty) return const SizedBox.shrink();

    // Get last 7 days of data
    final displayData = _history.take(7).toList().reversed.toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Engagement Trend (7 Days)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.slate700,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < 0 ||
                              value.toInt() >= displayData.length) {
                            return const SizedBox.shrink();
                          }
                          final dateString = displayData[value.toInt()]['date'];
                          try {
                            final date = DateTime.parse(dateString);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('M/d').format(date),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.slate400,
                                ),
                              ),
                            );
                          } catch (_) {
                            return const SizedBox.shrink();
                          }
                        },
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(displayData.length, (i) {
                        return FlSpot(
                          i.toDouble(),
                          displayData[i]['score'] as double,
                        );
                      }),
                      isCurved: true,
                      color: AppColors.lavender400,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.lavender400.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
