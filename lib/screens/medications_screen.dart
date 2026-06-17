import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/medication.dart';
import '../services/database_helper.dart';
import '../services/medication_notification_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

class MedicationsScreen extends StatefulWidget {
  final String userId;

  const MedicationsScreen({super.key, required this.userId});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final _dbHelper = DatabaseHelper.instance;
  List<Medication> _medications = [];
  List<Medication> _filteredMedications = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, inactive

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);
    final meds = await _dbHelper.getMedications(widget.userId);
    setState(() {
      _medications = meds;
      _applyFilters();
      _isLoading = false;
    });

    // Reschedule all medication notifications
    await MedicationNotificationService.instance.rescheduleAllMedications(meds);
  }

  void _applyFilters() {
    _filteredMedications = _medications.where((med) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          med.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          med.dosage.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _filterStatus == 'all' ||
          (_filterStatus == 'active' && med.isActive) ||
          (_filterStatus == 'inactive' && !med.isActive);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _showAddEditDialog([Medication? medication]) {
    showDialog(
      context: context,
      builder: (context) => MedicationFormDialog(
        userId: widget.userId,
        medication: medication,
        onSaved: _loadMedications,
      ),
    );
  }

  Future<void> _deleteMedication(Medication medication) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final themeService = Provider.of<ThemeService>(context, listen: false);
        final isBlackMinimalism =
            themeService.themeMode == AppThemeMode.blackMinimalism;

        return AlertDialog(
          backgroundColor: isBlackMinimalism ? const Color(0xFF1A1A1A) : null,
          title: Text(
            'Delete Medication',
            style: TextStyle(color: isBlackMinimalism ? Colors.white : null),
          ),
          content: Text(
            'Are you sure you want to delete ${medication.name}?',
            style: TextStyle(color: isBlackMinimalism ? Colors.white70 : null),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isBlackMinimalism ? Colors.white38 : null,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // Cancel notification before deleting
      await MedicationNotificationService.instance.cancelMedicationReminder(
        medication.id,
      );
      await _dbHelper.deleteMedication(medication.id);
      _loadMedications();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${medication.name} deleted')));
      }
    }
  }

  Future<void> _toggleActive(Medication medication) async {
    final updated = medication.copyWith(isActive: !medication.isActive);
    await _dbHelper.updateMedication(updated);

    // Update notification based on active status
    if (updated.isActive) {
      await MedicationNotificationService.instance.scheduleMedicationReminder(
        updated,
      );
    } else {
      await MedicationNotificationService.instance.cancelMedicationReminder(
        updated.id,
      );
    }

    _loadMedications();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isDark = themeService.isDarkMode;
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    return Scaffold(
      backgroundColor: isBlackMinimalism ? Colors.black : null,
      appBar: AppBar(
        backgroundColor: isBlackMinimalism ? Colors.black : null,
        elevation: isBlackMinimalism ? 0 : null,
        iconTheme: IconThemeData(
          color: isBlackMinimalism ? Colors.white : null,
        ),
        title: Text(
          'Medications',
          style: TextStyle(color: isBlackMinimalism ? Colors.white : null),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: isBlackMinimalism ? Colors.white : null,
            ),
            onPressed: _showFilterMenu,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isBlackMinimalism ? Colors.black : null,
          gradient: isBlackMinimalism
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [AppColors.slate900, AppColors.slate800]
                      : [AppColors.lavender50, Colors.white],
                ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: isBlackMinimalism
                      ? const Color(0xFF1A1A1A)
                      : (isDark ? AppColors.slate800 : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: isBlackMinimalism
                      ? Border.all(color: Colors.white10)
                      : null,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search medications...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _applyFilters();
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ),
            if (_filterStatus != 'all')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Chip(
                      label: Text('Filter: ${_filterStatus.toUpperCase()}'),
                      backgroundColor: isBlackMinimalism
                          ? Colors.white12
                          : null,
                      onDeleted: () {
                        setState(() {
                          _filterStatus = 'all';
                          _applyFilters();
                        });
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredMedications.isEmpty
                  ? _buildEmptyState(isBlackMinimalism)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredMedications.length,
                      itemBuilder: (context, index) {
                        final med = _filteredMedications[index];
                        return _buildMedicationCard(
                          med,
                          isDark,
                          isBlackMinimalism,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: Icon(
          Icons.add,
          color: isBlackMinimalism ? Colors.black : Colors.white,
        ),
        label: Text(
          'Add Medication',
          style: TextStyle(
            color: isBlackMinimalism ? Colors.black : Colors.white,
          ),
        ),
        backgroundColor: isBlackMinimalism
            ? Colors.white
            : AppColors.lavender400,
      ),
    );
  }

  Widget _buildEmptyState(bool isBlackMinimalism) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication,
            size: 80,
            color: isBlackMinimalism ? Colors.white12 : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No medications yet'
                : 'No medications found',
            style: TextStyle(
              fontSize: 18,
              color: isBlackMinimalism ? Colors.white38 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Tap the button below to add one'
                : 'Try a different search',
            style: TextStyle(
              color: isBlackMinimalism ? Colors.white24 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(
    Medication medication,
    bool isDark,
    bool isBlackMinimalism,
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isBlackMinimalism
            ? const Color(0xFF0A0A0A)
            : (isDark ? AppColors.slate800 : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: isBlackMinimalism ? Border.all(color: Colors.white10) : null,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: medication.isActive
                ? (isBlackMinimalism ? Colors.white12 : Colors.green[100])
                : (isBlackMinimalism ? Colors.white10 : Colors.grey[300]),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.medication,
            color: medication.isActive
                ? (isBlackMinimalism ? Colors.white : Colors.green[700])
                : (isBlackMinimalism ? Colors.white24 : Colors.grey[600]),
          ),
        ),
        title: Text(
          medication.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: medication.isActive ? null : TextDecoration.lineThrough,
            color: isBlackMinimalism ? Colors.white : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${medication.dosage} • ${medication.frequency}',
              style: TextStyle(
                color: isBlackMinimalism ? Colors.white70 : null,
              ),
            ),
            Text(
              'Time: ${medication.timeOfDay}',
              style: TextStyle(
                color: isBlackMinimalism ? Colors.white60 : null,
              ),
            ),
            if (medication.notes?.isNotEmpty ?? false)
              Text(
                medication.notes!,
                style: TextStyle(
                  color: isBlackMinimalism ? Colors.white38 : Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Theme(
          data: isBlackMinimalism
              ? theme.copyWith(
                  hoverColor: Colors.white10,
                  textTheme: theme.textTheme.apply(bodyColor: Colors.white),
                  popupMenuTheme: const PopupMenuThemeData(
                    color: Color(0xFF1A1A1A),
                  ),
                )
              : theme,
          child: PopupMenuButton(
            icon: Icon(
              Icons.more_vert,
              color: isBlackMinimalism ? Colors.white70 : null,
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(
                    medication.isActive ? Icons.pause : Icons.play_arrow,
                    size: 20,
                    color: isBlackMinimalism ? Colors.white : null,
                  ),
                  title: Text(
                    medication.isActive ? 'Deactivate' : 'Activate',
                    style: TextStyle(
                      color: isBlackMinimalism ? Colors.white : null,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                onTap: () => Future.delayed(
                  Duration.zero,
                  () => _toggleActive(medication),
                ),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(
                    Icons.edit,
                    size: 20,
                    color: isBlackMinimalism ? Colors.white : null,
                  ),
                  title: Text(
                    'Edit',
                    style: TextStyle(
                      color: isBlackMinimalism ? Colors.white : null,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                onTap: () {
                  Future.delayed(
                    Duration.zero,
                    () => _showAddEditDialog(medication),
                  );
                },
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(
                    Icons.delete,
                    size: 20,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                onTap: () {
                  Future.delayed(
                    Duration.zero,
                    () => _deleteMedication(medication),
                  );
                },
              ),
            ],
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showFilterMenu() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    showModalBottomSheet(
      context: context,
      backgroundColor: isBlackMinimalism ? const Color(0xFF1A1A1A) : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Filter by Status',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isBlackMinimalism ? Colors.white : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            RadioGroup<String>(
              groupValue: _filterStatus,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _filterStatus = value;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: Text(
                      'All Medications',
                      style: TextStyle(
                        color: isBlackMinimalism ? Colors.white : null,
                      ),
                    ),
                    value: 'all',
                    activeColor: isBlackMinimalism ? Colors.white : null,
                  ),
                  RadioListTile<String>(
                    title: Text(
                      'Active Only',
                      style: TextStyle(
                        color: isBlackMinimalism ? Colors.white : null,
                      ),
                    ),
                    value: 'active',
                    activeColor: isBlackMinimalism ? Colors.white : null,
                  ),
                  RadioListTile<String>(
                    title: Text(
                      'Inactive Only',
                      style: TextStyle(
                        color: isBlackMinimalism ? Colors.white : null,
                      ),
                    ),
                    value: 'inactive',
                    activeColor: isBlackMinimalism ? Colors.white : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MedicationFormDialog extends StatefulWidget {
  final String userId;
  final Medication? medication;
  final VoidCallback onSaved;

  const MedicationFormDialog({
    super.key,
    required this.userId,
    this.medication,
    required this.onSaved,
  });

  @override
  State<MedicationFormDialog> createState() => _MedicationFormDialogState();
}

class _MedicationFormDialogState extends State<MedicationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  String _frequency = 'Daily';
  TimeOfDay _timeOfDay = TimeOfDay.now();
  bool _isActive = true;
  bool _isSaving = false;

  final List<String> _frequencies = [
    'Daily',
    'Twice daily',
    'Three times daily',
    'Weekly',
    'As needed',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _nameController.text = widget.medication!.name;
      _dosageController.text = widget.medication!.dosage;
      _notesController.text = widget.medication!.notes ?? '';
      _frequency = widget.medication!.frequency;
      _isActive = widget.medication!.isActive;

      final timeParts = widget.medication!.timeOfDay.split(':');
      _timeOfDay = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _timeOfDay,
    );
    if (time != null) {
      setState(() => _timeOfDay = time);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final timeString =
        '${_timeOfDay.hour.toString().padLeft(2, '0')}:${_timeOfDay.minute.toString().padLeft(2, '0')}';

    final medication = Medication(
      id: widget.medication?.id ?? const Uuid().v4(),
      userId: widget.userId,
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      frequency: _frequency,
      timeOfDay: timeString,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isActive: _isActive,
      createdAt: widget.medication?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.medication == null) {
        await DatabaseHelper.instance.createMedication(medication);
      } else {
        await DatabaseHelper.instance.updateMedication(medication);
      }

      // Schedule notification for active medications
      if (medication.isActive) {
        await MedicationNotificationService.instance.scheduleMedicationReminder(
          medication,
        );
      } else {
        await MedicationNotificationService.instance.cancelMedicationReminder(
          medication.id,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.medication == null
                  ? 'Medication added with reminder'
                  : 'Medication updated',
            ),
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;
    final isDark = themeService.isDarkMode;

    return Dialog(
      backgroundColor: isBlackMinimalism ? const Color(0xFF1A1A1A) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.medication == null
                      ? 'Add Medication'
                      : 'Edit Medication',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isBlackMinimalism ? Colors.white : null,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Medication Name',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.medication),
                    enabledBorder: isBlackMinimalism
                        ? const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          )
                        : null,
                    labelStyle: isBlackMinimalism
                        ? const TextStyle(color: Colors.white60)
                        : null,
                  ),
                  style: isBlackMinimalism
                      ? const TextStyle(color: Colors.white)
                      : null,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter medication name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dosageController,
                  decoration: InputDecoration(
                    labelText: 'Dosage (e.g., 10mg, 2 tablets)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.healing),
                    enabledBorder: isBlackMinimalism
                        ? const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          )
                        : null,
                    labelStyle: isBlackMinimalism
                        ? const TextStyle(color: Colors.white60)
                        : null,
                  ),
                  style: isBlackMinimalism
                      ? const TextStyle(color: Colors.white)
                      : null,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter dosage';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  decoration: InputDecoration(
                    labelText: 'Frequency',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.repeat),
                    enabledBorder: isBlackMinimalism
                        ? const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          )
                        : null,
                    labelStyle: isBlackMinimalism
                        ? const TextStyle(color: Colors.white60)
                        : null,
                    focusedBorder: isBlackMinimalism
                        ? const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          )
                        : null,
                  ),
                  style: isBlackMinimalism
                      ? const TextStyle(color: Colors.white)
                      : null,
                  items: _frequencies.map((freq) {
                    return DropdownMenuItem(
                      value: freq,
                      child: Text(
                        freq,
                        style: TextStyle(
                          color: isBlackMinimalism
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _frequency = value!);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.access_time,
                    color: isBlackMinimalism ? Colors.white70 : null,
                  ),
                  title: Text(
                    'Time',
                    style: TextStyle(
                      color: isBlackMinimalism ? Colors.white : null,
                    ),
                  ),
                  subtitle: Text(
                    _timeOfDay.format(context),
                    style: TextStyle(
                      color: isBlackMinimalism ? Colors.white60 : null,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isBlackMinimalism ? Colors.white60 : null,
                  ),
                  onTap: _selectTime,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isBlackMinimalism
                          ? Colors.white10
                          : Colors.grey[300]!,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.notes),
                    enabledBorder: isBlackMinimalism
                        ? const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          )
                        : null,
                    labelStyle: isBlackMinimalism
                        ? const TextStyle(color: Colors.white60)
                        : null,
                    focusedBorder: isBlackMinimalism
                        ? const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          )
                        : null,
                  ),
                  style: isBlackMinimalism
                      ? const TextStyle(color: Colors.white)
                      : null,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Active',
                    style: TextStyle(
                      color: isBlackMinimalism ? Colors.white : null,
                    ),
                  ),
                  subtitle: Text(
                    _isActive ? 'Medication is active' : 'Medication is paused',
                    style: TextStyle(
                      color: isBlackMinimalism ? Colors.white60 : null,
                    ),
                  ),
                  activeThumbColor: isBlackMinimalism ? Colors.white : null,
                  value: _isActive,
                  onChanged: (value) {
                    setState(() => _isActive = value);
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isBlackMinimalism ? Colors.white70 : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBlackMinimalism
                            ? Colors.white
                            : null,
                        foregroundColor: isBlackMinimalism
                            ? Colors.black
                            : null,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.medication == null ? 'Add' : 'Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
