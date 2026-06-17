import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/journal_entry.dart';
import '../models/user.dart';
import '../models/familiar_face.dart';
import '../models/medication.dart';
import '../models/daily_routine.dart';
import '../models/safety_location.dart';
import '../models/game_progress.dart';
import '../models/chat_message.dart';
import '../models/music_track.dart';
import '../models/caregiver_alert.dart';
import '../models/activity_log.dart';
import 'database_migrator.dart';

class DatabaseHelper {
  static const int _databaseVersion = 11; // Added type to chat_messages
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  final LocalAuthentication _localAuth = LocalAuthentication();

  static bool? _isAuthenticated;

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Check if we need to migrate from unencrypted to encrypted database
    try {
      await DatabaseMigrator.migrate();
    } catch (e) {
      debugPrint('Migration error: $e');
      // Continue with new database even if migration fails
    }

    // Request biometric authentication before accessing the database
    if (_isAuthenticated == null) {
      _isAuthenticated = await _authenticateWithBiometrics();
      if (!_isAuthenticated!) {
        debugPrint(
          'Biometric authentication failed or was cancelled. Proceeding with caution.',
        );
      }
    }

    _database = await _initDB('memoriae_encrypted.db');
    return _database!;
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      // Check if device supports biometrics
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canAuthenticate || !isDeviceSupported) {
        // Skip biometric auth if not available (e.g., emulator)
        return true;
      }

      // Check if biometrics are enrolled
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        // No biometrics enrolled, skip authentication
        return true;
      }

      // Authenticate with biometrics
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your secure data',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/password as fallback
        ),
      );
    } on PlatformException catch (e) {
      print('Biometric authentication error: $e');
      // If biometric fails, allow access anyway (for development/emulator)
      return true;
    } catch (e) {
      print('Unexpected authentication error: $e');
      return true;
    }
  }

  // Get or create a secure database key
  Future<String> _getDatabaseKey() async {
    const storage = FlutterSecureStorage();
    String? key = await storage.read(key: 'db_encryption_key');

    if (key == null) {
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      key = base64Url.encode(values);
      await storage.write(key: 'db_encryption_key', value: key);
    }

    return key;
  }

  // Familiar Faces Table
  static const String tableFamiliarFaces = 'familiar_faces';

  // Column names for familiar_faces table
  static const String columnId = 'id';
  static const String columnUserId = 'userId';
  static const String columnName = 'name';
  static const String columnRelation = 'relation';
  static const String columnPhoneNumber = 'phoneNumber';
  static const String columnEmail = 'email';
  static const String columnPhotoPath = 'photoPath';
  static const String columnNotes = 'notes';
  static const String columnCreatedAt = 'createdAt';

  // Add a familiar face
  Future<FamiliarFace> createFamiliarFace(FamiliarFace face) async {
    final db = await database;
    await db.insert(
      tableFamiliarFaces,
      face.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return face;
  }

  // Get a familiar face by ID
  Future<FamiliarFace?> getFamiliarFace(String id) async {
    final db = await database;
    final maps = await db.query(
      tableFamiliarFaces,
      where: '$columnId = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return FamiliarFace.fromMap(maps.first);
    }
    return null;
  }

  // Get all familiar faces for a user
  Future<List<FamiliarFace>> getFamiliarFaces(String userId) async {
    final db = await database;
    final result = await db.query(
      tableFamiliarFaces,
      where: '$columnUserId = ?',
      whereArgs: [userId],
      orderBy: '$columnName ASC',
    );

    return result.map((json) => FamiliarFace.fromMap(json)).toList();
  }

  // Search familiar faces by name, relation, email, or phone
  Future<List<FamiliarFace>> searchFamiliarFaces(
    String userId,
    String query,
  ) async {
    if (query.isEmpty) {
      return getFamiliarFaces(userId);
    }

    final db = await database;
    final searchTerm = '%$query%';
    final result = await db.query(
      tableFamiliarFaces,
      where:
          '$columnUserId = ? AND ($columnName LIKE ? OR $columnRelation LIKE ? OR $columnEmail LIKE ? OR $columnPhoneNumber LIKE ?)',
      whereArgs: [userId, searchTerm, searchTerm, searchTerm, searchTerm],
      orderBy: '$columnName ASC',
    );

    return result.map((json) => FamiliarFace.fromMap(json)).toList();
  }

  // Update a familiar face
  Future<int> updateFamiliarFace(FamiliarFace face) async {
    final db = await database;
    return await db.update(
      tableFamiliarFaces,
      face.toMap(),
      where: '$columnId = ?',
      whereArgs: [face.id],
    );
  }

  // Delete a familiar face
  Future<int> deleteFamiliarFace(String id) async {
    final db = await database;
    return await db.delete(
      tableFamiliarFaces,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Delete all familiar faces for a user
  Future<int> deleteAllFamiliarFaces(String userId) async {
    final db = await database;
    return await db.delete(
      tableFamiliarFaces,
      where: '$columnUserId = ?',
      whereArgs: [userId],
    );
  }

  // Get ALL familiar faces (across all users) - for chatbot context
  Future<List<FamiliarFace>> getAllFamiliarFaces() async {
    final db = await database;
    final result = await db.query(
      tableFamiliarFaces,
      orderBy: '$columnName ASC',
    );
    return result.map((json) => FamiliarFace.fromMap(json)).toList();
  }

  // Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Get encryption key
    final key = await _getDatabaseKey();

    return await openDatabase(
      path,
      password: key,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Create chat_messages table if it doesn't exist
        await db.execute('''
          CREATE TABLE IF NOT EXISTS ${ChatMessage.tableName} (
            id TEXT PRIMARY KEY,
            content TEXT NOT NULL,
            isUser INTEGER NOT NULL,
            timestamp INTEGER NOT NULL,
            metadata TEXT,
            imagePath TEXT,
            type TEXT NOT NULL DEFAULT 'text'
          )
        ''');
      },
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add any version 2 schema changes here
    }
    if (oldVersion < 3) {
      // Add any version 3 schema changes here
    }
    if (oldVersion < 4) {
      // Add any version 4 schema changes here
    }
    if (oldVersion < 5) {
      // Add chat_messages table for version 5
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${ChatMessage.tableName} (
          id TEXT PRIMARY KEY,
          content TEXT NOT NULL,
          isUser INTEGER NOT NULL,
          timestamp INTEGER NOT NULL,
          metadata TEXT,
          imagePath TEXT,
          type TEXT NOT NULL DEFAULT 'text'
        )
      ''');
    }
    if (oldVersion < 8) {
      // Add Caregiver monitoring tables and columns
      try {
        await db.execute('ALTER TABLE users ADD COLUMN linkedCaregiverId TEXT');
      } catch (e) {
        debugPrint(
          'Column linkedCaregiverId migration exception (likely exists): $e',
        );
      }
      try {
        await _createCaregiversTable(db);
      } catch (_) {}
      try {
        await _createActivityLogsTable(db);
      } catch (_) {}
      try {
        await _createCaregiverAlertsTable(db);
      } catch (_) {}
      try {
        await _createEngagementScoresTable(db);
      } catch (_) {}
      try {
        await _createAuditLogsTable(db);
      } catch (_) {}
    }
    if (oldVersion < 10) {
      // Add therapyCount and feedbackCount to engagement_scores
      try {
        await db.execute(
          'ALTER TABLE engagement_scores ADD COLUMN therapyCount INTEGER NOT NULL DEFAULT 0',
        );
      } catch (e) {
        debugPrint(
          'Column therapyCount migration exception (likely exists): $e',
        );
      }
      try {
        await db.execute(
          'ALTER TABLE engagement_scores ADD COLUMN feedbackCount INTEGER NOT NULL DEFAULT 0',
        );
      } catch (e) {
        debugPrint(
          'Column feedbackCount migration exception (likely exists): $e',
        );
      }
    }
    if (oldVersion < 11) {
      // Add columns to chat_messages
      try {
        await db.execute(
          'ALTER TABLE ${ChatMessage.tableName} ADD COLUMN imagePath TEXT',
        );
      } catch (e) {
        debugPrint('Column imagePath migration exception: $e');
      }
      try {
        await db.execute(
          'ALTER TABLE ${ChatMessage.tableName} ADD COLUMN type TEXT NOT NULL DEFAULT "text"',
        );
      } catch (e) {
        debugPrint('Column type migration exception: $e');
      }
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const intTypeNullable = 'INTEGER';

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        email $textType,
        name $textType,
        age $intTypeNullable,
        profileImagePath $textTypeNullable,
        createdAt $intType,
        lastLoginAt $intType,
        isGuest $intType,
        isActive $intType,
        linkedCaregiverId $textTypeNullable
      )
    ''');

    // User credentials table
    await db.execute('''
      CREATE TABLE user_credentials (
        userId $textType,
        passwordHash $textType,
        salt $textType,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Journal entries table
    await db.execute('''
      CREATE TABLE journal_entries (
        id $idType,
        title $textType,
        content $textType,
        date $intType,
        imagePath $textTypeNullable,
        imagesPaths $textTypeNullable,
        audioPath $textTypeNullable,
        tags $textType,
        mood $textType
      )
    ''');

    // Create index for faster queries
    await db.execute('CREATE INDEX idx_date ON journal_entries(date)');

    // Create Phase 3 tables
    await _createFamiliarFacesTable(db);
    await _createMedicationsTable(db);
    await _createDailyRoutinesTable(db);
    await _createSafetyLocationsTable(db);
    await _createGameProgressTable(db);
    await _createMusicTracksTable(db);

    // Create Caregiver Monitoring tables
    await _createCaregiversTable(db);
    await _createActivityLogsTable(db);
    await _createCaregiverAlertsTable(db);
    await _createEngagementScoresTable(db);
    await _createAuditLogsTable(db);
  }

  // Create
  Future<void> createEntry(JournalEntry entry) async {
    final db = await instance.database;
    await db.insert(
      'journal_entries',
      _entryToMap(entry),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read all
  Future<List<JournalEntry>> readAllEntries() async {
    final db = await instance.database;
    const orderBy = 'date DESC';
    final result = await db.query('journal_entries', orderBy: orderBy);
    return result.map((json) => _entryFromMap(json)).toList();
  }

  // Read by ID
  Future<JournalEntry?> readEntry(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return _entryFromMap(maps.first);
    }
    return null;
  }

  // Update
  Future<void> updateEntry(JournalEntry entry) async {
    final db = await instance.database;
    await db.update(
      'journal_entries',
      _entryToMap(entry),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  // Delete
  Future<void> deleteEntry(String id) async {
    final db = await instance.database;
    await db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
  }

  // Search
  Future<List<JournalEntry>> searchEntries(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'journal_entries',
      where: 'title LIKE ? OR content LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'date DESC',
    );
    return result.map((json) => _entryFromMap(json)).toList();
  }

  // Filter by mood
  Future<List<JournalEntry>> filterByMood(String mood) async {
    final db = await instance.database;
    final result = await db.query(
      'journal_entries',
      where: 'mood = ?',
      whereArgs: [mood],
      orderBy: 'date DESC',
    );
    return result.map((json) => _entryFromMap(json)).toList();
  }

  // Filter by date range
  Future<List<JournalEntry>> filterByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'journal_entries',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );
    return result.map((json) => _entryFromMap(json)).toList();
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await instance.database;

    // Total entries
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM journal_entries',
    );
    final totalEntries = Sqflite.firstIntValue(countResult) ?? 0;

    // Entries this week
    final weekAgo = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    final weekResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM journal_entries WHERE date > ?',
      [weekAgo],
    );
    final entriesThisWeek = Sqflite.firstIntValue(weekResult) ?? 0;

    // Entries this month
    final monthAgo = DateTime.now()
        .subtract(const Duration(days: 30))
        .millisecondsSinceEpoch;
    final monthResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM journal_entries WHERE date > ?',
      [monthAgo],
    );
    final entriesThisMonth = Sqflite.firstIntValue(monthResult) ?? 0;

    // Most used mood
    final moodResult = await db.rawQuery('''
      SELECT mood, COUNT(*) as count 
      FROM journal_entries 
      GROUP BY mood 
      ORDER BY count DESC 
      LIMIT 1
    ''');
    final mostUsedMood = moodResult.isNotEmpty
        ? moodResult.first['mood'] as String
        : '😊';

    // Top tags
    final entries = await readAllEntries();
    final tagCounts = <String, int>{};
    for (var entry in entries) {
      for (var tag in entry.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    final topTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTagsList = topTags.take(5).map((e) => e.key).toList();

    return {
      'totalEntries': totalEntries,
      'entriesThisWeek': entriesThisWeek,
      'entriesThisMonth': entriesThisMonth,
      'mostUsedMood': mostUsedMood,
      'topTags': topTagsList,
    };
  }

  // Helper methods
  Map<String, dynamic> _entryToMap(JournalEntry entry) {
    return {
      'id': entry.id,
      'title': entry.title,
      'content': entry.content,
      'date': entry.date.millisecondsSinceEpoch,
      'imagePath': entry.imagePath,
      'imagesPaths': entry.imagesPaths.join('|||'),
      'audioPath': entry.audioPath,
      'tags': entry.tags.join(','),
      'mood': entry.mood,
    };
  }

  JournalEntry _entryFromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      imagePath: map['imagePath'] as String?,
      imagesPaths: (map['imagesPaths'] as String?)?.isEmpty ?? true
          ? []
          : (map['imagesPaths'] as String).split('|||'),
      audioPath: map['audioPath'] as String?,
      tags: (map['tags'] as String).isEmpty
          ? []
          : (map['tags'] as String).split(','),
      mood: map['mood'] as String,
    );
  }

  // User CRUD operations
  Future<void> createUser(User user, String? passwordHash, String? salt) async {
    final db = await instance.database;
    await db.insert('users', user.toMap());

    if (!user.isGuest && passwordHash != null && salt != null) {
      await db.insert('user_credentials', {
        'userId': user.id,
        'passwordHash': passwordHash,
        'salt': salt,
      });
    }
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(String userId) async {
    final db = await instance.database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [userId]);

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<Map<String, String>?> getUserCredentials(String userId) async {
    final db = await instance.database;
    final maps = await db.query(
      'user_credentials',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return {
        'passwordHash': maps.first['passwordHash'] as String,
        'salt': maps.first['salt'] as String,
      };
    }
    return null;
  }

  Future<void> updateUser(User user) async {
    final db = await instance.database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> updateUserPassword(
    String userId,
    String passwordHash,
    String salt,
  ) async {
    final db = await instance.database;
    await db.update(
      'user_credentials',
      {'passwordHash': passwordHash, 'salt': salt},
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteUser(String userId) async {
    final db = await instance.database;
    await db.delete(
      'user_credentials',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  // ==================== PHASE 3: NEW TABLES ====================

  // Familiar Faces Table
  Future<void> _createFamiliarFacesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableFamiliarFaces (
        $columnId TEXT PRIMARY KEY,
        $columnUserId TEXT NOT NULL,
        $columnName TEXT NOT NULL,
        $columnRelation TEXT NOT NULL,
        $columnPhoneNumber TEXT,
        $columnEmail TEXT,
        $columnPhotoPath TEXT,
        $columnNotes TEXT,
        $columnCreatedAt INTEGER NOT NULL,
        FOREIGN KEY ($columnUserId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  // Medications Table
  Future _createMedicationsTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE medications (
        id $idType,
        userId $textType,
        name $textType,
        dosage $textType,
        frequency $textType,
        timeOfDay $textType,
        notes $textTypeNullable,
        isActive $intType,
        createdAt $intType
      )
    ''');
  }

  // Daily Routines Table
  Future _createDailyRoutinesTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE daily_routines (
        id $idType,
        userId $textType,
        title $textType,
        description $textType,
        time $textType,
        days $textType,
        isActive $intType,
        createdAt $intType
      )
    ''');
  }

  // Safety Locations Table
  Future _createSafetyLocationsTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE safety_locations (
        id $idType,
        userId $textType,
        name $textType,
        address $textType,
        latitude $realType,
        longitude $realType,
        radius $realType,
        isHome $intType,
        createdAt $intType
      )
    ''');
  }

  // Game Progress Table
  Future _createGameProgressTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE game_progress (
        id $idType,
        userId $textType,
        gameType $textType,
        score $intType,
        completedAt $intType,
        duration $intType
      )
    ''');

    await db.execute('CREATE INDEX idx_game_type ON game_progress(gameType)');
    await db.execute(
      'CREATE INDEX idx_completed_at ON game_progress(completedAt)',
    );
  }

  // ==================== FAMILIAR FACES CRUD ====================
  // Note: Familiar faces CRUD methods are defined earlier in this file (lines ~150-230)
  // to avoid duplication with the main implementation that uses proper table constants.

  // ==================== MEDICATIONS CRUD ====================

  Future<void> createMedication(Medication medication) async {
    final db = await instance.database;
    await db.insert(
      'medications',
      medication.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Medication>> getMedications(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'medications',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return result.map((map) => Medication.fromMap(map)).toList();
  }

  Future<Medication?> getMedication(String id) async {
    final db = await instance.database;
    final result = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? Medication.fromMap(result.first) : null;
  }

  Future<void> updateMedication(Medication medication) async {
    final db = await instance.database;
    await db.update(
      'medications',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  Future<void> deleteMedication(String id) async {
    final db = await instance.database;
    await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  // Get ALL medications (across all users) - for chatbot context
  Future<List<Medication>> getAllMedications() async {
    final db = await instance.database;
    final result = await db.query('medications', orderBy: 'name ASC');
    return result.map((map) => Medication.fromMap(map)).toList();
  }

  // ==================== DAILY ROUTINES CRUD ====================

  Future<void> createDailyRoutine(DailyRoutine routine) async {
    final db = await instance.database;
    await db.insert(
      'daily_routines',
      routine.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DailyRoutine>> getDailyRoutines(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'daily_routines',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'time ASC',
    );
    return result.map((map) => DailyRoutine.fromMap(map)).toList();
  }

  Future<DailyRoutine?> getDailyRoutine(String id) async {
    final db = await instance.database;
    final result = await db.query(
      'daily_routines',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? DailyRoutine.fromMap(result.first) : null;
  }

  Future<void> updateDailyRoutine(DailyRoutine routine) async {
    final db = await instance.database;
    await db.update(
      'daily_routines',
      routine.toMap(),
      where: 'id = ?',
      whereArgs: [routine.id],
    );
  }

  Future<void> deleteDailyRoutine(String id) async {
    final db = await instance.database;
    await db.delete('daily_routines', where: 'id = ?', whereArgs: [id]);
  }

  // Get ALL daily routines (across all users) - for chatbot context
  Future<List<DailyRoutine>> getAllDailyRoutines() async {
    final db = await instance.database;
    final result = await db.query('daily_routines', orderBy: 'time ASC');
    return result.map((map) => DailyRoutine.fromMap(map)).toList();
  }

  // ==================== SAFETY LOCATIONS CRUD ====================

  Future<void> createSafetyLocation(SafetyLocation location) async {
    final db = await instance.database;
    await db.insert(
      'safety_locations',
      location.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SafetyLocation>> getSafetyLocations(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'safety_locations',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return result.map((map) => SafetyLocation.fromMap(map)).toList();
  }

  Future<SafetyLocation?> getSafetyLocation(String id) async {
    final db = await instance.database;
    final result = await db.query(
      'safety_locations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? SafetyLocation.fromMap(result.first) : null;
  }

  Future<void> updateSafetyLocation(SafetyLocation location) async {
    final db = await instance.database;
    await db.update(
      'safety_locations',
      location.toMap(),
      where: 'id = ?',
      whereArgs: [location.id],
    );
  }

  Future<void> deleteSafetyLocation(String id) async {
    final db = await instance.database;
    await db.delete('safety_locations', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CHAT MESSAGES CRUD ====================

  Future<void> insertChatMessage(ChatMessage message) async {
    final db = await instance.database;
    await db.insert(
      ChatMessage.tableName,
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatMessage>> getChatMessages({int limit = 100}) async {
    final db = await instance.database;
    final result = await db.query(
      ChatMessage.tableName,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return result
        .map((map) => ChatMessage.fromMap(map))
        .toList()
        .reversed
        .toList();
  }

  Future<void> deleteChatMessage(String id) async {
    final db = await instance.database;
    await db.delete(ChatMessage.tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearChatHistory() async {
    final db = await instance.database;
    await db.delete(ChatMessage.tableName);
  }

  // Get ALL reminders (basic implementation)
  Future<List<Map<String, dynamic>>> getAllReminders() async {
    // For now, return empty list - you can implement reminders table later
    return [];
  }

  // ==================== GAME PROGRESS CRUD ====================

  Future<void> saveGameProgress(GameProgress progress) async {
    final db = await instance.database;
    await db.insert(
      'game_progress',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<GameProgress>> getGameProgress(
    String userId, [
    String? gameType,
  ]) async {
    final db = await instance.database;
    if (gameType != null) {
      final result = await db.query(
        'game_progress',
        where: 'userId = ? AND gameType = ?',
        whereArgs: [userId, gameType],
        orderBy: 'completedAt DESC',
      );
      return result.map((map) => GameProgress.fromMap(map)).toList();
    }
    final result = await db.query(
      'game_progress',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'completedAt DESC',
    );
    return result.map((map) => GameProgress.fromMap(map)).toList();
  }

  Future<List<GameProgress>> getHighScores(
    String userId,
    String gameType, {
    int limit = 10,
  }) async {
    final db = await instance.database;
    final result = await db.query(
      'game_progress',
      where: 'userId = ? AND gameType = ?',
      whereArgs: [userId, gameType],
      orderBy: 'score DESC',
      limit: limit,
    );
    return result.map((map) => GameProgress.fromMap(map)).toList();
  }

  Future<void> deleteGameProgress(String id) async {
    final db = await instance.database;
    await db.delete('game_progress', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== MUSIC TRACKS CRUD ====================

  // Music Tracks Table
  Future<void> _createMusicTracksTable(Database db) async {
    await db.execute('''
      CREATE TABLE music_tracks(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        filePath TEXT NOT NULL,
        type TEXT NOT NULL,
        dateAdded TEXT NOT NULL,
        duration INTEGER,
        subtitle TEXT,
        icon TEXT,
        colorValue INTEGER
      )
    ''');
  }

  // CRUD for Music Tracks
  Future<void> createMusicTrack(MusicTrack track) async {
    final db = await database;
    await db.insert(
      'music_tracks',
      track.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MusicTrack>> getAllMusicTracks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'music_tracks',
      orderBy: 'dateAdded DESC',
    );
    return List.generate(maps.length, (i) => MusicTrack.fromJson(maps[i]));
  }

  Future<MusicTrack?> getMusicTrack(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'music_tracks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return MusicTrack.fromJson(maps.first);
    }
    return null;
  }

  Future<void> updateMusicTrack(MusicTrack track) async {
    final db = await database;
    await db.update(
      'music_tracks',
      track.toJson(),
      where: 'id = ?',
      whereArgs: [track.id],
    );
  }

  Future<void> deleteMusicTrack(String id) async {
    final db = await database;
    await db.delete('music_tracks', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CAREGIVER CRUD ====================

  Future<void> insertCaregiver(Map<String, dynamic> caregiver) async {
    final db = await instance.database;
    await db.insert(
      'caregivers',
      caregiver,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCaregiver(String id) async {
    final db = await instance.database;
    final maps = await db.query('caregivers', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? maps.first : null;
  }

  // ==================== ACTIVITY LOGS CRUD ====================

  Future<void> insertActivityLog(ActivityLog log) async {
    final db = await instance.database;
    await db.insert(
      'activity_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ActivityLog>> getActivityLogs(
    String patientId, {
    int? limit,
  }) async {
    final db = await instance.database;
    final result = await db.query(
      'activity_logs',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return result.map((map) => ActivityLog.fromMap(map)).toList();
  }

  // ==================== CAREGIVER ALERTS CRUD ====================

  Future<void> insertCaregiverAlert(CaregiverAlert alert) async {
    final db = await instance.database;
    await db.insert(
      'caregiver_alerts',
      alert.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CaregiverAlert>> getCaregiverAlerts(String patientId) async {
    final db = await instance.database;
    final result = await db.query(
      'caregiver_alerts',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => CaregiverAlert.fromMap(map)).toList();
  }

  Future<void> resolveAlert(String alertId) async {
    final db = await instance.database;
    await db.update(
      'caregiver_alerts',
      {'isResolved': 1},
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }

  // ==================== ENGAGEMENT SCORES CRUD ====================

  Future<void> insertEngagementScore(Map<String, dynamic> score) async {
    final db = await instance.database;
    await db.insert(
      'engagement_scores',
      score,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getEngagementHistory(
    String patientId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'engagement_scores',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'date DESC',
    );
  }

  // Close database
  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // ==================== CAREGIVER MONITORING TABLES ====================

  Future<void> _createCaregiversTable(Database db) async {
    await db.execute('''
      CREATE TABLE caregivers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        isVerified INTEGER NOT NULL,
        passwordHash TEXT,
        salt TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createActivityLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE activity_logs (
        id TEXT PRIMARY KEY,
        activityType TEXT NOT NULL,
        description TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        durationSeconds INTEGER NOT NULL,
        patientId TEXT NOT NULL,
        FOREIGN KEY (patientId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createCaregiverAlertsTable(Database db) async {
    await db.execute('''
      CREATE TABLE caregiver_alerts (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        message TEXT NOT NULL,
        severity TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isResolved INTEGER NOT NULL,
        patientId TEXT NOT NULL,
        FOREIGN KEY (patientId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createEngagementScoresTable(Database db) async {
    await db.execute('''
      CREATE TABLE engagement_scores (
        id TEXT PRIMARY KEY,
        patientId TEXT NOT NULL,
        date TEXT NOT NULL,
        score REAL NOT NULL,
        chatCount INTEGER NOT NULL,
        journalCount INTEGER NOT NULL,
        gameCount INTEGER NOT NULL,
        therapyCount INTEGER NOT NULL DEFAULT 0,
        feedbackCount INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (patientId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createAuditLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        caregiverId TEXT NOT NULL,
        action TEXT NOT NULL,
        details TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  // ==================== AUDIT LOGS CRUD ====================

  Future<void> insertAuditLog(dynamic log) async {
    final db = await instance.database;
    await db.insert(
      'audit_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<dynamic>> getAuditLogs({String? caregiverId}) async {
    final db = await instance.database;
    final result = caregiverId != null
        ? await db.query(
            'audit_logs',
            where: 'caregiverId = ?',
            whereArgs: [caregiverId],
            orderBy: 'timestamp DESC',
          )
        : await db.query('audit_logs', orderBy: 'timestamp DESC');

    // We'll trust the AuditLoggingService to handle the conversion
    return result;
  }

  // ==================== CAREGIVER CRUD ====================

  Future<Map<String, dynamic>?> getCaregiverByEmail(String email) async {
    final db = await instance.database;
    final result = await db.query(
      'caregivers',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<Map<String, dynamic>?> getCaregiverById(String id) async {
    final db = await instance.database;
    final result = await db.query(
      'caregivers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<Map<String, String>?> getCaregiverCredentials(String id) async {
    final db = await instance.database;
    final result = await db.query(
      'caregivers',
      columns: ['passwordHash', 'salt'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty && result.first['passwordHash'] != null) {
      return {
        'passwordHash': result.first['passwordHash'] as String,
        'salt': result.first['salt'] as String,
      };
    }
    return null;
  }
}
