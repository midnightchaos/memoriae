import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audit_logging_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    final isBlackMinimalism = themeService.themeMode == AppThemeMode.blackMinimalism;

    return Scaffold(
      backgroundColor: isBlackMinimalism ? Colors.black : null,
      appBar: AppBar(
        title: const Text('Audit Logs'),
        backgroundColor: isBlackMinimalism ? Colors.black : null,
        foregroundColor: isBlackMinimalism ? Colors.white : null,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isBlackMinimalism
                ? [Colors.black, const Color(0xFF121212)]
                : (isDark
                    ? [AppColors.slate900, AppColors.slate800]
                    : [AppColors.blue50, AppColors.lavender50]),
          ),
        ),
        child: FutureBuilder<List<AuditLog>>(
          future: AuditLoggingService.instance.getLogs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState(isBlackMinimalism);
            }

            final logs = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildLogCard(log, isDark, isBlackMinimalism);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogCard(AuditLog log, bool isDark, bool isBlackMinimalism) {
    final dateStr = DateFormat('MMM d, yyyy • HH:mm').format(log.timestamp);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isBlackMinimalism ? const Color(0xFF0A0A0A) : (isDark ? AppColors.slate800 : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: isBlackMinimalism ? Border.all(color: Colors.white10) : null,
        boxShadow: isBlackMinimalism ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getActionColor(log.action).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getActionIcon(log.action),
            color: _getActionColor(log.action),
          ),
        ),
        title: Text(
          log.action,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isBlackMinimalism ? Colors.white : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              log.details,
              style: TextStyle(color: isBlackMinimalism ? Colors.white70 : null),
            ),
            const SizedBox(height: 8),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 12,
                color: isBlackMinimalism ? Colors.white38 : AppColors.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActionIcon(String action) {
    action = action.toLowerCase();
    if (action.contains('medication')) return Icons.medication;
    if (action.contains('routine')) return Icons.schedule;
    if (action.contains('location')) return Icons.place;
    if (action.contains('login')) return Icons.login;
    if (action.contains('link')) return Icons.link;
    return Icons.history;
  }

  Color _getActionColor(String action) {
    action = action.toLowerCase();
    if (action.contains('medication')) return AppColors.coral500;
    if (action.contains('routine')) return AppColors.lavender500;
    if (action.contains('location')) return AppColors.emerald500;
    if (action.contains('login')) return AppColors.blue500;
    return AppColors.slate500;
  }

  Widget _buildEmptyState(bool isBlackMinimalism) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 64,
            color: isBlackMinimalism ? Colors.white24 : AppColors.slate300,
          ),
          const SizedBox(height: 16),
          Text(
            'No logs found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isBlackMinimalism ? Colors.white70 : AppColors.slate400,
            ),
          ),
        ],
      ),
    );
  }
}
