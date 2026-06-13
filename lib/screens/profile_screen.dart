import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:location/location.dart' as loc;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'edit_profile_screen.dart';

import '../services/analytics_service.dart';
import '../services/theme_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/theme_extensions.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import '../widgets/animated_page_wrapper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserAnalytics? _analytics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    AnalyticsService.instance.addListener(_loadAnalytics);
  }

  @override
  void dispose() {
    AnalyticsService.instance.removeListener(_loadAnalytics);
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    if (_analytics == null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final analytics = await AnalyticsService.instance.getUserAnalytics();
      if (mounted) {
        setState(() {
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load analytics: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _shareWithCaregiver() async {
    if (_analytics == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share with Caregiver'),
        content: const Text(
          'This will share your current location and activity analytics with your caregiver.\n\nDo you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Share'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Get location
    loc.LocationData? locationData;
    try {
      final location = loc.Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
      }
      if (serviceEnabled) {
        loc.PermissionStatus permissionGranted = await location.hasPermission();
        if (permissionGranted == loc.PermissionStatus.denied) {
          permissionGranted = await location.requestPermission();
        }
        if (permissionGranted == loc.PermissionStatus.granted) {
          locationData = await location.getLocation();
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }

    final report = _compileAnalyticsReport(locationData);
    await Share.share(report, subject: 'Memoriae Activity Report');
  }

  String _compileAnalyticsReport(loc.LocationData? location) {
    if (_analytics == null) return 'No data available';
    final buffer = StringBuffer();
    buffer.writeln('📊 MEMORIAE ACTIVITY REPORT');
    buffer.writeln('Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}');
    buffer.writeln('');
    buffer.writeln('👤 USER: ${_analytics!.name}');
    if (location != null) {
      buffer.writeln('📍 LOCATION: https://maps.google.com/?q=${location.latitude},${location.longitude}');
    }
    buffer.writeln('📈 STATS: ${_analytics!.totalChats} chats, ${_analytics!.currentStreak} day streak');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final pageStyle = Theme.of(context).extension<AppPageStyle>()!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context) 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            )
          : null,
        title: Text(
          'Personal Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22),
            onPressed: () {
              final profile = context.read<ProfileService>().profile;
              if (profile != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)),
                );
              }
            },
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: _loadAnalytics,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedPageWrapper(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState()
                : _buildContent(pageStyle),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: AppSpacing.md),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _loadAnalytics,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppPageStyle pageStyle) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 100, AppSpacing.lg, AppSpacing.xxl),
      child: Column(
        children: [
          // User Card
          const StaggeredEntrance(
            index: 0,
            child: _UserIdentityCard(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Quick Stats
          const StaggeredEntrance(
            index: 1,
            child: _QuickStatsGrid(),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Activity Section
          const StaggeredEntrance(
            index: 2,
            child: SectionHeader(
              title: 'Activity Insights',
              icon: Icons.auto_graph_rounded,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StaggeredEntrance(
            index: 3,
            child: _EngagementChart(analytics: _analytics!),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Actions
          StaggeredEntrance(
            index: 4,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _shareWithCaregiver,
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share with Caregiver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pageStyle.iconAccentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserIdentityCard extends StatelessWidget {
  const _UserIdentityCard();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileService>().profile;
    final pageStyle = Theme.of(context).extension<AppPageStyle>()!;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: AppRadius.lg,
                  boxShadow: AppShadows.subtle,
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.name ?? 'Memoriae User',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontFamily: 'PlayfairDisplay',
                        fontWeight: FontWeight.bold,
                        color: pageStyle.sectionHeaderColor,
                      ),
                    ),
                    Text(
                      'Dementia Care Account',
                      style: TextStyle(color: pageStyle.subtitleColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildInfoItem(context, 'Date of Birth', profile?.age?.toString() != null ? '${profile!.age} Years Old' : 'Not set', Icons.cake_rounded),
          _buildInfoItem(context, 'Email', profile?.email ?? 'Not set', Icons.email_rounded),
          _buildInfoItem(context, 'Account Type', profile?.caregiverAccess == true ? 'Caregiver' : 'Patient', Icons.person_rounded),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon) {
    final pageStyle = Theme.of(context).extension<AppPageStyle>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: pageStyle.iconBackgroundColor,
              borderRadius: AppRadius.md,
            ),
            child: Icon(icon, size: 18, color: pageStyle.iconAccentColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: pageStyle.subtitleColor)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStatsGrid extends StatelessWidget {
  const _QuickStatsGrid();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserAnalytics>(
      future: AnalyticsService.instance.getUserAnalytics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final analytics = snapshot.data!;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.5,
          children: [
            _StatCard(label: 'Total Chats', value: analytics.totalChats.toString(), icon: Icons.chat_bubble_rounded),
            _StatCard(label: 'Day Streak', value: '${analytics.currentStreak} Days', icon: Icons.local_fire_department_rounded),
            _StatCard(label: 'Journals', value: analytics.journalEntries.toString(), icon: Icons.book_rounded),
            _StatCard(label: 'Games', value: analytics.gamesPlayed.toString(), icon: Icons.videogame_asset_rounded),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final pageStyle = Theme.of(context).extension<AppPageStyle>()!;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: pageStyle.iconAccentColor, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 12, color: pageStyle.subtitleColor)),
        ],
      ),
    );
  }
}

class _EngagementChart extends StatelessWidget {
  final UserAnalytics analytics;
  const _EngagementChart({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageStyle = Theme.of(context).extension<AppPageStyle>()!;

    return GlassCard(
      height: 240,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() % 2 != 0) return const SizedBox();
                  return Text(
                    'Day ${value.toInt() + 1}',
                    style: TextStyle(fontSize: 10, color: pageStyle.subtitleColor),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                analytics.engagementHistory.length,
                (i) => FlSpot(i.toDouble(), (analytics.engagementHistory[i]['chats'] as int).toDouble()),
              ),
              isCurved: true,
              gradient: AppGradients.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.lavender400.withOpacity(0.3),
                    AppColors.teal400.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
