import 'dart:io';
import 'package:epubx/epubx.dart';
import '../models/chapter.dart';

/// Parses an EPUB file into a structured list of Chapters.
/// Each chapter contains a list of clean sentences ready for
/// display and TTS playback.
class EpubParser {
  /// Parse an EPUB file at [filePath].
  /// Returns a list of Chapters with sentences extracted and cleaned.
  /// Throws [EpubParseException] if the file cannot be read or parsed.
  Future<EpubParseResult> parse(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final book = await EpubReader.readBook(bytes);
      return _extractChapters(book);
    } on FileSystemException catch (e) {
      throw EpubParseException('Cannot read file: ${e.message}', filePath);
    } catch (e) {
      throw EpubParseException('Failed to parse EPUB: $e', filePath);
    }
  }

  EpubParseResult _extractChapters(EpubBook book) {
    final chapters = <Chapter>[];
    int globalSentenceIndex = 0;

    // Get spine items in reading order
    final spineItems = book.Schema?.Package?.Spine?.Items ?? [];
    final manifest = book.Schema?.Package?.Manifest?.Items ?? {};

    // Build a map of id -> content for quick lookup
    final contentMap = <String, EpubTextContentFile>{};
    for (final file in book.Content?.Html?.values ?? []) {
      contentMap[file.FileName ?? ''] = file;
    }

    // Map spine items to their manifest entries then to content files
    final orderedContent = <EpubTextContentFile>[];
    for (final spineItem in spineItems) {
      final manifestItem = manifest[spineItem.IdRef];
      if (manifestItem == null) continue;
      final href = manifestItem.Href ?? '';
      // Match by filename
      final contentFile = contentMap.values.firstWhere(
        (f) => (f.FileName ?? '').endsWith(href.split('/').last),
        orElse: () => contentMap[href] ?? EpubTextContentFile(),
      );
      if ((contentFile.Content ?? '').isNotEmpty) {
        orderedContent.add(contentFile);
      }
    }

    // If spine parsing yielded nothing, fall back to all HTML files in order
    final contentFiles = orderedContent.isNotEmpty
        ? orderedContent
        : (book.Content?.Html?.values.toList() ?? []);

    // Parse chapters from content files
    for (int i = 0; i < contentFiles.length; i++) {
      final file = contentFiles[i];
      final rawHtml = file.Content ?? '';
      if (rawHtml.trim().isEmpty) continue;

      // Extract plain text from HTML
      final plainText = _extractTextFromHtml(rawHtml);
      if (plainText.trim().isEmpty) continue;

      // Detect chapter title from HTML heading tags
      final title = _extractChapterTitle(rawHtml, i);

      // Skip if this is clearly a cover, TOC, or copyright page
      if (_isBoilerplatePage(title, plainText)) continue;

      // Split into sentences
      final sentences = _splitIntoSentences(plainText);
      if (sentences.isEmpty) continue;

      chapters.add(Chapter(
        index: chapters.length,
        title: title,
        sentences: sentences,
        startSentenceIndex: globalSentenceIndex,
      ));

      globalSentenceIndex += sentences.length;
    }

    return EpubParseResult(
      chapters: chapters,
      title: book.Title ?? 'Unknown Title',
      author: book.Author ?? 'Unknown Author',
      totalSentences: globalSentenceIndex,
    );
  }

  /// Extract plain text from HTML, preserving paragraph breaks.
  String _extractTextFromHtml(String html) {
    var text = html;

    // Mark paragraph and block endings with a newline before stripping tags
    text = text.replaceAll(RegExp(r'</(p|div|li|h[1-6]|br)\s*>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

    // Remove all remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');

    // Decode common HTML entities
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('\u00a0', ' '); // non-breaking space

    // Normalise whitespace while preserving paragraph breaks
    text = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join(' ');

    return text.trim();
  }

  /// Extract the chapter title from HTML heading tags.
  String _extractChapterTitle(String html, int fallbackIndex) {
    // Try h1, h2, h3 in order
    for (final tag in ['h1', 'h2', 'h3']) {
      final match = RegExp(
        '<$tag[^>]*>(.*?)</$tag>',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(html);
      if (match != null) {
        final title = match.group(1) ?? '';
        final clean = title.replaceAll(RegExp(r'<[^>]+>'), '').trim();
        if (clean.isNotEmpty) return clean;
      }
    }
    return 'Chapter ${fallbackIndex + 1}';
  }

  /// Returns true if this page should be skipped (cover, TOC, copyright).
  bool _isBoilerplatePage(String title, String text) {
    final lowerTitle = title.toLowerCase();
    final lowerText = text.toLowerCase();

    // Skip by title keywords
    if (RegExp(r'\b(cover|copyright|contents|table of contents|dedication|acknowledgements?|about the author|also by|title page)\b')
        .hasMatch(lowerTitle)) {
      return true;
    }

    // Skip very short pages (under 100 chars — likely metadata)
    if (text.length < 100) return true;

    // Skip pages that are mostly navigation links
    final linkRatio = RegExp(r'chapter \d+').allMatches(lowerText).length;
    if (linkRatio > 5 && text.length < 500) return true;

    return false;
  }

  /// Split a block of text into individual sentences.
  /// Handles standard punctuation, dialogue, ellipsis, and em-dashes.
  List<String> _splitIntoSentences(String text) {
    final sentences = <String>[];

    // Split on sentence-ending punctuation followed by whitespace and a capital
    // Uses a regex that respects common abbreviations and dialogue
    final raw = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Protect common abbreviations from splitting
    var protected = raw
        .replaceAll('Mr.', 'Mr\u200b')
        .replaceAll('Mrs.', 'Mrs\u200b')
        .replaceAll('Ms.', 'Ms\u200b')
        .replaceAll('Dr.', 'Dr\u200b')
        .replaceAll('Prof.', 'Prof\u200b')
        .replaceAll('St.', 'St\u200b')
        .replaceAll('vs.', 'vs\u200b')
        .replaceAll('etc.', 'etc\u200b')
        .replaceAll('i.e.', 'i\u200be\u200b')
        .replaceAll('e.g.', 'e\u200bg\u200b');

    // Split on . ! ? followed by space and uppercase (sentence boundary)
    final parts = protected.split(RegExp(r'(?<=[.!?])\s+(?=[A-Z""\u201c])'));

    for (var part in parts) {
      // Restore protected abbreviations
      part = part
          .replaceAll('Mr\u200b', 'Mr.')
          .replaceAll('Mrs\u200b', 'Mrs.')
          .replaceAll('Ms\u200b', 'Ms.')
          .replaceAll('Dr\u200b', 'Dr.')
          .replaceAll('Prof\u200b', 'Prof.')
          .replaceAll('St\u200b', 'St.')
          .replaceAll('vs\u200b', 'vs.')
          .replaceAll('etc\u200b', 'etc.')
          .replaceAll('i\u200be\u200b', 'i.e.')
          .replaceAll('e\u200bg\u200b', 'e.g.');

      part = part.trim();
      if (part.length > 2) {
        sentences.add(part);
      }
    }

    // If splitting produced nothing, return the whole text as one sentence
    if (sentences.isEmpty && raw.isNotEmpty) {
      sentences.add(raw);
    }

    return sentences;
  }
}

/// Result returned by [EpubParser.parse].
class EpubParseResult {
  final List<Chapter> chapters;
  final String title;
  final String author;
  final int totalSentences;

  const EpubParseResult({
    required this.chapters,
    required this.title,
    required this.author,
    required this.totalSentences,
  });
}

/// Thrown when EPUB parsing fails.
class EpubParseException implements Exception {
  final String message;
  final String filePath;
  EpubParseException(this.message, this.filePath);

  @override
  String toString() => 'EpubParseException: $message ($filePath)';
}
