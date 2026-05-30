import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../../models/bookmark.dart';
import '../../models/book_profile.dart';
import 'database.dart';

/// Handles bookmarks and book profiles in the database.
class ProgressRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // ─── Book Profiles ────────────────────────────────────────

  /// Save or update the BookProfile for a book.
  Future<void> saveBookProfile(BookProfile profile) async {
    final db = await _db.database;
    await db.insert(
      DatabaseHelper.tableBookProfiles,
      {
        'bookId': profile.bookId,
        'profileJson': jsonEncode(profile.toMap()),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get the BookProfile for a book. Returns null if not yet classified.
  Future<BookProfile?> getBookProfile(String bookId) async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseHelper.tableBookProfiles,
      where: 'bookId = ?',
      whereArgs: [bookId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final profileMap = jsonDecode(maps.first['profileJson'] as String)
        as Map<String, dynamic>;
    return BookProfile.fromMap(profileMap);
  }

  /// Delete the profile for a book (e.g. to force re-classification).
  Future<void> deleteBookProfile(String bookId) async {
    final db = await _db.database;
    await db.delete(
      DatabaseHelper.tableBookProfiles,
      where: 'bookId = ?',
      whereArgs: [bookId],
    );
  }

  // ─── Bookmarks ────────────────────────────────────────────

  /// Insert or replace a bookmark.
  Future<void> saveBookmark(Bookmark bookmark) async {
    final db = await _db.database;
    await db.insert(
      DatabaseHelper.tableBookmarks,
      bookmark.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all manual bookmarks for a book (excludes auto-saves),
  /// ordered by sentence position.
  Future<List<Bookmark>> getBookmarks(String bookId) async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseHelper.tableBookmarks,
      where: 'bookId = ? AND isAutoSave = 0',
      whereArgs: [bookId],
      orderBy: 'sentenceIndex ASC',
    );
    return maps.map(Bookmark.fromMap).toList();
  }

  /// Get the auto-saved last position for a book.
  Future<Bookmark?> getAutoSave(String bookId) async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseHelper.tableBookmarks,
      where: 'bookId = ? AND isAutoSave = 1',
      whereArgs: [bookId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Bookmark.fromMap(maps.first);
  }

  /// Save the auto-position bookmark — replaces any existing auto-save.
  Future<void> saveAutoPosition({
    required String bookId,
    required int chapterIndex,
    required int sentenceIndex,
    required String sentencePreview,
  }) async {
    final db = await _db.database;
    // Delete existing auto-save first
    await db.delete(
      DatabaseHelper.tableBookmarks,
      where: 'bookId = ? AND isAutoSave = 1',
      whereArgs: [bookId],
    );
    // Insert fresh auto-save
    await db.insert(
      DatabaseHelper.tableBookmarks,
      {
        'id': 'autosave_$bookId',
        'bookId': bookId,
        'label': null,
        'chapterIndex': chapterIndex,
        'sentenceIndex': sentenceIndex,
        'sentencePreview': sentencePreview,
        'isAutoSave': 1,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Delete a specific bookmark by id.
  Future<void> deleteBookmark(String bookmarkId) async {
    final db = await _db.database;
    await db.delete(
      DatabaseHelper.tableBookmarks,
      where: 'id = ?',
      whereArgs: [bookmarkId],
    );
  }

  /// Delete all manual bookmarks for a book.
  Future<void> deleteAllBookmarks(String bookId) async {
    final db = await _db.database;
    await db.delete(
      DatabaseHelper.tableBookmarks,
      where: 'bookId = ? AND isAutoSave = 0',
      whereArgs: [bookId],
    );
  }
}
