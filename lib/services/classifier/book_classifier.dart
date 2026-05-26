import 'dart:async';
import 'dart:io';
import '../../models/book_profile.dart';
import '../../models/chapter.dart';
import '../../models/pov_character.dart';
import 'narrative_detector.dart';
import 'dialogue_detector.dart';
import 'character_extractor.dart';
import 'gender_resolver.dart';
import 'pov_detector.dart';
import 'confidence_scorer.dart';

/// The main orchestrator for book classification.
/// Runs in two stages:
///   Stage 1 (fast, ~2–3s): narrative person + basic POV structure
///   Stage 2 (deep, ~8–15s): characters, genders, full chapter mapping
///
/// Emits a stream of [BookProfile] so the UI can update progressively.
class BookClassifier {
  final NarrativeDetector _narrativeDetector = NarrativeDetector();
  final DialogueDetector _dialogueDetector = DialogueDetector();
  final CharacterExtractor _characterExtractor = CharacterExtractor();
  final GenderResolver _genderResolver = GenderResolver();
  final PovDetector _povDetector = PovDetector();
  final ConfidenceScorer _confidenceScorer = ConfidenceScorer();

  /// Classify a book from its chapters.
  /// Yields a partial profile after Stage 1, then a complete profile after Stage 2.
  Stream<BookProfile> classify({
    required String bookId,
    required List<Chapter> chapters,
    required String title,
    required String author,
    bool useInternet = true,
  }) async* {
    if (chapters.isEmpty) {
      yield _unknownProfile(bookId);
      return;
    }

    // ── Stage 1: Fast scan ────────────────────────────────────────
    final narrativeResult = _narrativeDetector.detect(chapters);
    final dialogueResult = _dialogueDetector.detect(chapters);

    // Quick heading-based character extraction
    final headingCharacters = _characterExtractor.extractFromHeadings(chapters);

    // Basic POV structure from headings alone
    final quickPovResult = _povDetector.detect(
      chapters: chapters,
      characterChapterMap: headingCharacters,
      narrativePerson: narrativeResult.person,
    );

    // Emit Stage 1 partial profile immediately
    final stage1Profile = BookProfile(
      bookId: bookId,
      narrativePerson: narrativeResult.person,
      povStructure: quickPovResult.structure,
      dialogueStyle: dialogueResult.style,
      povCharacters: headingCharacters.keys
          .map((name) => PovCharacter(
                name: name,
                gender: CharacterGender.unknown,
                confidence: DetectionConfidence.low,
                chapterIndices: headingCharacters[name]!,
              ))
          .toList(),
      chapterPovMap: quickPovResult.chapterPovMap,
      overallConfidence: 0.4,
      voiceSwitchingEnabled: false, // Not confirmed yet
      classifiedAt: DateTime.now(),
      isComplete: false,
    );
    yield stage1Profile;

    // ── Stage 2: Deep scan ────────────────────────────────────────
    // Extract names from content as well
    final contentCharacters = _characterExtractor.extractFromContent(chapters);
    final mergedCharacters = _characterExtractor.merge(
      headingCharacters,
      contentCharacters,
    );

    // Resolve genders (on-device + optional internet)
    final resolvedCharacters = await _genderResolver.resolve(
      chapterMap: mergedCharacters,
      chapters: chapters,
      useInternet: useInternet && await _hasInternet(),
    );

    // Full POV detection with resolved characters
    final fullPovResult = _povDetector.detect(
      chapters: chapters,
      characterChapterMap: mergedCharacters,
      narrativePerson: narrativeResult.person,
    );

    // Deep scan: fill in unmapped chapters
    final fullChapterPovMap = _povDetector.deepScanChapterPov(
      chapters: chapters,
      existingMap: fullPovResult.chapterPovMap,
      characters: resolvedCharacters,
    );

    // Calculate overall confidence
    final overallConfidence = _confidenceScorer.calculate(
      narrativeConfidence: narrativeResult.confidence,
      povStructureConfidence: fullPovResult.confidence,
      dialogueConfidence: dialogueResult.confidence,
      characters: resolvedCharacters,
      chapterPovMap: fullChapterPovMap,
      totalChapters: chapters.length,
    );

    // Determine if voice switching should be active
    final voiceSwitching = _confidenceScorer.shouldEnableVoiceSwitching(
      structure: fullPovResult.structure,
      characters: resolvedCharacters,
      overallConfidence: overallConfidence,
    );

    // Emit complete Stage 2 profile
    yield BookProfile(
      bookId: bookId,
      narrativePerson: narrativeResult.person,
      povStructure: fullPovResult.structure,
      dialogueStyle: dialogueResult.style,
      povCharacters: resolvedCharacters,
      chapterPovMap: fullChapterPovMap,
      overallConfidence: overallConfidence,
      voiceSwitchingEnabled: voiceSwitching,
      hasMidBookPovShift: fullPovResult.hasMidBookShift,
      midBookShiftChapter: fullPovResult.midBookShiftChapter,
      classifiedAt: DateTime.now(),
      isComplete: true,
    );
  }

  BookProfile _unknownProfile(String bookId) {
    return BookProfile(
      bookId: bookId,
      narrativePerson: NarrativePerson.unknown,
      povStructure: PovStructure.unknown,
      dialogueStyle: DialogueStyle.unknown,
      povCharacters: [],
      chapterPovMap: {},
      overallConfidence: 0.0,
      voiceSwitchingEnabled: false,
      classifiedAt: DateTime.now(),
      isComplete: true,
    );
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('api.genderize.io')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
