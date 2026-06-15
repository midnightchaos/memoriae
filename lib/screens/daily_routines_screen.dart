import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

import '../models/daily_routine.dart';
import '../theme/app_theme.dart';
import '../services/database_helper.dart';
import '../services/daily_routine_notification_service.dart';
import 'package:uuid/uuid.dart';

class DailyRoutinesScreen extends StatefulWidget {
  final String userId;

  const DailyRoutinesScreen({super.key, required this.userId});

  @override
  State<DailyRoutinesScreen> createState() => _DailyRoutinesScreenState();
}

class _DailyRoutinesScreenState extends State<DailyRoutinesScreen> {
  final List<DailyRoutine> _routines = [];
  String _selectedFilter = 'all'; // all, today, active

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    try {
      final routines = await DatabaseHelper.instance.getDailyRoutines(
        widget.userId,
      );
      setState(() {
        _routines.clear();
        _routines.addAll(routines);
      });

      // Reschedule all routine notifications
      await DailyRoutineNotificationService.instance.rescheduleAllRoutines(
        routines,
      );
    } catch (e) {
      print('Error loading routines: $e');
    }
  }

  List<DailyRoutine> get _filteredRoutines {
    final now = DateTime.now();
    final today = now.weekday;

    switch (_selectedFilter) {
      case 'today':
        return _routines
            .where((r) => r.days.contains(today) && r.isActive)
            .toList();
      case 'active':
        return _routines.where((r) => r.isActive).toList();
      default:
        return _routines;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeService = context.watch<ThemeService>();
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;
    final sortedRoutines = _filteredRoutines
      ..sort((a, b) => a.time.compareTo(b.time));

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
                      ? [AppColors.slate900, AppColors.slate800]
                      : [AppColors.mint50, AppColors.lavender50],
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
                      icon: const Icon(Icons.arrow_back, size: 28),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        foregroundColor: isDark
                            ? AppColors.slate400
                            : AppColors.slate600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Daily Routines',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),

              // Filter tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all', isDark, isBlackMinimalism),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Today',
                      'today',
                      isDark,
                      isBlackMinimalism,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Active',
                      'active',
                      isDark,
                      isBlackMinimalism,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Daily Schedule View
              Expanded(
                child: sortedRoutines.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📅', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                            Text(
                              'No routines scheduled',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: isBlackMinimalism
                                        ? Colors.white70
                                        : null,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to create your first routine',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: isBlackMinimalism
                                        ? Colors.white38
                                        : null,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedRoutines.length,
                        itemBuilder: (context, index) {
                          final routine = sortedRoutines[index];
                          return _buildRoutineCard(
                            routine,
                            isDark,
                            isBlackMinimalism,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRoutineDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Routine'),
        backgroundColor: isBlackMinimalism ? Colors.white : AppColors.mint500,
        foregroundColor: isBlackMinimalism ? Colors.black : Colors.white,
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    bool isDark,
    bool isBlackMinimalism,
  ) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isBlackMinimalism ? Colors.white : AppColors.mint500)
              : isBlackMinimalism
              ? Colors.white10
              : (isDark ? AppColors.slate700 : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: isBlackMinimalism
              ? Border.all(color: isSelected ? Colors.white : Colors.white12)
              : null,
          boxShadow: (isSelected && !isBlackMinimalism)
              ? [
                  BoxShadow(
                    color: AppColors.mint500.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isBlackMinimalism ? Colors.black : Colors.white)
                : (isBlackMinimalism ? Colors.white70 : null),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRoutineCard(
    DailyRoutine routine,
    bool isDark,
    bool isBlackMinimalism,
  ) {
    final now = DateTime.now();
    final routineTime = TimeOfDay(
      hour: int.parse(routine.time.split(':')[0]),
      minute: int.parse(routine.time.split(':')[1]),
    );
    final isUpcoming =
        routineTime.hour > now.hour ||
        (routineTime.hour == now.hour && routineTime.minute > now.minute);
    final isToday = routine.days.contains(now.weekday);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isBlackMinimalism
            ? const Color(0xFF0A0A0A)
            : (isDark ? AppColors.slate800 : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: isBlackMinimalism ? Border.all(color: Colors.white10) : null,
        boxShadow: isBlackMinimalism
            ? null
            : [
                BoxShadow(
                  color: AppColors.mint500.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: isBlackMinimalism
                ? null
                : LinearGradient(
                    colors: isToday && isUpcoming
                        ? [AppColors.mint400, AppColors.mint600]
                        : [AppColors.slate300, AppColors.slate400],
                  ),
            color: isBlackMinimalism
                ? (isToday && isUpcoming ? Colors.white : Colors.white10)
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                routine.time.split(':')[0],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isBlackMinimalism
                      ? (isToday && isUpcoming ? Colors.black : Colors.white)
                      : Colors.white,
                ),
              ),
              Text(
                routine.time.split(':')[1],
                style: TextStyle(
                  fontSize: 14,
                  color: isBlackMinimalism
                      ? (isToday && isUpcoming
                            ? Colors.black54
                            : Colors.white70)
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          routine.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isBlackMinimalism ? Colors.white : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              routine.description,
              style: TextStyle(
                color: isBlackMinimalism ? Colors.white70 : null,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: _buildDayIndicators(routine.days, isBlackMinimalism),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isToday && isUpcoming)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isBlackMinimalism ? Colors.white12 : AppColors.mint100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Today',
                  style: TextStyle(
                    color: isBlackMinimalism ? Colors.white : AppColors.mint700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            PopupMenuButton(
              icon: Icon(
                Icons.more_vert,
                color: isBlackMinimalism ? Colors.white70 : null,
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        size: 20,
                        color: isBlackMinimalism ? Colors.white : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: isBlackMinimalism ? Colors.white : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showRoutineDialog(routine: routine);
                } else if (value == 'delete') {
                  _deleteRoutine(routine);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDayIndicators(List<int> days, bool isBlackMinimalism) {
    const dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return List.generate(7, (index) {
      final isActive = days.contains(index + 1);
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isActive
              ? (isBlackMinimalism ? Colors.white : AppColors.mint500)
              : (isBlackMinimalism ? Colors.white10 : AppColors.slate200),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            dayNames[index],
            style: TextStyle(
              fontSize: 10,
              color: isActive
                  ? (isBlackMinimalism ? Colors.black : Colors.white)
                  : (isBlackMinimalism ? Colors.white38 : AppColors.slate500),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    });
  }

  Future<void> _showRoutineDialog({DailyRoutine? routine}) async {
    final titleController = TextEditingController(text: routine?.title);
    final descController = TextEditingController(text: routine?.description);
    TimeOfDay selectedTime = routine != null
        ? TimeOfDay(
            hour: int.parse(routine.time.split(':')[0]),
            minute: int.parse(routine.time.split(':')[1]),
          )
        : const TimeOfDay(hour: 8, minute: 0);
    List<int> selectedDays = routine?.days.toList() ?? [1, 2, 3, 4, 5, 6, 7];

    final themeService = context.read<ThemeService>();
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isBlackMinimalism ? const Color(0xFF1A1A1A) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            routine == null ? 'Add Routine' : 'Edit Routine',
            style: TextStyle(color: isBlackMinimalism ? Colors.white : null),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: const OutlineInputBorder(),
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
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: const OutlineInputBorder(),
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
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Time',
                    style: TextStyle(
                      color: isBlackMinimalism ? Colors.white70 : null,
                    ),
                  ),
                  trailing: Text(
                    selectedTime.format(context),
                    style: TextStyle(
                      color: isBlackMinimalism ? Colors.white : null,
                    ),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Repeat on:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isBlackMinimalism ? Colors.white70 : null,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (index) {
                    const dayNames = [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ];
                    final dayNum = index + 1;
                    final isSelected = selectedDays.contains(dayNum);
                    return FilterChip(
                      label: Text(dayNames[index]),
                      selected: isSelected,
                      selectedColor: isBlackMinimalism ? Colors.white : null,
                      checkmarkColor: isBlackMinimalism ? Colors.black : null,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? (isBlackMinimalism ? Colors.black : Colors.white)
                            : (isBlackMinimalism ? Colors.white70 : null),
                      ),
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            selectedDays.add(dayNum);
                          } else {
                            selectedDays.remove(dayNum);
                          }
                        });
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isBlackMinimalism ? Colors.white70 : null,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }

                if (selectedDays.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select at least one day'),
                    ),
                  );
                  return;
                }

                final newRoutine = DailyRoutine(
                  id: routine?.id ?? const Uuid().v4(),
                  userId: widget.userId,
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  time:
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                  days: selectedDays,
                  createdAt: routine?.createdAt ?? DateTime.now(),
                );
                Navigator.pop(context);
                _saveRoutine(newRoutine);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isBlackMinimalism ? Colors.white : null,
                foregroundColor: isBlackMinimalism ? Colors.black : null,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRoutine(DailyRoutine routine) async {
    try {
      final index = _routines.indexWhere((r) => r.id == routine.id);
      if (index >= 0) {
        await DatabaseHelper.instance.updateDailyRoutine(routine);
      } else {
        await DatabaseHelper.instance.createDailyRoutine(routine);
      }

      // Schedule notification if active
      if (routine.isActive) {
        await DailyRoutineNotificationService.instance.scheduleRoutineReminder(
          routine,
        );
      }

      await _loadRoutines();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Routine ${index >= 0 ? 'updated' : 'added'} successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving routine: $e')));
      }
    }
  }

  Future<void> _deleteRoutine(DailyRoutine routine) async {
    final themeService = context.read<ThemeService>();
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isBlackMinimalism ? const Color(0xFF1A1A1A) : null,
        title: Text(
          'Delete Routine',
          style: TextStyle(color: isBlackMinimalism ? Colors.white : null),
        ),
        content: Text(
          'Are you sure you want to delete "${routine.title}"?',
          style: TextStyle(color: isBlackMinimalism ? Colors.white70 : null),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isBlackMinimalism ? Colors.white70 : null,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Cancel notifications first
        await DailyRoutineNotificationService.instance.cancelRoutineReminder(
          routine.id,
        );
        await DatabaseHelper.instance.deleteDailyRoutine(routine.id);
        await _loadRoutines();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('"${routine.title}" deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting routine: $e')));
        }
      }
    }
  }
}
