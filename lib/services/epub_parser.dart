import 'dart:io';
import 'package:epubx/epubx.dart';
import '../models/chapter.dart';

class EpubParser {
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

    final spineItems = book.Schema?.Package?.Spine?.Items ?? [];

    // manifest is Map<String, EpubManifestItem>? — access safely
    final manifestItems = book.Schema?.Package?.Manifest?.Items;

    // Build content map from HTML files
    final contentMap = <String, EpubTextContentFile>{};
    final htmlFiles = book.Content?.Html;
    if (htmlFiles != null) {
      for (final entry in (htmlFiles as Map).entries) {
        final file = entry.value;
        if (file is EpubTextContentFile) {
          contentMap[file.FileName ?? ''] = file;
        }
      }
    }

    // Walk spine → manifest → content
    final orderedContent = <EpubTextContentFile>[];
    for (final spineItem in spineItems) {
      if (manifestItems == null) continue;
      final idRef = spineItem.IdRef;
      if (idRef == null) continue;
      final manifestEntry = (manifestItems as Map)[idRef];
      if (manifestEntry == null) continue;
      final href = (manifestEntry as dynamic).Href as String? ?? '';
      final lastName = href.split('/').last;
      EpubTextContentFile? found;
      for (final f in contentMap.values) {
        if ((f.FileName ?? '').endsWith(lastName)) { found = f; break; }
      }
      found ??= contentMap[href];
      if (found != null && (found.Content ?? '').isNotEmpty) {
        orderedContent.add(found);
      }
    }

    final contentFiles = orderedContent.isNotEmpty
        ? orderedContent
        : contentMap.values.toList();

    for (int i = 0; i < contentFiles.length; i++) {
      final file = contentFiles[i];
      final rawHtml = file.Content ?? '';
      if (rawHtml.trim().isEmpty) continue;

      final plainText = _extractTextFromHtml(rawHtml);
      if (plainText.trim().isEmpty) continue;

      final title = _extractChapterTitle(rawHtml, i);
      if (_isBoilerplatePage(title, plainText)) continue;

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

  String _extractTextFromHtml(String html) {
    var text = html;
    text = text.replaceAll(RegExp(r'</(p|div|li|h[1-6]|br)\s*>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('\u00a0', ' ');
    return text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).join(' ').trim();
  }

  String _extractChapterTitle(String html, int fallbackIndex) {
    for (final tag in ['h1', 'h2', 'h3']) {
      final match = RegExp('<$tag[^>]*>(.*?)</$tag>', caseSensitive: false, dotAll: true).firstMatch(html);
      if (match != null) {
        final clean = (match.group(1) ?? '').replaceAll(RegExp(r'<[^>]+>'), '').trim();
        if (clean.isNotEmpty) return clean;
      }
    }
    return 'Chapter ${fallbackIndex + 1}';
  }

  bool _isBoilerplatePage(String title, String text) {
    final lowerTitle = title.toLowerCase();
    final lowerText = text.toLowerCase();
    if (RegExp(r'\b(cover|copyright|contents|table of contents|dedication|acknowledgements?|about the author|also by|title page)\b').hasMatch(lowerTitle)) return true;
    if (text.length < 100) return true;
    if (RegExp(r'chapter \d+').allMatches(lowerText).length > 5 && text.length < 500) return true;
    return false;
  }

  List<String> _splitIntoSentences(String text) {
    final sentences = <String>[];
    final raw = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    var protected = raw
        .replaceAll('Mr.', 'Mr\u200b').replaceAll('Mrs.', 'Mrs\u200b')
        .replaceAll('Ms.', 'Ms\u200b').replaceAll('Dr.', 'Dr\u200b')
        .replaceAll('Prof.', 'Prof\u200b').replaceAll('St.', 'St\u200b')
        .replaceAll('vs.', 'vs\u200b').replaceAll('etc.', 'etc\u200b')
        .replaceAll('i.e.', 'i\u200be\u200b').replaceAll('e.g.', 'e\u200bg\u200b');
    final parts = protected.split(RegExp(r'(?<=[.!?])\s+(?=[A-Z""\u201c])'));
    for (var part in parts) {
      part = part
          .replaceAll('Mr\u200b', 'Mr.').replaceAll('Mrs\u200b', 'Mrs.')
          .replaceAll('Ms\u200b', 'Ms.').replaceAll('Dr\u200b', 'Dr.')
          .replaceAll('Prof\u200b', 'Prof.').replaceAll('St\u200b', 'St.')
          .replaceAll('vs\u200b', 'vs.').replaceAll('etc\u200b', 'etc.')
          .replaceAll('i\u200be\u200b', 'i.e.').replaceAll('e\u200bg\u200b', 'e.g.')
          .trim();
      if (part.length > 2) sentences.add(part);
    }
    if (sentences.isEmpty && raw.isNotEmpty) sentences.add(raw);
    return sentences;
  }
}

class EpubParseResult {
  final List<Chapter> chapters;
  final String title;
  final String author;
  final int totalSentences;
  const EpubParseResult({required this.chapters, required this.title, required this.author, required this.totalSentences});
}

class EpubParseException implements Exception {
  final String message;
  final String filePath;
  EpubParseException(this.message, this.filePath);
  @override
  String toString() => 'EpubParseException: $message ($filePath)';
}
