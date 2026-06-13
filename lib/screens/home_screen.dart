import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/animated_page_wrapper.dart';
import '../widgets/feature_tile.dart';
import '../widgets/glass_card.dart';

import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/theme_extensions.dart';
import 'package:intl/intl.dart';
import 'memory_screen.dart';
import 'familiar_faces_screen.dart';
import '../services/profile_service.dart';
import 'daily_routines_screen.dart';
import 'safety_locations_screen.dart';
import 'medications_screen.dart';
import 'drawing_therapy_screen.dart';
import 'relax_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'chatbot_screen.dart';
import 'connect_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String greeting = '';
  String currentDate = '';
  String weather = '72°F';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _controller.forward();
    _updateGreeting();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    currentDate = DateFormat('EEEE, MMMM d').format(DateTime.now());
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDrawer(BuildContext context, ProfileService profileService) {
    final pageStyle = Theme.of(context).extension<AppPageStyle>()!;

    final isBlack = pageStyle.pageColor == Colors.black;

    return Drawer(
      child: Container(
        decoration: isBlack
            ? const BoxDecoration(color: Colors.black)
            : pageStyle.backgroundDecoration,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: isBlack ? null : AppGradients.primary,
                color: isBlack ? Colors.black : null,
                border: isBlack
                    ? const Border(
                        bottom: BorderSide(color: Colors.white12))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.lg,
                    ),
                    child: const Center(
                      child: Text('💜', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),
                  Text(
                    profileService.profile?.name ?? 'User',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Memory Care Companion',
                    style: GoogleFonts.dmSans(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            _drawerItem(Icons.home_rounded, 'Home', () => Navigator.pop(context)),
            _drawerItem(Icons.chat_rounded, 'Chat with Menta', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatbotScreen()));
            }),
            _drawerItem(Icons.book_rounded, 'Memory Journal', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MemoryScreen()));
            }),
            _drawerItem(Icons.people_rounded, 'Familiar Faces', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, FamiliarFacesScreen.routeName);
            }),
            _drawerItem(Icons.calendar_today_rounded, 'Daily Routines', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DailyRoutinesScreen(
                      userId: profileService.profile?.id ?? 'user1'),
                ),
              );
            }),
            _drawerItem(Icons.medical_services_rounded, 'Medications', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => MedicationsScreen(userId: profileService.profile?.id ?? 'user1')));
            }),
            Divider(color: pageStyle.subtitleColor.withOpacity(0.15)),
            _drawerItem(Icons.brush_rounded, 'Drawing Therapy', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const DrawingTherapyScreen()));
            }),
            _drawerItem(Icons.spa_rounded, 'Relax & Breathe', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RelaxScreen()));
            }),
            _drawerItem(Icons.connect_without_contact_rounded,
                'Connect & Support', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ConnectScreen()));
            }),
            Divider(color: pageStyle.subtitleColor.withOpacity(0.15)),
            _drawerItem(Icons.person_rounded, 'My Profile', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
            _drawerItem(Icons.settings_rounded, 'Settings', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    final pageStyle = Theme.of(context).extension<AppPageStyle>()!;

    return ListTile(
      leading: Icon(icon, color: pageStyle.iconAccentColor, size: 22),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: pageStyle.sectionHeaderColor,
              fontSize: 15,
            ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileService = context.watch<ProfileService>();

    final features = [
      FeatureTile(
        icon: Icons.book_rounded,
        label: 'Memory',
        sublabel: 'Journal & Moments',
        backgroundImage: 'assets/images/1.png',
        index: 0,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MemoryScreen()),
        ),
      ),
      FeatureTile(
        icon: Icons.people_rounded,
        label: 'Familiar',
        sublabel: 'Faces & Connections',
        backgroundImage: 'assets/images/2.png',
        index: 1,
        onTap: () => Navigator.pushNamed(context, FamiliarFacesScreen.routeName),
      ),
      FeatureTile(
        icon: Icons.wb_sunny_rounded,
        label: 'Daily',
        sublabel: 'Routine & Schedule',
        backgroundImage: 'assets/images/3.png',
        index: 2,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DailyRoutinesScreen(
                userId: profileService.profile?.id ?? 'user1'),
          ),
        ),
      ),
      FeatureTile(
        icon: Icons.location_on_rounded,
        label: 'Location',
        sublabel: 'Safety & Navigation',
        backgroundImage: 'assets/images/4.png',
        index: 3,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SafetyLocationsScreen()),
        ),
      ),
      FeatureTile(
        icon: Icons.medication_rounded,
        label: 'Medication',
        sublabel: 'Reminders & Tracking',
        backgroundImage: 'assets/images/5.jpg',
        index: 4,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => MedicationsScreen(userId: profileService.profile?.id ?? 'user1')),
        ),
      ),
      FeatureTile(
        icon: Icons.brush_rounded,
        label: 'Drawing',
        sublabel: 'Art Therapy',
        backgroundImage: 'assets/images/6.png',
        index: 5,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DrawingTherapyScreen()),
        ),
      ),
      FeatureTile(
        icon: Icons.spa_rounded,
        label: 'Relax',
        sublabel: 'Breathe & Meditate',
        backgroundImage: 'assets/images/18.png',
        index: 6,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RelaxScreen()),
        ),
      ),
      FeatureTile(
        icon: Icons.handshake_rounded,
        label: 'Connect',
        sublabel: 'Support & Community',
        backgroundImage: 'assets/images/121.png',
        index: 7,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ConnectScreen()),
        ),
      ),
      FeatureTile(
        icon: Icons.person_rounded,
        label: 'My Profile',
        sublabel: 'Personal Info',
        backgroundImage: 'assets/images/1.png',
        index: 8,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
      ),
    ];

    return Scaffold(
      drawer: _buildDrawer(context, profileService),
      body: AnimatedPageWrapper(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu_rounded, size: 28),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Greeting Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _controller.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _controller.value)),
                      child: child,
                    ),
                  );
                },
                child: GlassCard(
                  gradient: _getGreetingGradient(context),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.8, end: 1.0),
                        duration: const Duration(seconds: 2),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: AppRadius.lg,
                          ),
                          child: const Center(
                            child: Text('💜', style: TextStyle(fontSize: 32)),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '$greeting, ${profileService.profile?.name ?? 'User'}!',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).textTheme.displayMedium?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        currentDate,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wb_sunny_rounded,
                              size: 18, color: AppColors.amber400),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            weather,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Features
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                itemCount: features.length + 1,
                itemBuilder: (context, index) {
                  if (index < features.length) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                      child: features[index],
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                      child: FeatureTile(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        sublabel: 'Preferences & Setup',
                        backgroundImage: 'assets/images/2.png',
                        index: 9,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient? _getGreetingGradient(BuildContext context) {
    final pageStyle = Theme.of(context).extension<AppPageStyle>()!;
    if (pageStyle.pageColor == Colors.black) return null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppGradients.warmDark : AppGradients.warm;
  }
}
