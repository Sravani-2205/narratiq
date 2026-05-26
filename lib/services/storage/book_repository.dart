import '../../models/book.dart';
import '../../models/chapter.dart';
import 'database.dart';

/// Handles all database operations for Books and Chapters.
class BookRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // ─── Books ───────────────────────────────────────────────

  /// Insert a new book. Throws if id already exists.
  Future<void> insertBook(Book book) async {
    final db = await _db.database;
    await db.insert(
      DatabaseHelper.tableBooks,
      book.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a single book by id. Returns null if not found.
  Future<Book?> getBook(String id) async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseHelper.tableBooks,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Book.fromMap(maps.first);
  }

  /// Get all books, most recently opened first.
  Future<List<Book>> getAllBooks() async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseHelper.tableBooks,
      orderBy: 'lastOpenedAt DESC, importedAt DESC',
    );
    return maps.map(Book.fromMap).toList();
  }

  /// Get the most recently opened books (for library top section).
  Future<List<Book>> getRecentBooks({int limit = 3}) async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseHelper.tableBooks,
      where: 'lastOpenedAt IS NOT NULL',
      orderBy: 'lastOpenedAt DESC',
      limit: limit,
    );
    return maps.map(Book.fromMap).toList();
  }

  /// Update reading progress for a book.
  Future<void> updateProgress(
    String bookId, {
    required int chapterIndex,
    required int sentenceIndex,
  }) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.tableBooks,
      {
        'currentChapterIndex': chapterIndex,
        'currentSentenceIndex': sentenceIndex,
        'lastOpenedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  /// Update the total sentence count after parsing is complete.
  Future<void> updateTotals(
    String bookId, {
    required int totalChapters,
    required int totalSentences,
  }) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.tableBooks,
      {
        'totalChapters': totalChapters,
        'totalSentences': totalSentences,
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  /// Mark a book as last opened now.
  Future<void> touchLastOpened(String bookId) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.tableBooks,
      {'lastOpenedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  /// Delete a book and all its associated data (cascades via FK).
  Future<void> deleteBook(String bookId) async {
    final db = await _db.database;
    await db.delete(
      DatabaseHelper.tableBooks,
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  // ─── Chapters ────────────────────────────────────────────

  /// Insert all chapters for a book in a single transaction.
  Future<void> insertChapters(String bookId, List<Chapter> chapters) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final chapter in chapters) {
      batch.insert(
        DatabaseHelper.tableChapters,
        {
          'id': '${bookId}_ch${chapter.index}',
          'bookId': bookId,
          'chapterIndex': chapter.index,
          'title': chapter.title,
          'sentencesJson': DatabaseHelper.encodeJson(
            {'sentences': chapter.sentences},
          ),
          'startSentenceIndex': chapter.startSentenceIndex,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Get all chapters for a book, ordered by index.
  Future<List<Chapter>> getChapters(String bookId) async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseHelper.tableChapters,
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'chapterIndex ASC',
    );
    return maps.map((map) {
      final sentencesData = DatabaseHelper.decodeJson(map['sentencesJson'] as String);
      return Chapter(
        index: map['chapterIndex'] as int,
        title: map['title'] as String,
        sentences: List<String>.from(sentencesData['sentences'] as List),
        startSentenceIndex: map['startSentenceIndex'] as int,
      );
    }).toList();
  }

  /// Get a single chapter by index.
  Future<Chapter?> getChapter(String bookId, int chapterIndex) async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseHelper.tableChapters,
      where: 'bookId = ? AND chapterIndex = ?',
      whereArgs: [bookId, chapterIndex],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final map = maps.first;
    final sentencesData = DatabaseHelper.decodeJson(map['sentencesJson'] as String);
    return Chapter(
      index: map['chapterIndex'] as int,
      title: map['title'] as String,
      sentences: List<String>.from(sentencesData['sentences'] as List),
      startSentenceIndex: map['startSentenceIndex'] as int,
    );
  }

  // ─── Pronunciations ──────────────────────────────────────

  /// Get pronunciation corrections for a book.
  Future<Map<String, String>> getPronunciations(String bookId) async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseHelper.tablePronunciations,
      where: 'bookId = ?',
      whereArgs: [bookId],
    );
    return {
      for (final map in maps)
        map['originalWord'] as String: map['pronunciation'] as String,
    };
  }

  /// Save a pronunciation correction.
  Future<void> savePronunciation(
    String bookId,
    String originalWord,
    String pronunciation,
  ) async {
    final db = await _db.database;
    await db.insert(
      DatabaseHelper.tablePronunciations,
      {
        'id': '${bookId}_$originalWord',
        'bookId': bookId,
        'originalWord': originalWord,
        'pronunciation': pronunciation,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
