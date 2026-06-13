import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DatabaseMigrator {
  static const _oldDbName = 'memoriae.db';
  static const _newDbName = 'memoriae_encrypted.db';
  
  // Check if we need to migrate from unencrypted to encrypted database
  static Future<bool> needsMigration() async {
    final dbPath = await getDatabasesPath();
    final oldDbPath = join(dbPath, _oldDbName);
    final newDbPath = join(dbPath, _newDbName);
    
    return await File(oldDbPath).exists() && !await File(newDbPath).exists();
  }
  
  // Migrate data from old unencrypted DB to new encrypted DB
  static Future<void> migrate() async {
    if (!await needsMigration()) return;
    
    final dbPath = await getDatabasesPath();
    final oldDbPath = join(dbPath, _oldDbName);
    
    // Open the old database
    final oldDb = await openDatabase(oldDbPath);
    
    try {
      // Read all data from the old database
      final users = await oldDb.query('users');
      final journalEntries = await oldDb.query('journal_entries');
      // Add other tables as needed
      
      // Close the old database
      await oldDb.close();
      
      // Create new encrypted database
      final storage = FlutterSecureStorage();
      String? key = await storage.read(key: 'db_encryption_key');
      
      if (key == null) {
        throw Exception('Encryption key not found');
      }
      
      final newDb = await openDatabase(
        join(dbPath, _newDbName),
        password: key,
        version: 4, // Match your current version
        onCreate: (db, version) async {
          // This will be called if the database doesn't exist
          // We'll create it with the same schema as before
          await _createDatabaseSchema(db);
        },
      );
      
      // Start a transaction
      await newDb.transaction((txn) async {
        // Insert users
        for (var user in users) {
          await txn.insert('users', user);
        }
        
        // Insert journal entries
        for (var entry in journalEntries) {
          await txn.insert('journal_entries', entry);
        }
        
        // Add other tables as needed
      });
      
      // Close the new database
      await newDb.close();
      
      // Optional: Backup the old database before deleting
      final appDocDir = await getApplicationDocumentsDirectory();
      final backupPath = '${appDocDir.path}/backup_${DateTime.now().millisecondsSinceEpoch}.db';
      await File(oldDbPath).copy(backupPath);
      
      // Delete the old database
      await deleteDatabase(oldDbPath);
      
    } catch (e) {
      // If anything goes wrong, close the databases and rethrow
      await oldDb.close();
      rethrow;
    }
  }
  
  // Create the database schema (same as in DatabaseHelper)
  static Future<void> _createDatabaseSchema(Database db) async {
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
        isActive $intType
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
        audioPath $textTypeNullable,
        tags $textType,
        mood $textType
      )
    ''');

    // Create index for faster queries
    await db.execute('CREATE INDEX idx_date ON journal_entries(date)');
    
    // Add other tables as needed (familiar_faces, medications, etc.)
  }
}
