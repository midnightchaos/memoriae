import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final List<Map<String, dynamic>> _resourceCategories = [
    {
      'title': 'Emergency Services',
      'icon': Icons.emergency,
      'color': Colors.red,
      'items': [
        {
          'name': 'Emergency Services',
          'description': 'Call in case of emergency',
          'contact': '911',
          'type': ResourceType.phone,
        },
        {
          'name': 'Crisis Text Line',
          'description': 'Text HOME to talk to a crisis counselor',
          'contact': '741741',
          'type': ResourceType.sms,
        },
      ],
    },
    {
      'title': 'Healthcare Support',
      'icon': Icons.local_hospital,
      'color': AppColors.blue400,
      'items': [
        {
          'name': 'Alzheimer\'s Association 24/7 Helpline',
          'description': 'Support and information',
          'contact': '800-272-3900',
          'type': ResourceType.phone,
        },
        {
          'name': 'National Institute on Aging',
          'description': 'Information and resources',
          'contact': 'https://www.nia.nih.gov/health/alzheimers',
          'type': ResourceType.website,
        },
      ],
    },
    {
      'title': 'Caregiver Resources',
      'icon': Icons.people,
      'color': AppColors.lavender400,
      'items': [
        {
          'name': 'Family Caregiver Alliance',
          'description': 'Caregiver support and education',
          'contact': 'https://www.caregiver.org',
          'type': ResourceType.website,
        },
        {
          'name': 'Eldercare Locator',
          'description': 'Find local support services',
          'contact': '800-677-1116',
          'type': ResourceType.phone,
        },
      ],
    },
    {
      'title': 'Mental Health',
      'icon': Icons.psychology,
      'color': AppColors.teal400,
      'items': [
        {
          'name': 'SAMHSA National Helpline',
          'description': 'Mental health and substance abuse support',
          'contact': '800-662-4357',
          'type': ResourceType.phone,
        },
        {
          'name': 'Mental Health America',
          'description': 'Screening and resources',
          'contact': 'https://www.mhanational.org',
          'type': ResourceType.website,
        },
      ],
    },
    {
      'title': 'Community Support',
      'icon': Icons.groups,
      'color': AppColors.coral400,
      'items': [
        {
          'name': 'Meals on Wheels',
          'description': 'Food delivery for seniors',
          'contact': 'https://www.mealsonwheelsamerica.org',
          'type': ResourceType.website,
        },
        {
          'name': 'Area Agency on Aging',
          'description': 'Local aging services',
          'contact': '800-677-1116',
          'type': ResourceType.phone,
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    return Scaffold(
      backgroundColor: isBlackMinimalism ? Colors.black : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isBlackMinimalism
                ? [Colors.black, const Color(0xFF121212)]
                : (isDark
                      ? [
                          AppColors.slate900,
                          AppColors.slate800,
                          AppColors.slate900,
                        ]
                      : [
                          Color(0xFFE0F2F1),
                          Color(0xFFE0F7FA),
                          Color(0xFFE0F2F1),
                        ]),
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
                      icon: const Icon(Icons.arrow_back),
                      color: isBlackMinimalism ? Colors.white : null,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Connect & Resources',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isBlackMinimalism ? Colors.white : null,
                          ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Emergency Banner
                      _buildEmergencyBanner(isBlackMinimalism),
                      const SizedBox(height: 24),

                      Text(
                        'Resource Categories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isBlackMinimalism ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Resource Categories
                      ..._resourceCategories.map(
                        (category) => _buildCategoryCard(
                          category,
                          isDark,
                          isBlackMinimalism,
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyBanner(bool isBlackMinimalism) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isBlackMinimalism ? const Color(0xFF1A1A1A) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isBlackMinimalism
              ? Colors.red.withOpacity(0.5)
              : Colors.red.shade200,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isBlackMinimalism
                      ? Colors.red.withOpacity(0.2)
                      : Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency_share,
                  color: Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Assistance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isBlackMinimalism
                            ? Colors.white
                            : Colors.red.shade900,
                      ),
                    ),
                    Text(
                      'Tap for immediate help',
                      style: TextStyle(
                        color: isBlackMinimalism
                            ? Colors.white70
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleAction(ResourceType.phone, '911'),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call SOS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    Map<String, dynamic> category,
    bool isDark,
    bool isBlackMinimalism,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                  color: (category['color'] as Color).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          hoverColor: isBlackMinimalism ? Colors.white.withOpacity(0.05) : null,
          splashColor: isBlackMinimalism
              ? Colors.white.withOpacity(0.05)
              : null,
        ),
        child: ExpansionTile(
          iconColor: isBlackMinimalism ? Colors.white : category['color'],
          collapsedIconColor: isBlackMinimalism
              ? Colors.white38
              : AppColors.slate400,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isBlackMinimalism
                  ? Colors.white.withOpacity(0.05)
                  : (category['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              category['icon'],
              color: isBlackMinimalism ? Colors.white : category['color'],
            ),
          ),
          title: Text(
            category['title'],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isBlackMinimalism ? Colors.white : null,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                children: (category['items'] as List)
                    .map((item) => _buildResourceTile(item, isBlackMinimalism))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceTile(Map<String, dynamic> item, bool isBlackMinimalism) {
    final type = item['type'] as ResourceType;
    final contact = item['contact'] as String;

    IconData actionIcon;
    String actionLabel;

    switch (type) {
      case ResourceType.phone:
        actionIcon = Icons.phone;
        actionLabel = 'Call';
        break;
      case ResourceType.sms:
        actionIcon = Icons.message;
        actionLabel = 'Text';
        break;
      case ResourceType.website:
        actionIcon = Icons.language;
        actionLabel = 'Visit';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBlackMinimalism
            ? Colors.white.withOpacity(0.03)
            : AppColors.slate100.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: isBlackMinimalism ? Border.all(color: Colors.white10) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isBlackMinimalism ? Colors.white : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['description'],
                  style: TextStyle(
                    color: isBlackMinimalism
                        ? Colors.white60
                        : AppColors.slate500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            actionIcon,
            actionLabel,
            () => _handleAction(type, contact),
            isBlackMinimalism,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    bool isBlackMinimalism,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isBlackMinimalism
              ? Colors.white.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBlackMinimalism ? Colors.white10 : AppColors.slate200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isBlackMinimalism ? Colors.white70 : AppColors.lavender500,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isBlackMinimalism ? Colors.white70 : AppColors.slate600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(ResourceType type, String contact) {
    switch (type) {
      case ResourceType.phone:
        _launchAction(
          Uri(scheme: 'tel', path: contact),
          'Cannot make phone call',
        );
        break;
      case ResourceType.sms:
        _launchAction(Uri(scheme: 'sms', path: contact), 'Cannot send SMS');
        break;
      case ResourceType.website:
        _launchAction(
          Uri.parse(contact),
          'Cannot open website',
          mode: LaunchMode.externalApplication,
        );
        break;
    }
  }

  Future<void> _launchAction(
    Uri uri,
    String errorMessage, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: mode);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }
}

// Models
enum ResourceType { phone, sms, website }
