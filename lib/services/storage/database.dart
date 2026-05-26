import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Central database manager for Narratiq.
/// Single SQLite database with all tables.
/// Use DatabaseHelper.instance to access — never instantiate directly.
class DatabaseHelper {
  static const String _dbName = 'narratiq.db';
  static const int _dbVersion = 1;

  // Table names
  static const String tableBooks = 'books';
  static const String tableBookProfiles = 'book_profiles';
  static const String tableBookmarks = 'bookmarks';
  static const String tableChapters = 'chapters';
  static const String tablePronunciations = 'pronunciations';

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Books table
    await db.execute('''
      CREATE TABLE $tableBooks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        filePath TEXT NOT NULL,
        fileType TEXT NOT NULL,
        coverImagePath TEXT,
        totalChapters INTEGER NOT NULL DEFAULT 0,
        totalSentences INTEGER NOT NULL DEFAULT 0,
        importedAt INTEGER NOT NULL,
        lastOpenedAt INTEGER,
        currentChapterIndex INTEGER NOT NULL DEFAULT 0,
        currentSentenceIndex INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Book profiles table — stores full JSON of BookProfile
    await db.execute('''
      CREATE TABLE $tableBookProfiles (
        bookId TEXT PRIMARY KEY,
        profileJson TEXT NOT NULL,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (bookId) REFERENCES $tableBooks(id) ON DELETE CASCADE
      )
    ''');

    // Chapters table — stores sentences as JSON array
    await db.execute('''
      CREATE TABLE $tableChapters (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        chapterIndex INTEGER NOT NULL,
        title TEXT NOT NULL,
        sentencesJson TEXT NOT NULL,
        startSentenceIndex INTEGER NOT NULL,
        FOREIGN KEY (bookId) REFERENCES $tableBooks(id) ON DELETE CASCADE
      )
    ''');

    // Bookmarks table
    await db.execute('''
      CREATE TABLE $tableBookmarks (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        label TEXT,
        chapterIndex INTEGER NOT NULL,
        sentenceIndex INTEGER NOT NULL,
        sentencePreview TEXT NOT NULL,
        isAutoSave INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (bookId) REFERENCES $tableBooks(id) ON DELETE CASCADE
      )
    ''');

    // Per-book pronunciation corrections
    await db.execute('''
      CREATE TABLE $tablePronunciations (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        originalWord TEXT NOT NULL,
        pronunciation TEXT NOT NULL,
        FOREIGN KEY (bookId) REFERENCES $tableBooks(id) ON DELETE CASCADE
      )
    ''');

    // Indexes for fast lookups
    await db.execute('CREATE INDEX idx_chapters_bookId ON $tableChapters(bookId)');
    await db.execute('CREATE INDEX idx_bookmarks_bookId ON $tableBookmarks(bookId)');
    await db.execute('CREATE INDEX idx_pronunciations_bookId ON $tablePronunciations(bookId)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  /// Encode a map to JSON string for storage.
  static String encodeJson(Map<String, dynamic> map) => jsonEncode(map);

  /// Decode a JSON string from storage.
  static Map<String, dynamic> decodeJson(String json) =>
      jsonDecode(json) as Map<String, dynamic>;

  /// Close the database — call on app dispose.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
