import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, String>> creators = [
      {
        'name': 'Numbers',
        'role': 'Lead Developer & Project Manager',
        'image': 'assets/poi/numbers.jpg',
        'bio':
            'Visionary behind menta, passionate about creating accessible technology that makes a real difference in people\'s lives. Specializes in Flutter development and user experience design.',
        'expertise': '🎯 Flutter • 🚀 Project Management • 💡 Innovation',
      },
      {
        'name': 'Suv',
        'role': 'Full Stack Developer',
        'image': 'assets/poi/suv.jpg',
        'bio':
            'Expert in building robust and scalable applications. Focused on creating seamless user experiences and efficient backend systems for menta.',
        'expertise': '💻 Full Stack • 🔧 Backend • 📱 Mobile Dev',
      },
      {
        'name': 'Son',
        'role': 'UI/UX Designer',
        'image': 'assets/poi/son.jpg',
        'bio':
            'Crafts beautiful and accessible interfaces with empathy at the core. Ensures every interaction in menta is intuitive and delightful for users of all abilities.',
        'expertise': '🎨 UI Design • ✨ UX Research • 🌈 Accessibility',
      },
      {
        'name': 'Mal',
        'role': 'AI/ML Specialist',
        'image': 'assets/poi/mal.jpg',
        'bio':
            'Integrates cutting-edge AI features to enhance menta\'s cognitive support capabilities. Specializes in natural language processing and personalized assistance.',
        'expertise': '🤖 AI/ML • 🧠 NLP • 📊 Data Science',
      },
      {
        'name': 'Lak',
        'role': 'Quality Assurance & Testing',
        'image': 'assets/poi/lak.jpg',
        'bio':
            'Ensures menta works flawlessly for every user. Dedicated to delivering a bug-free, reliable experience through comprehensive testing and quality standards.',
        'expertise': '✅ QA Testing • 🔍 Bug Hunting • 📈 Performance',
      },
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isBlackMinimalism ? Colors.black : null,
          gradient: isBlackMinimalism
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.slate900,
                          AppColors.slate800,
                          AppColors.slate900,
                        ]
                      : [
                          AppColors.cream50,
                          AppColors.lavender50,
                          AppColors.mint50,
                        ],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        size: 28,
                        color: isBlackMinimalism ? Colors.white : null,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Text(
                      'About Us',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isBlackMinimalism ? Colors.white : null,
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
                  padding: const EdgeInsets.all(24),
                  children: [
                    // App Introduction
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isBlackMinimalism
                            ? const Color(0xFF1A1A1A)
                            : null,
                        gradient: isBlackMinimalism
                            ? null
                            : LinearGradient(
                                colors: [
                                  AppColors.lavender400.withValues(alpha: 0.2),
                                  AppColors.teal400.withValues(alpha: 0.2),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isBlackMinimalism
                              ? Colors.white10
                              : AppColors.lavender400.withValues(alpha: 0.3),
                          width: isBlackMinimalism ? 1 : 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          // App Icon/Logo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.lavender400,
                                  AppColors.teal400,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.lavender400.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'menta',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isBlackMinimalism ? Colors.white : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Memory Companion & Cognitive Support',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? AppColors.slate300
                                  : AppColors.slate600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Empowering individuals with memory challenges through compassionate technology and innovative solutions.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: isBlackMinimalism ? Colors.white70 : null,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Meet the Team Header
                    Row(
                      children: [
                        const Text('👥', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Text(
                          'Meet the Team',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isBlackMinimalism ? Colors.white : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A passionate team dedicated to making a difference',
                      style: TextStyle(
                        fontSize: 14,
                        color: isBlackMinimalism
                            ? Colors.white38
                            : (isDark
                                  ? AppColors.slate400
                                  : AppColors.slate600),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Team Members
                    ...creators.asMap().entries.map((entry) {
                      final index = entry.key;
                      final creator = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildCreatorCard(
                          context,
                          creator,
                          index,
                          isDark,
                          isBlackMinimalism,
                        ),
                      );
                    }),

                    const SizedBox(height: 32),

                    // Mission Statement
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isBlackMinimalism
                            ? const Color(0xFF0A0A0A)
                            : (isDark ? AppColors.slate800 : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: isBlackMinimalism
                            ? Border.all(color: Colors.white10)
                            : null,
                        boxShadow: isBlackMinimalism
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('🎯', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Text(
                                'Our Mission',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isBlackMinimalism
                                      ? Colors.white
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'To create accessible, compassionate technology that empowers individuals facing memory challenges to live more independently, confidently, and joyfully.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: isBlackMinimalism ? Colors.white70 : null,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Core Values
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isBlackMinimalism
                            ? const Color(0xFF0A0A0A)
                            : (isDark ? AppColors.slate800 : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: isBlackMinimalism
                            ? Border.all(color: Colors.white10)
                            : null,
                        boxShadow: isBlackMinimalism
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('💎', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Text(
                                'Core Values',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isBlackMinimalism
                                      ? Colors.white
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildValueItem(
                            'Compassion',
                            'Every feature designed with empathy',
                            isBlackMinimalism,
                          ),
                          _buildValueItem(
                            'Accessibility',
                            'Technology for everyone',
                            isBlackMinimalism,
                          ),
                          _buildValueItem(
                            'Innovation',
                            'Pushing boundaries in cognitive support',
                            isBlackMinimalism,
                          ),
                          _buildValueItem(
                            'Privacy',
                            'Your data, your control',
                            isBlackMinimalism,
                          ),
                          _buildValueItem(
                            'Excellence',
                            'Committed to the highest quality',
                            isBlackMinimalism,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Contact Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isBlackMinimalism
                            ? const Color(0xFF1A1A1A)
                            : null,
                        gradient: isBlackMinimalism
                            ? null
                            : LinearGradient(
                                colors: [
                                  AppColors.blue400.withValues(alpha: 0.2),
                                  AppColors.lavender400.withValues(alpha: 0.2),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isBlackMinimalism
                              ? Colors.white10
                              : AppColors.blue400.withValues(alpha: 0.3),
                          width: isBlackMinimalism ? 1 : 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Get in Touch',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isBlackMinimalism ? Colors.white : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Have questions or feedback? We\'d love to hear from you!',
                            style: TextStyle(
                              fontSize: 14,
                              color: isBlackMinimalism ? Colors.white70 : null,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildContactButton(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                onTap: () => _launchEmail(context),
                                color: AppColors.blue400,
                              ),
                              const SizedBox(width: 16),
                              _buildContactButton(
                                icon: Icons.language,
                                label: 'Website',
                                onTap: () => _launchWebsite(context),
                                color: AppColors.lavender400,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Version Info
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.slate500
                                  : AppColors.slate400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '© 2025 menta Team. All rights reserved.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.slate600
                                  : AppColors.slate400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatorCard(
    BuildContext context,
    Map<String, String> creator,
    int index,
    bool isDark,
    bool isBlackMinimalism,
  ) {
    final gradients = [
      [AppColors.lavender400, AppColors.blue400],
      [AppColors.teal400, AppColors.mint400],
      [AppColors.coral400, AppColors.peach400],
      [AppColors.blue400, AppColors.lavender400],
      [AppColors.mint400, AppColors.teal400],
    ];

    final gradient = gradients[index % gradients.length];

    return Container(
      decoration: BoxDecoration(
        color: isBlackMinimalism
            ? const Color(0xFF0A0A0A)
            : (isDark ? AppColors.slate800 : Colors.white),
        borderRadius: BorderRadius.circular(24),
        border: isBlackMinimalism ? Border.all(color: Colors.white10) : null,
        boxShadow: isBlackMinimalism
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          // Profile Image Section
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient.map((c) => c.withValues(alpha: 0.3)).toList(),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: gradient),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: gradient[0].withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        creator['image']!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to icon if image not found
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradient),
                            ),
                            child: Center(
                              child: Text(
                                creator['name']![0],
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  creator['name']!,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isBlackMinimalism ? Colors.white : null,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient
                          .map((c) => c.withValues(alpha: 0.2))
                          .toList(),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    creator['role']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: gradient[0],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  creator['bio']!,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? AppColors.slate300 : AppColors.slate600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.slate700.withValues(alpha: 0.5)
                        : AppColors.slate100.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    creator['expertise']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isBlackMinimalism ? Colors.white60 : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueItem(
    String title,
    String description,
    bool isBlackMinimalism,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.lavender400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isBlackMinimalism ? Colors.white : null,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isBlackMinimalism
                        ? Colors.white38
                        : AppColors.slate600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'team@mentaapp.com',
      query: 'subject=Feedback for menta',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email client'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _launchWebsite(BuildContext context) async {
    final Uri websiteUri = Uri.parse('https://mentaapp.com');

    try {
      if (await canLaunchUrl(websiteUri)) {
        await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open browser'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
