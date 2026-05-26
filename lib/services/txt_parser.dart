import 'dart:io';
import '../models/chapter.dart';

/// Parses a plain TXT file into chapters and sentences.
/// Detects chapter breaks from common heading patterns.
class TxtParser {
  /// Parse a TXT file at [filePath].
  Future<TxtParseResult> parse(String filePath) async {
    try {
      final content = await File(filePath).readAsString();
      return _parseContent(content, filePath);
    } on FileSystemException catch (e) {
      throw TxtParseException('Cannot read file: ${e.message}', filePath);
    }
  }

  TxtParseResult _parseContent(String content, String filePath) {
    final lines = content.split('\n');
    final chapterBlocks = <_ChapterBlock>[];
    _ChapterBlock? current;

    for (final line in lines) {
      final trimmed = line.trim();

      if (_isChapterHeading(trimmed)) {
        // Save the current block and start a new one
        if (current != null && current.lines.isNotEmpty) {
          chapterBlocks.add(current);
        }
        current = _ChapterBlock(title: trimmed);
      } else if (trimmed.isNotEmpty) {
        // Add line to current block, or start a default block
        current ??= _ChapterBlock(title: 'Chapter 1');
        current.lines.add(trimmed);
      }
    }

    // Don't forget the last block
    if (current != null && current.lines.isNotEmpty) {
      chapterBlocks.add(current);
    }

    // If no chapters were detected, treat the whole file as one chapter
    if (chapterBlocks.isEmpty) {
      final allText = lines.map((l) => l.trim()).where((l) => l.isNotEmpty).join(' ');
      chapterBlocks.add(_ChapterBlock(title: 'Chapter 1')..lines.add(allText));
    }

    // Build Chapter objects
    final chapters = <Chapter>[];
    int globalSentenceIndex = 0;

    for (int i = 0; i < chapterBlocks.length; i++) {
      final block = chapterBlocks[i];
      final fullText = block.lines.join(' ');
      final sentences = _splitIntoSentences(fullText);
      if (sentences.isEmpty) continue;

      chapters.add(Chapter(
        index: i,
        title: block.title,
        sentences: sentences,
        startSentenceIndex: globalSentenceIndex,
      ));
      globalSentenceIndex += sentences.length;
    }

    // Extract title from filename
    final fileName = filePath.split('/').last.replaceAll('.txt', '');

    return TxtParseResult(
      chapters: chapters,
      title: fileName,
      author: 'Unknown Author',
      totalSentences: globalSentenceIndex,
    );
  }

  /// Detects common chapter heading patterns in plain text.
  bool _isChapterHeading(String line) {
    if (line.isEmpty || line.length > 100) return false;

    return RegExp(
      r'^(chapter\s+\d+|chapter\s+[ivxlcdm]+|part\s+\d+|part\s+[ivxlcdm]+|prologue|epilogue|preface|introduction)',
      caseSensitive: false,
    ).hasMatch(line);
  }

  /// Split text into sentences — same logic as EpubParser.
  List<String> _splitIntoSentences(String text) {
    final sentences = <String>[];
    final raw = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    var protected = raw
        .replaceAll('Mr.', 'Mr\u200b')
        .replaceAll('Mrs.', 'Mrs\u200b')
        .replaceAll('Ms.', 'Ms\u200b')
        .replaceAll('Dr.', 'Dr\u200b')
        .replaceAll('Prof.', 'Prof\u200b')
        .replaceAll('St.', 'St\u200b')
        .replaceAll('vs.', 'vs\u200b')
        .replaceAll('etc.', 'etc\u200b');

    final parts = protected.split(RegExp(r'(?<=[.!?])\s+(?=[A-Z""\u201c])'));

    for (var part in parts) {
      part = part
          .replaceAll('Mr\u200b', 'Mr.')
          .replaceAll('Mrs\u200b', 'Mrs.')
          .replaceAll('Ms\u200b', 'Ms.')
          .replaceAll('Dr\u200b', 'Dr.')
          .replaceAll('Prof\u200b', 'Prof.')
          .replaceAll('St\u200b', 'St.')
          .replaceAll('vs\u200b', 'vs.')
          .replaceAll('etc\u200b', 'etc.')
          .trim();

      if (part.length > 2) sentences.add(part);
    }

    if (sentences.isEmpty && raw.isNotEmpty) sentences.add(raw);
    return sentences;
  }
}

class _ChapterBlock {
  final String title;
  final List<String> lines = [];
  _ChapterBlock({required this.title});
}

class TxtParseResult {
  final List<Chapter> chapters;
  final String title;
  final String author;
  final int totalSentences;

  const TxtParseResult({
    required this.chapters,
    required this.title,
    required this.author,
    required this.totalSentences,
  });
}

class TxtParseException implements Exception {
  final String message;
  final String filePath;
  TxtParseException(this.message, this.filePath);

  @override
  String toString() => 'TxtParseException: $message ($filePath)';
}
