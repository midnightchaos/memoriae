import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/theme_extensions.dart';
import 'home_screen.dart';
import 'relax_screen.dart';
import 'profile_screen.dart';
import 'drawing_therapy_screen.dart';
import 'familiar_faces_screen.dart';
import 'chatbot_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DrawingTherapyScreen(),
    const FamiliarFacesScreen(),
    const RelaxScreen(),
    const ProfileScreen(),
  ];

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.brush_rounded, label: 'Draw'),
    _NavItem(icon: Icons.people_rounded, label: 'Faces'),
    _NavItem(icon: Icons.spa_rounded, label: 'Relax'),
    _NavItem(icon: Icons.person_rounded, label: 'You'),
  ];

  @override
  Widget build(BuildContext context) {
    final navStyle = Theme.of(context).extension<AppNavStyle>()!;

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) return;

        // If we're not on the Home tab, switch to it first
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        // If already on Home tab, exit the app
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: AnimatedSwitcher(
        duration: AppDurations.normal,
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navStyle.barBackground,
          border: Border(
            top: BorderSide(
              color: navStyle.barBorderColor,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (index) {
                final isSelected = _currentIndex == index;
                return _buildNavItem(_items[index], isSelected, index, navStyle);
              }),
            ),
          ),
        ),
      ),
      floatingActionButton: _currentIndex != 2
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppShadows.glowWith(AppColors.lavender400),
              ),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatbotScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.chat_rounded, size: 24),
              ),
            )
          : null,
      ),
    );
  }

  Widget _buildNavItem(
      _NavItem item, bool isSelected, int index, AppNavStyle navStyle) {
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: AppRadius.xxl,
      child: AnimatedContainer(
        duration: AppDurations.normal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? navStyle.selectedIndicatorGradient : null,
          borderRadius: AppRadius.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: AppDurations.fast,
              child: Icon(
                item.icon,
                size: 24,
                color: isSelected
                    ? navStyle.selectedLabelColor
                    : navStyle.unselectedLabelColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? navStyle.selectedLabelColor
                    : navStyle.unselectedLabelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
