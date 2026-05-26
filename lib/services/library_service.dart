import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import '../models/book_profile.dart';
import '../models/chapter.dart';
import 'epub_parser.dart';
import 'txt_parser.dart';
import 'classifier/book_classifier.dart';
import 'storage/book_repository.dart';
import 'storage/progress_repository.dart';

/// Central service for managing the book library.
/// Handles import, classification, progress tracking, and deletion.
class LibraryService extends ChangeNotifier {
  final BookRepository _bookRepo = BookRepository();
  final ProgressRepository _progressRepo = ProgressRepository();
  final BookClassifier _classifier = BookClassifier();
  final _uuid = const Uuid();

  List<Book> _books = [];
  final Map<String, BookProfile> _profiles = {};
  final Map<String, ClassificationStatus> _classificationStatus = {};

  List<Book> get books => List.unmodifiable(_books);
  List<Book> get recentBooks => _books.take(3).toList();

  BookProfile? profileFor(String bookId) => _profiles[bookId];
  ClassificationStatus statusFor(String bookId) =>
      _classificationStatus[bookId] ?? ClassificationStatus.notStarted;

  /// Load all books from the database on app start.
  Future<void> loadLibrary() async {
    _books = await _bookRepo.getAllBooks();
    for (final book in _books) {
      final profile = await _progressRepo.getBookProfile(book.id);
      if (profile != null) _profiles[book.id] = profile;
    }
    notifyListeners();
  }

  /// Import a book file (EPUB or TXT).
  /// Parses the file, saves to DB, starts classification in background.
  Future<Book?> importBook(String filePath) async {
    try {
      final fileType = filePath.toLowerCase().endsWith('.epub') ? 'epub' : 'txt';
      final bookId = _uuid.v4();

      // Copy file to app documents directory for persistence
      final savedPath = await _copyToDocuments(filePath, bookId, fileType);

      // Parse the file
      List<Chapter> chapters;
      String title;
      String author;

      if (fileType == 'epub') {
        final result = await EpubParser().parse(savedPath);
        chapters = result.chapters;
        title = result.title;
        author = result.author;
      } else {
        final result = await TxtParser().parse(savedPath);
        chapters = result.chapters;
        title = result.title;
        author = result.author;
      }

      if (chapters.isEmpty) return null;

      final totalSentences = chapters.fold(0, (sum, c) => sum + c.sentenceCount);

      // Create and save the book
      final book = Book(
        id: bookId,
        title: title,
        author: author,
        filePath: savedPath,
        fileType: fileType,
        totalChapters: chapters.length,
        totalSentences: totalSentences,
        importedAt: DateTime.now(),
      );

      await _bookRepo.insertBook(book);
      await _bookRepo.insertChapters(bookId, chapters);

      _books.insert(0, book);
      _classificationStatus[bookId] = ClassificationStatus.running;
      notifyListeners();

      // Start classification in background
      _classifyInBackground(bookId, chapters, title, author);

      return book;
    } catch (e) {
      debugPrint('Import error: $e');
      return null;
    }
  }

  /// Run classification in background and update profile progressively.
  void _classifyInBackground(
    String bookId,
    List<Chapter> chapters,
    String title,
    String author,
  ) {
    _classifier
        .classify(
          bookId: bookId,
          chapters: chapters,
          title: title,
          author: author,
        )
        .listen(
          (profile) async {
            _profiles[bookId] = profile;
            await _progressRepo.saveBookProfile(profile);
            if (profile.isComplete) {
              _classificationStatus[bookId] = ClassificationStatus.complete;
            }
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Classification error: $e');
            _classificationStatus[bookId] = ClassificationStatus.failed;
            notifyListeners();
          },
        );
  }

  /// Save reading progress for a book.
  Future<void> saveProgress({
    required String bookId,
    required int chapterIndex,
    required int sentenceIndex,
    required String sentencePreview,
  }) async {
    await _bookRepo.updateProgress(
      bookId,
      chapterIndex: chapterIndex,
      sentenceIndex: sentenceIndex,
    );
    await _progressRepo.saveAutoPosition(
      bookId: bookId,
      chapterIndex: chapterIndex,
      sentenceIndex: sentenceIndex,
      sentencePreview: sentencePreview,
    );
    final idx = _books.indexWhere((b) => b.id == bookId);
    if (idx != -1) {
      _books[idx] = _books[idx].copyWith(
        currentChapterIndex: chapterIndex,
        currentSentenceIndex: sentenceIndex,
        lastOpenedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// Delete a book and all its data.
  Future<void> deleteBook(String bookId) async {
    final book = _books.firstWhere((b) => b.id == bookId);
    // Delete the file
    try {
      final file = File(book.filePath);
      if (await file.exists()) await file.delete();
    } catch (_) {}

    await _bookRepo.deleteBook(bookId);
    _books.removeWhere((b) => b.id == bookId);
    _profiles.remove(bookId);
    _classificationStatus.remove(bookId);
    notifyListeners();
  }

  Future<String> _copyToDocuments(
    String sourcePath,
    String bookId,
    String fileType,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final destPath = '${dir.path}/$bookId.$fileType';
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  /// Get chapters for a book from the database.
  Future<List<Chapter>> getChapters(String bookId) async {
    return _bookRepo.getChapters(bookId);
  }
}

enum ClassificationStatus { notStarted, running, complete, failed }
