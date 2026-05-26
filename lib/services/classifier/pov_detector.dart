import '../../models/book_profile.dart';
import '../../models/chapter.dart';
import '../../models/pov_character.dart';

/// Detects the POV structure of the book and maps each chapter
/// to its POV character where possible.
class PovDetector {
  /// Detect POV structure and build the chapter POV map.
  PovDetectionResult detect({
    required List<Chapter> chapters,
    required Map<String, List<int>> characterChapterMap,
    required NarrativePerson narrativePerson,
  }) {
    if (chapters.isEmpty) {
      return PovDetectionResult(
        structure: PovStructure.unknown,
        chapterPovMap: {},
        confidence: 0.0,
        hasMidBookShift: false,
      );
    }

    // Check for epistolary style (letters/diary entries)
    if (_isEpistolary(chapters)) {
      return PovDetectionResult(
        structure: PovStructure.epistolary,
        chapterPovMap: {},
        confidence: 0.7,
        hasMidBookShift: false,
      );
    }

    // If no characters were extracted, determine structure from narrative person
    if (characterChapterMap.isEmpty) {
      return _inferFromNarrativePerson(narrativePerson, chapters);
    }

    // Build chapter POV map from character data
    final chapterPovMap = <int, String>{};
    for (final entry in characterChapterMap.entries) {
      for (final chapterIdx in entry.value) {
        // If multiple characters claim the same chapter, the one with
        // more occurrences in headings wins
        if (!chapterPovMap.containsKey(chapterIdx)) {
          chapterPovMap[chapterIdx] = entry.key;
        }
      }
    }

    // Determine structure from number of distinct POV characters
    final uniqueCharacters = characterChapterMap.keys.length;
    final structure = uniqueCharacters == 1
        ? PovStructure.single
        : uniqueCharacters == 2
            ? PovStructure.dual
            : uniqueCharacters >= 3
                ? PovStructure.multi
                : PovStructure.unknown;

    // Calculate confidence based on coverage
    final mappedChapters = chapterPovMap.length;
    final coverage = mappedChapters / chapters.length;
    final confidence = (coverage * 0.8 + 0.2).clamp(0.0, 1.0);

    // Detect mid-book POV shift
    final shiftResult = _detectMidBookShift(chapters, chapterPovMap);

    return PovDetectionResult(
      structure: structure,
      chapterPovMap: chapterPovMap,
      confidence: confidence,
      hasMidBookShift: shiftResult.hasShift,
      midBookShiftChapter: shiftResult.shiftChapter,
    );
  }

  /// For chapters not covered by heading analysis,
  /// scan content to assign a POV character.
  /// Call this during the deep scan phase.
  Map<int, String> deepScanChapterPov({
    required List<Chapter> chapters,
    required Map<int, String> existingMap,
    required List<PovCharacter> characters,
  }) {
    final result = Map<int, String>.from(existingMap);

    for (final chapter in chapters) {
      if (result.containsKey(chapter.index)) continue;

      // Scan up to 10 sentences for character name appearances
      final sentences = chapter.openingSentences(count: 10);
      final fullText = sentences.join(' ').toLowerCase();

      String? bestMatch;
      int bestScore = 0;

      for (final character in characters) {
        final namePattern = RegExp(
          r'\b' + RegExp.escape(character.name.toLowerCase()) + r'\b',
        );
        final matches = namePattern.allMatches(fullText).length;
        if (matches > bestScore) {
          bestScore = matches;
          bestMatch = character.name;
        }
      }

      // Also check first-person signals for single first-person POV books
      if (bestMatch == null && characters.length == 1) {
        final hasFirstPerson = RegExp(
          r'\b(i\s+(?:was|had|felt|saw|knew|walked|ran|thought|said)|my\s+\w+)\b',
        ).hasMatch(fullText);
        if (hasFirstPerson) bestMatch = characters.first.name;
      }

      if (bestMatch != null && bestScore > 0) {
        result[chapter.index] = bestMatch;
      }
    }

    return result;
  }

  PovDetectionResult _inferFromNarrativePerson(
    NarrativePerson person,
    List<Chapter> chapters,
  ) {
    switch (person) {
      case NarrativePerson.thirdOmniscient:
        return PovDetectionResult(
          structure: PovStructure.omniscient,
          chapterPovMap: {},
          confidence: 0.6,
          hasMidBookShift: false,
        );
      case NarrativePerson.firstPerson:
        return PovDetectionResult(
          structure: PovStructure.single,
          chapterPovMap: {},
          confidence: 0.5,
          hasMidBookShift: false,
        );
      default:
        return PovDetectionResult(
          structure: PovStructure.unknown,
          chapterPovMap: {},
          confidence: 0.3,
          hasMidBookShift: false,
        );
    }
  }

  bool _isEpistolary(List<Chapter> chapters) {
    final epistolaryPattern = RegExp(
      r'\b(dear\s+\w+|dearest|to whom it may concern|yours (truly|sincerely|faithfully)|dear diary|entry\s+\d+)\b',
      caseSensitive: false,
    );
    int matches = 0;
    for (final chapter in chapters.take(3)) {
      final text = chapter.sentences.take(3).join(' ');
      if (epistolaryPattern.hasMatch(text)) matches++;
    }
    return matches >= 2;
  }

  _ShiftResult _detectMidBookShift(
    List<Chapter> chapters,
    Map<int, String> chapterPovMap,
  ) {
    if (chapterPovMap.length < 4) return _ShiftResult(false, null);

    // Look for a sustained change in POV character pattern in the second half
    final midPoint = chapters.length ~/ 2;
    final firstHalfChars = <String>{};
    final secondHalfChars = <String>{};

    for (final entry in chapterPovMap.entries) {
      if (entry.key < midPoint) {
        firstHalfChars.add(entry.value);
      } else {
        secondHalfChars.add(entry.value);
      }
    }

    // If entirely new characters appear in the second half, flag it
    final newInSecondHalf = secondHalfChars.difference(firstHalfChars);
    if (newInSecondHalf.isNotEmpty && firstHalfChars.isNotEmpty) {
      return _ShiftResult(true, midPoint);
    }

    return _ShiftResult(false, null);
  }
}

class PovDetectionResult {
  final PovStructure structure;
  final Map<int, String> chapterPovMap;
  final double confidence;
  final bool hasMidBookShift;
  final int? midBookShiftChapter;

  PovDetectionResult({
    required this.structure,
    required this.chapterPovMap,
    required this.confidence,
    required this.hasMidBookShift,
    this.midBookShiftChapter,
  });
}

class _ShiftResult {
  final bool hasShift;
  final int? shiftChapter;
  _ShiftResult(this.hasShift, this.shiftChapter);
}
