import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'auth_service.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Analytics data model for user activity and behavior
class UserAnalytics {
  // User Identity
  final String userId;
  final String name;
  final int? age;
  final String? gender;
  final String userType;
  final Duration accountAge;
  
  // Chat Activity
  final int totalChats;
  final double avgChatsPerDay;
  final double avgChatsPerWeek;
  final Map<int, int> chatsByHour; // Hour -> count
  final int chatStreak;
  
  // Engagement Metrics
  final Duration totalTimeSpent;
  final int sessionCount;
  final double avgSessionDuration;
  final int currentStreak;
  final int longestStreak;
  
  // Content & Media
  final int journalEntries;
  final Map<String, int> moodDistribution;
  final List<String> topTags;
  final int gamesPlayed;
  final Map<String, int> gamesByType;
  
  // Progress Trends
  final Map<String, dynamic> weeklyTrends;
  final Map<String, dynamic> monthlyTrends;
  final List<Map<String, dynamic>> engagementHistory; // For graphs
  
  UserAnalytics({
    required this.userId,
    required this.name,
    this.age,
    this.gender,
    required this.userType,
    required this.accountAge,
    required this.totalChats,
    required this.avgChatsPerDay,
    required this.avgChatsPerWeek,
    required this.chatsByHour,
    required this.chatStreak,
    required this.totalTimeSpent,
    required this.sessionCount,
    required this.avgSessionDuration,
    required this.currentStreak,
    required this.longestStreak,
    required this.journalEntries,
    required this.moodDistribution,
    required this.topTags,
    required this.gamesPlayed,
    required this.gamesByType,
    required this.weeklyTrends,
    required this.monthlyTrends,
    required this.engagementHistory,
  });
}

class AnalyticsService extends ChangeNotifier {
  static final AnalyticsService instance = AnalyticsService._init();
  AnalyticsService._init();

  UserAnalytics? _cachedAnalytics;
  DateTime? _lastCacheTime;
  static const _cacheValidity = Duration(minutes: 5);

  /// Get comprehensive user analytics
  Future<UserAnalytics> getUserAnalytics() async {
    // Return cached data if valid
    if (_cachedAnalytics != null && 
        _lastCacheTime != null && 
        DateTime.now().difference(_lastCacheTime!) < _cacheValidity) {
      return _cachedAnalytics!;
    }

    final user = await AuthService.instance.getCurrentUser();
    if (user == null) {
      throw Exception('No authenticated user');
    }

    final db = DatabaseHelper.instance;
    
    // Gather all analytics data
    final analytics = UserAnalytics(
      userId: user.id,
      name: user.name,
      age: user.age,
      gender: null, // Not stored yet
      userType: user.isGuest ? 'Guest User' : 'Patient',
      accountAge: DateTime.now().difference(user.createdAt),
      
      // Chat analytics
      totalChats: await _getTotalChats(),
      avgChatsPerDay: await _getAvgChatsPerDay(user.createdAt),
      avgChatsPerWeek: await _getAvgChatsPerWeek(user.createdAt),
      chatsByHour: await _getChatsByHour(),
      chatStreak: await _getChatStreak(),
      
      // Engagement metrics
      totalTimeSpent: await _estimateTotalTimeSpent(),
      sessionCount: await _getSessionCount(),
      avgSessionDuration: await _getAvgSessionDuration(),
      currentStreak: await _getCurrentStreak(),
      longestStreak: await _getLongestStreak(),
      
      // Content & Media
      journalEntries: await _getJournalEntryCount(),
      moodDistribution: await _getMoodDistribution(),
      topTags: await _getTopTags(),
      gamesPlayed: await _getTotalGamesPlayed(user.id),
      gamesByType: await _getGamesByType(user.id),
      
      // Progress trends
      weeklyTrends: await _getWeeklyTrends(user.id),
      monthlyTrends: await _getMonthlyTrends(user.id),
      engagementHistory: await _getEngagementHistory(user.id),
    );

    // Cache the results
    _cachedAnalytics = analytics;
    _lastCacheTime = DateTime.now();
    
    return analytics;
  }

  /// Force refresh analytics (clear cache)
  void invalidateCache() {
    _cachedAnalytics = null;
    _lastCacheTime = null;
    notifyListeners();
  }

  // ==================== CHAT ANALYTICS ====================
  
  Future<int> _getTotalChats() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM chat_messages WHERE isUser = 1');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('Error getting total chats: $e');
      return 0;
    }
  }

  Future<double> _getAvgChatsPerDay(DateTime createdAt) async {
    final totalChats = await _getTotalChats();
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays + 1;
    return totalChats / daysSinceCreation;
  }

  Future<double> _getAvgChatsPerWeek(DateTime createdAt) async {
    final avgPerDay = await _getAvgChatsPerDay(createdAt);
    return avgPerDay * 7;
  }

  Future<Map<int, int>> _getChatsByHour() async {
    try {
      final db = await DatabaseHelper.instance.database;
      // SQLite unixepoch uses seconds. Convert milliseconds -> seconds and format hour in local time context
      final result = await db.rawQuery('''
        SELECT strftime('%H', datetime(timestamp / 1000, 'unixepoch', 'localtime')) as hour, 
               COUNT(*) as count 
        FROM chat_messages 
        WHERE isUser = 1 
        GROUP BY hour
      ''');
      
      final hourCounts = <int, int>{};
      for (var row in result) {
        if (row['hour'] != null && row['count'] != null) {
          int hour = int.parse(row['hour'].toString());
          hourCounts[hour] = int.parse(row['count'].toString());
        }
      }
      return hourCounts;
    } catch (e) {
      debugPrint('Error getting chats by hour: $e');
      return {};
    }
  }

  Future<int> _getChatStreak() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery('''
        SELECT DISTINCT date(timestamp / 1000, 'unixepoch', 'localtime') as day_date
        FROM chat_messages 
        WHERE isUser = 1 
        ORDER BY day_date DESC
      ''');
      
      if (result.isEmpty) return 0;
      
      final dates = result.map((r) => DateTime.parse(r['day_date'] as String)).toList();
      
      int streak = 0;
      DateTime expectedDate = DateTime.now();
      expectedDate = DateTime(expectedDate.year, expectedDate.month, expectedDate.day);
      
      for (var date in dates) {
        if (date.isAtSameMomentAs(expectedDate) || 
            date.isAtSameMomentAs(expectedDate.subtract(const Duration(days: 1)))) {
          streak++;
          expectedDate = date.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      
      return streak;
    } catch (e) {
      debugPrint('Error calculating chat streak: $e');
      return 0;
    }
  }

  // ==================== ENGAGEMENT METRICS ====================
  
  Future<Duration> _estimateTotalTimeSpent() async {
    // Estimate based on number of interactions
    // Assume average session = 15 minutes, average chat = 2 minutes
    final chats = await _getTotalChats();
    final journals = await _getJournalEntryCount();
    final games = await _getTotalGamesPlayed(
      (await AuthService.instance.getCurrentUser())?.id ?? ''
    );
    
    final estimatedMinutes = (chats * 2) + (journals * 10) + (games * 5);
    return Duration(minutes: estimatedMinutes);
  }

  Future<int> _getSessionCount() async {
    // Approximate sessions based on message clusters
    // Messages within 30 minutes = same session
    try {
      final messages = await DatabaseHelper.instance.getChatMessages(limit: 10000);
      if (messages.isEmpty) return 0;
      
      int sessions = 1;
      for (int i = 1; i < messages.length; i++) {
        final timeDiff = messages[i].dateTime.difference(messages[i-1].dateTime);
        if (timeDiff.inMinutes > 30) {
          sessions++;
        }
      }
      return sessions;
    } catch (e) {
      debugPrint('Error counting sessions: $e');
      return 0;
    }
  }

  Future<double> _getAvgSessionDuration() async {
    final totalTime = await _estimateTotalTimeSpent();
    final sessions = await _getSessionCount();
    if (sessions == 0) return 0;
    return totalTime.inMinutes / sessions;
  }

  Future<int> _getCurrentStreak() async {
    return await _getChatStreak(); // Using chat streak as current streak
  }

  Future<int> _getLongestStreak() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery('''
        SELECT DISTINCT date(timestamp / 1000, 'unixepoch', 'localtime') as day_date
        FROM chat_messages 
        WHERE isUser = 1 
        ORDER BY day_date ASC
      ''');
      
      if (result.isEmpty) return 0;
      
      final dates = result.map((r) => DateTime.parse(r['day_date'] as String)).toList();
      
      int maxStreak = 0;
      int currentStreak = 1;
      
      for (int i = 1; i < dates.length; i++) {
        if (dates[i].difference(dates[i-1]).inDays == 1) {
          currentStreak++;
        } else {
          maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
          currentStreak = 1;
        }
      }
      maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
      
      return maxStreak;
    } catch (e) {
      debugPrint('Error calculating longest streak: $e');
      return 0;
    }
  }

  // ==================== CONTENT & MEDIA ====================
  
  Future<int> _getJournalEntryCount() async {
    try {
      final entries = await DatabaseHelper.instance.readAllEntries();
      return entries.length;
    } catch (e) {
      debugPrint('Error getting journal count: $e');
      return 0;
    }
  }

  Future<Map<String, int>> _getMoodDistribution() async {
    try {
      final entries = await DatabaseHelper.instance.readAllEntries();
      final moodCounts = <String, int>{};
      
      for (var entry in entries) {
        moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
      }
      
      return moodCounts;
    } catch (e) {
      debugPrint('Error getting mood distribution: $e');
      return {};
    }
  }

  Future<List<String>> _getTopTags() async {
    try {
      final entries = await DatabaseHelper.instance.readAllEntries();
      final tagCounts = <String, int>{};
      
      for (var entry in entries) {
        for (var tag in entry.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
      
      final sorted = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return sorted.take(5).map((e) => e.key).toList();
    } catch (e) {
      debugPrint('Error getting top tags: $e');
      return [];
    }
  }

  Future<int> _getTotalGamesPlayed(String userId) async {
    try {
      final progress = await DatabaseHelper.instance.getGameProgress(userId);
      return progress.length;
    } catch (e) {
      debugPrint('Error getting games played: $e');
      return 0;
    }
  }

  Future<Map<String, int>> _getGamesByType(String userId) async {
    try {
      final progress = await DatabaseHelper.instance.getGameProgress(userId);
      final typeCounts = <String, int>{};
      
      for (var game in progress) {
        typeCounts[game.gameType] = (typeCounts[game.gameType] ?? 0) + 1;
      }
      
      return typeCounts;
    } catch (e) {
      debugPrint('Error getting games by type: $e');
      return {};
    }
  }

  // ==================== PROGRESS TRENDS ====================
  
  Future<Map<String, dynamic>> _getWeeklyTrends(String userId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    try {
      final messages = await DatabaseHelper.instance.getChatMessages(limit: 10000);
      final recentMessages = messages.where((m) => 
        m.isUser && m.dateTime.isAfter(weekAgo)
      ).length;
      
      final journals = await DatabaseHelper.instance.filterByDateRange(weekAgo, now);
      final games = await DatabaseHelper.instance.getGameProgress(userId);
      final recentGames = games.where((g) => g.completedAt.isAfter(weekAgo)).length;
      
      return {
        'chats': recentMessages,
        'journals': journals.length,
        'games': recentGames,
      };
    } catch (e) {
      debugPrint('Error getting weekly trends: $e');
      return {'chats': 0, 'journals': 0, 'games': 0};
    }
  }

  Future<Map<String, dynamic>> _getMonthlyTrends(String userId) async {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    
    try {
      final messages = await DatabaseHelper.instance.getChatMessages(limit: 10000);
      final recentMessages = messages.where((m) => 
        m.isUser && m.dateTime.isAfter(monthAgo)
      ).length;
      
      final journals = await DatabaseHelper.instance.filterByDateRange(monthAgo, now);
      final games = await DatabaseHelper.instance.getGameProgress(userId);
      final recentGames = games.where((g) => g.completedAt.isAfter(monthAgo)).length;
      
      return {
        'chats': recentMessages,
        'journals': journals.length,
        'games': recentGames,
      };
    } catch (e) {
      debugPrint('Error getting monthly trends: $e');
      return {'chats': 0, 'journals': 0, 'games': 0};
    }
  }

  Future<List<Map<String, dynamic>>> _getEngagementHistory(String userId) async {
    // Get daily engagement for the last 30 days
    final now = DateTime.now();
    final history = <Map<String, dynamic>>[];
    
    try {
      final messages = await DatabaseHelper.instance.getChatMessages(limit: 10000);
      final journals = await DatabaseHelper.instance.readAllEntries();
      final games = await DatabaseHelper.instance.getGameProgress(userId);
      
      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        
        final dayChats = messages.where((m) => 
          m.isUser && 
          m.dateTime.isAfter(dayStart) && 
          m.dateTime.isBefore(dayEnd)
        ).length;
        
        final dayJournals = journals.where((j) => 
          j.date.isAfter(dayStart) && 
          j.date.isBefore(dayEnd)
        ).length;
        
        final dayGames = games.where((g) => 
          g.completedAt.isAfter(dayStart) && 
          g.completedAt.isBefore(dayEnd)
        ).length;
        
        history.add({
          'date': dayStart,
          'chats': dayChats,
          'journals': dayJournals,
          'games': dayGames,
          'total': dayChats + dayJournals + dayGames,
        });
      }
      
      return history;
    } catch (e) {
      debugPrint('Error getting engagement history: $e');
      return [];
    }
  }
}
