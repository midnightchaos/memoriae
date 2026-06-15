import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

import 'package:intl/intl.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import 'add_edit_journal_screen.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen>
    with SingleTickerProviderStateMixin {
  final JournalService _journalService = JournalService();
  List<JournalEntry> _entries = [];
  List<JournalEntry> _filteredEntries = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedMoodFilter;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadEntries();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final entries = await _journalService.loadEntries();
    setState(() {
      _entries = entries;
      _filteredEntries = entries;
      _isLoading = false;
    });
    _animationController.forward();
  }

  Future<void> _filterEntries() async {
    setState(() => _isLoading = true);

    List<JournalEntry> filtered = _entries;

    if (_searchQuery.isNotEmpty) {
      filtered = await _journalService.searchEntries(_searchQuery);
    }

    if (_selectedMoodFilter != null) {
      final moodFiltered = await _journalService.filterByMood(
        _selectedMoodFilter!,
      );
      if (_searchQuery.isNotEmpty) {
        // If both filters are active, intersect the results
        filtered = filtered
            .where((entry) => moodFiltered.any((m) => m.id == entry.id))
            .toList();
      } else {
        filtered = moodFiltered;
      }
    }

    setState(() {
      _filteredEntries = filtered;
      _isLoading = false;
    });
  }

  Future<void> _addEntry() async {
    final result = await Navigator.push<JournalEntry>(
      context,
      MaterialPageRoute(builder: (context) => const AddEditJournalScreenV2()),
    );

    if (result != null) {
      await _journalService.addEntry(result);
      await _loadEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal entry saved!'),
            backgroundColor: AppColors.emerald500,
          ),
        );
      }
    }
  }

  Future<void> _editEntry(JournalEntry entry) async {
    final result = await Navigator.push<JournalEntry>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditJournalScreenV2(entry: entry),
      ),
    );

    if (result != null) {
      await _journalService.updateEntry(result);
      await _loadEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal entry updated!'),
            backgroundColor: AppColors.emerald500,
          ),
        );
      }
    }
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isBlackMinimalism ? const Color(0xFF1A1A1A) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete Entry?',
          style: TextStyle(color: isBlackMinimalism ? Colors.white : null),
        ),
        content: Text(
          'This action cannot be undone.',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral400,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _journalService.deleteEntry(entry.id);
      await _loadEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry deleted'),
            backgroundColor: AppColors.coral400,
          ),
        );
      }
    }
  }

  Future<void> _showStatistics() async {
    final stats = await _journalService.getStatistics();
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isBlackMinimalism ? const Color(0xFF1A1A1A) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isBlackMinimalism
                    ? Colors.white12
                    : AppColors.lavender100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('📊', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Text(
              'Your Statistics',
              style: TextStyle(color: isBlackMinimalism ? Colors.white : null),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Entries', '${stats['totalEntries']}'),
            const SizedBox(height: 12),
            _buildStatRow('This Week', '${stats['entriesThisWeek']}'),
            const SizedBox(height: 12),
            _buildStatRow('This Month', '${stats['entriesThisMonth']}'),
            const SizedBox(height: 12),
            _buildStatRow('Most Used Mood', stats['mostUsedMood']),
            const SizedBox(height: 12),
            if ((stats['topTags'] as List).isNotEmpty) ...[
              Text(
                'Top Tags:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isBlackMinimalism ? Colors.white : null,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: (stats['topTags'] as List<String>).map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: isBlackMinimalism
                        ? Colors.white12
                        : AppColors.lavender100,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlackMinimalism
                  ? Colors.white24
                  : AppColors.lavender500,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Close',
              style: TextStyle(color: isBlackMinimalism ? Colors.white : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: isBlackMinimalism ? Colors.white70 : null,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isBlackMinimalism ? Colors.white : AppColors.lavender500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeService = context.watch<ThemeService>();
    final isDark = themeService.isDarkMode;
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isBlackMinimalism
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [AppColors.slate900, AppColors.slate800]
                      : [
                          AppColors.lavender50,
                          AppColors.blue50,
                          AppColors.mint50,
                        ],
                ),
          color: isBlackMinimalism ? Colors.black : null,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('📔', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Memory Journal',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: isBlackMinimalism ? Colors.white : null,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.bar_chart_rounded),
                      onPressed: _showStatistics,
                      tooltip: 'Statistics',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),

              // Search and Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isBlackMinimalism
                        ? const Color(0xFF1A1A1A)
                        : (isDark ? AppColors.slate800 : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: isBlackMinimalism
                        ? Border.all(color: Colors.white10)
                        : null,
                    boxShadow: isBlackMinimalism
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search memories...',
                            hintStyle: TextStyle(
                              color: isBlackMinimalism ? Colors.white38 : null,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: isBlackMinimalism ? Colors.white70 : null,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                            _filterEntries();
                          },
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.filter_list,
                          color: isBlackMinimalism ? Colors.white70 : null,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: isBlackMinimalism
                            ? const Color(0xFF1A1A1A)
                            : null,
                        onSelected: (mood) {
                          setState(() {
                            _selectedMoodFilter = _selectedMoodFilter == mood
                                ? null
                                : mood;
                          });
                          _filterEntries();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: '😊',
                            child: Text('😊 Happy'),
                          ),
                          const PopupMenuItem(
                            value: '😔',
                            child: Text('😔 Sad'),
                          ),
                          const PopupMenuItem(
                            value: '😌',
                            child: Text('😌 Calm'),
                          ),
                          const PopupMenuItem(
                            value: '😄',
                            child: Text('😄 Excited'),
                          ),
                          const PopupMenuItem(
                            value: '😴',
                            child: Text('😴 Tired'),
                          ),
                          const PopupMenuItem(
                            value: '🤔',
                            child: Text('🤔 Thoughtful'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Active Filters
              if (_selectedMoodFilter != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Chip(
                        label: Text('Mood: $_selectedMoodFilter'),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() => _selectedMoodFilter = null);
                          _filterEntries();
                        },
                        backgroundColor: isBlackMinimalism
                            ? Colors.white12
                            : AppColors.lavender100,
                        labelStyle: TextStyle(
                          color: isBlackMinimalism ? Colors.white : null,
                        ),
                        deleteIconColor: isBlackMinimalism
                            ? Colors.white38
                            : null,
                      ),
                    ],
                  ),
                ),

              // Entries List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredEntries.isEmpty
                    ? _buildEmptyState()
                    : AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _animationController.value,
                            child: child,
                          );
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredEntries.length,
                          itemBuilder: (context, index) {
                            final entry = _filteredEntries[index];
                            return _buildEntryCard(
                              entry,
                              index,
                              isDark,
                              isBlackMinimalism,
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
        backgroundColor: isBlackMinimalism
            ? Colors.white
            : AppColors.lavender500,
        foregroundColor: isBlackMinimalism ? Colors.black : Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    final themeService = context.watch<ThemeService>();
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isBlackMinimalism
                  ? Colors.white12
                  : Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Text('📝', style: TextStyle(fontSize: 72)),
          ),
          const SizedBox(height: 24),
          Text(
            'No Memories Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isBlackMinimalism ? Colors.white : AppColors.slate800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first journal entry',
            style: TextStyle(
              fontSize: 16,
              color: isBlackMinimalism ? Colors.white38 : AppColors.slate600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(
    JournalEntry entry,
    int index,
    bool isDark,
    bool isBlackMinimalism,
  ) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isBlackMinimalism
              ? const Color(0xFF1A1A1A)
              : (isDark ? AppColors.slate800 : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: isBlackMinimalism ? Border.all(color: Colors.white12) : null,
          boxShadow: isBlackMinimalism
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: InkWell(
          onTap: () => _editEntry(entry),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(entry.mood, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isBlackMinimalism ? Colors.white : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            DateFormat(
                              'MMM d, yyyy • h:mm a',
                            ).format(entry.date),
                            style: TextStyle(
                              fontSize: 14,
                              color: isBlackMinimalism
                                  ? Colors.white38
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.coral400,
                      ),
                      onPressed: () => _deleteEntry(entry),
                    ),
                  ],
                ),

                if (entry.content.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    entry.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: isBlackMinimalism ? Colors.white70 : null,
                    ),
                  ),
                ],

                // Image thumbnail
                if (entry.imagePath != null && entry.imagePath!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(entry.imagePath!),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: isBlackMinimalism
                                ? Colors.white10
                                : AppColors.slate100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 48,
                              color: isBlackMinimalism
                                  ? Colors.white24
                                  : AppColors.slate400,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Audio indicator
                if (entry.audioPath != null && entry.audioPath!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isBlackMinimalism
                          ? Colors.white12
                          : AppColors.lavender100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic,
                          size: 16,
                          color: isBlackMinimalism
                              ? Colors.white70
                              : AppColors.lavender500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Voice Recording',
                          style: TextStyle(
                            fontSize: 12,
                            color: isBlackMinimalism
                                ? Colors.white70
                                : AppColors.lavender500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Tags section
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isBlackMinimalism
                              ? Colors.white12
                              : AppColors.lavender100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Mood: ${entry.mood}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isBlackMinimalism
                                ? Colors.white
                                : AppColors.slate800,
                          ),
                        ),
                      ),
                      ...entry.tags.map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isBlackMinimalism
                                ? Colors.white12
                                : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 12,
                              color: isBlackMinimalism
                                  ? Colors.white38
                                  : AppColors.slate600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Add/Edit Journal Entry Screen
class AddEditJournalScreen extends StatefulWidget {
  final JournalEntry? entry;

  const AddEditJournalScreen({super.key, this.entry});

  @override
  State<AddEditJournalScreen> createState() => _AddEditJournalScreenState();
}

class _AddEditJournalScreenState extends State<AddEditJournalScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagController;
  String _selectedMood = '😊';
  List<String> _tags = [];
  String? _imagePath;
  String? _audioPath;

  final List<String> _moods = ['😊', '😔', '😌', '😄', '😴', '🤔', '😍', '😎'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(
      text: widget.entry?.content ?? '',
    );
    _tagController = TextEditingController();
    _selectedMood = widget.entry?.mood ?? '😊';
    _tags = List.from(widget.entry?.tags ?? []);
    _imagePath = widget.entry?.imagePath;
    _audioPath = widget.entry?.audioPath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _saveEntry() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: AppColors.coral400,
        ),
      );
      return;
    }

    final entry = JournalEntry(
      id: widget.entry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      date: widget.entry?.date ?? DateTime.now(),
      imagePath: _imagePath,
      audioPath: _audioPath,
      tags: _tags,
      mood: _selectedMood,
    );

    Navigator.pop(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'New Entry' : 'Edit Entry'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveEntry),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.slate900, AppColors.slate800]
                : [AppColors.lavender50, AppColors.blue50],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Mood Selector
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How are you feeling?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _moods.map((mood) {
                        final isSelected = mood == _selectedMood;
                        return InkWell(
                          onTap: () => setState(() => _selectedMood = mood),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.lavender100
                                  : AppColors.slate50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.lavender500
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              mood,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Title
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Give your memory a title...',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'What happened today?',
                    hintText: 'Write your thoughts...',
                    border: InputBorder.none,
                  ),
                  maxLines: 10,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tags
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            decoration: const InputDecoration(
                              hintText: 'Add a tag...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addTag,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.lavender500,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => _removeTag(tag),
                            backgroundColor: AppColors.mint100,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Media buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Photo feature coming soon!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Add Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Voice recording coming soon!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.mic),
                    label: const Text('Record'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
