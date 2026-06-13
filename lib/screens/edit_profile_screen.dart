import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/profile_service.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/theme_extensions.dart';
import '../widgets/animated_page_wrapper.dart';
import '../widgets/glass_card.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _emailController = TextEditingController(text: widget.profile.email);
    _ageController = TextEditingController(text: widget.profile.age?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profileService = context.read<ProfileService>();
      final updatedProfile = widget.profile.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
      );

      await profileService.save(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageStyle = Theme.of(context).extension<AppPageStyle>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AnimatedPageWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildTextField(
                      controller: _ageController,
                      label: 'Age',
                      icon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lavender500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
                  elevation: 4,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isDark = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.slate700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: isDark ? Colors.white : AppColors.slate900),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.lavender400),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: AppRadius.md,
              borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.lavender100),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.md,
              borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.lavender100),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.md,
              borderSide: const BorderSide(color: AppColors.lavender400, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
