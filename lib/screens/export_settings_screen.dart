import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/data_export_service.dart';
import '../providers/export_provider.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../widgets/error_dialog.dart';

class ExportSettingsScreen extends StatefulWidget {
  const ExportSettingsScreen({super.key});

  @override
  State<ExportSettingsScreen> createState() => _ExportSettingsScreenState();
}

class _ExportSettingsScreenState extends State<ExportSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _exportFormat = 'PDF Report';
  String _exportPeriod = 'Last 30 Days';
  final _passwordController = TextEditingController();
  bool _exportJournals = true;
  bool _exportHealth = true;
  bool _exportMedications = true;
  bool _exportLocations = true;

  void _handleManualExport() {
    _exportToFile();
  }

  void _exportData() {
    _handleManualExport();
  }

  late TextEditingController _emailController;

  bool _isLoading = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final exportService = DataExportService(prefs);
      final settings = exportService.getExportSettings();

      if (mounted) {
        setState(() {
          _emailController.text = settings['email'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        context.showError(
          title: 'Error Loading Settings',
          message: 'Failed to load export settings: ${e.toString()}',
          onRetry: _loadSettings,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportToFile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isExporting = true);

    try {
      final exportProvider = Provider.of<ExportProvider>(
        context,
        listen: false,
      );
      await exportProvider.exportData('current_user_id', sendEmail: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        context.showError(
          title: 'Export Failed',
          message: 'Failed to export data: ${e.toString()}',
          onRetry: _exportToFile,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeService = context.watch<ThemeService>();
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                      : [AppColors.blue50, const Color(0xFFE8EAF6)]),
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
                      'Export Settings',
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
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSettingsCard(
                          isDark,
                          isBlackMinimalism,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data Selection',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isBlackMinimalism
                                      ? Colors.white
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildCheckboxRow(
                                'Journal Entries',
                                _exportJournals,
                                (val) => setState(() => _exportJournals = val!),
                                isBlackMinimalism,
                              ),
                              _buildCheckboxRow(
                                'Health Analytics',
                                _exportHealth,
                                (val) => setState(() => _exportHealth = val!),
                                isBlackMinimalism,
                              ),
                              _buildCheckboxRow(
                                'Medication Logs',
                                _exportMedications,
                                (val) =>
                                    setState(() => _exportMedications = val!),
                                isBlackMinimalism,
                              ),
                              _buildCheckboxRow(
                                'Safety Locations',
                                _exportLocations,
                                (val) =>
                                    setState(() => _exportLocations = val!),
                                isBlackMinimalism,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSettingsCard(
                          isDark,
                          isBlackMinimalism,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Export Format',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isBlackMinimalism
                                      ? Colors.white
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildDropdownField(
                                value: _exportFormat,
                                items: [
                                  'PDF Report',
                                  'CSV Data',
                                  'Excel Spreadsheet',
                                ],
                                label: 'Select Format',
                                icon: Icons.description_outlined,
                                isBlackMinimalism: isBlackMinimalism,
                                onChanged: (val) =>
                                    setState(() => _exportFormat = val!),
                              ),
                              const SizedBox(height: 16),
                              _buildDropdownField(
                                value: _exportPeriod,
                                items: [
                                  'Last 7 Days',
                                  'Last 30 Days',
                                  'Last 90 Days',
                                  'Custom Range',
                                ],
                                label: 'Time Period',
                                icon: Icons.calendar_today_outlined,
                                isBlackMinimalism: isBlackMinimalism,
                                onChanged: (val) =>
                                    setState(() => _exportPeriod = val!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSettingsCard(
                          isDark,
                          isBlackMinimalism,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recipient Settings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isBlackMinimalism
                                      ? Colors.white
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                                isBlackMinimalism: isBlackMinimalism,
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Email is required'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Report Password (Optional)',
                                icon: Icons.lock_outline,
                                isBlackMinimalism: isBlackMinimalism,
                                isPassword: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _isExporting || _isLoading
                              ? null
                              : _exportData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isBlackMinimalism
                                ? Colors.white
                                : AppColors.lavender500,
                            foregroundColor: isBlackMinimalism
                                ? Colors.black
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isExporting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: isBlackMinimalism
                                        ? Colors.black
                                        : Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'GENERATE EXPORT',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isBlackMinimalism
                                ? Colors.white38
                                : AppColors.slate600,
                            side: BorderSide(
                              color: isBlackMinimalism
                                  ? Colors.white12
                                  : AppColors.slate300,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('CANCEL'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    bool isDark,
    bool isBlackMinimalism, {
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _buildCheckboxRow(
    String label,
    bool value,
    Function(bool?) onChanged,
    bool isBlackMinimalism,
  ) {
    return CheckboxListTile(
      title: Text(
        label,
        style: TextStyle(color: isBlackMinimalism ? Colors.white70 : null),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: isBlackMinimalism ? Colors.white : AppColors.lavender500,
      checkColor: isBlackMinimalism ? Colors.black : null,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isBlackMinimalism = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      style: TextStyle(color: isBlackMinimalism ? Colors.white : null),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isBlackMinimalism ? Colors.white70 : null),
        prefixIcon: Icon(
          icon,
          color: isBlackMinimalism ? Colors.white70 : null,
        ),
        enabledBorder: isBlackMinimalism
            ? const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              )
            : null,
        focusedBorder: isBlackMinimalism
            ? const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              )
            : null,
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required bool isBlackMinimalism,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  color: isBlackMinimalism
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black)
                      : null,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      dropdownColor: isBlackMinimalism ? const Color(0xFF1A1A1A) : null,
      style: TextStyle(color: isBlackMinimalism ? Colors.white : null),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isBlackMinimalism ? Colors.white70 : null),
        prefixIcon: Icon(
          icon,
          color: isBlackMinimalism ? Colors.white70 : null,
        ),
        enabledBorder: isBlackMinimalism
            ? const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              )
            : null,
        focusedBorder: isBlackMinimalism
            ? const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              )
            : null,
      ),
    );
  }
}
