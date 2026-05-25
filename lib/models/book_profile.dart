import 'pov_character.dart';

/// The narrative person style of the book.
enum NarrativePerson { firstPerson, thirdLimited, thirdOmniscient, secondPerson, mixed, unknown }

/// How many POV characters the book has.
enum PovStructure { single, dual, multi, omniscient, epistolary, unknown }

/// How dialogue is formatted in the book.
enum DialogueStyle { standardQuoted, emDash, unquoted, mixed, unknown }

/// The complete analysis result produced by the BookClassifier.
/// Generated once on import, stored permanently, never re-scanned.
class BookProfile {
  final String bookId;

  // Core classification results
  final NarrativePerson narrativePerson;
  final PovStructure povStructure;
  final DialogueStyle dialogueStyle;
  final List<PovCharacter> povCharacters;

  // Per-chapter POV mapping: chapterIndex -> character name
  // Built progressively as the book is read
  final Map<int, String> chapterPovMap;

  // Overall confidence in the classification (0.0 to 1.0)
  final double overallConfidence;

  // Whether voice switching should be active for this book
  final bool voiceSwitchingEnabled;

  // Metadata from internet lookup (if available)
  final String? resolvedTitle;
  final String? resolvedAuthor;

  // Flags for edge cases
  final bool hasMidBookPovShift;   // POV pattern changes mid-book
  final int? midBookShiftChapter;  // Chapter where shift occurs

  // When this profile was generated
  final DateTime classifiedAt;
  final bool isComplete; // false while background scan is still running

  const BookProfile({
    required this.bookId,
    required this.narrativePerson,
    required this.povStructure,
    required this.dialogueStyle,
    required this.povCharacters,
    required this.chapterPovMap,
    required this.overallConfidence,
    required this.voiceSwitchingEnabled,
    this.resolvedTitle,
    this.resolvedAuthor,
    this.hasMidBookPovShift = false,
    this.midBookShiftChapter,
    required this.classifiedAt,
    this.isComplete = false,
  });

  /// Human-readable summary for the banner notification.
  String get summaryText {
    if (povStructure == PovStructure.dual && povCharacters.length >= 2) {
      final names = povCharacters.map((c) => c.name).join(' & ');
      return 'Dual POV detected · $names';
    }
    if (povStructure == PovStructure.single && povCharacters.isNotEmpty) {
      return 'Single POV · ${povCharacters.first.name}';
    }
    if (povStructure == PovStructure.multi) {
      return 'Multi POV · ${povCharacters.length} characters';
    }
    return 'Book analysed · Voice switching ready';
  }

  String get confidenceDisplay {
    final percent = (overallConfidence * 100).toStringAsFixed(0);
    return '$percent%';
  }

  /// Returns the POV character for a given chapter index, or null if unknown.
  PovCharacter? characterForChapter(int chapterIndex) {
    final name = chapterPovMap[chapterIndex];
    if (name == null) return null;
    try {
      return povCharacters.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  BookProfile copyWith({
    NarrativePerson? narrativePerson,
    PovStructure? povStructure,
    DialogueStyle? dialogueStyle,
    List<PovCharacter>? povCharacters,
    Map<int, String>? chapterPovMap,
    double? overallConfidence,
    bool? voiceSwitchingEnabled,
    String? resolvedTitle,
    String? resolvedAuthor,
    bool? hasMidBookPovShift,
    int? midBookShiftChapter,
    bool? isComplete,
  }) {
    return BookProfile(
      bookId: bookId,
      narrativePerson: narrativePerson ?? this.narrativePerson,
      povStructure: povStructure ?? this.povStructure,
      dialogueStyle: dialogueStyle ?? this.dialogueStyle,
      povCharacters: povCharacters ?? this.povCharacters,
      chapterPovMap: chapterPovMap ?? this.chapterPovMap,
      overallConfidence: overallConfidence ?? this.overallConfidence,
      voiceSwitchingEnabled: voiceSwitchingEnabled ?? this.voiceSwitchingEnabled,
      resolvedTitle: resolvedTitle ?? this.resolvedTitle,
      resolvedAuthor: resolvedAuthor ?? this.resolvedAuthor,
      hasMidBookPovShift: hasMidBookPovShift ?? this.hasMidBookPovShift,
      midBookShiftChapter: midBookShiftChapter ?? this.midBookShiftChapter,
      classifiedAt: classifiedAt,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'narrativePerson': narrativePerson.name,
      'povStructure': povStructure.name,
      'dialogueStyle': dialogueStyle.name,
      'povCharacters': povCharacters.map((c) => c.toMap()).toList(),
      'chapterPovMap': chapterPovMap.map((k, v) => MapEntry(k.toString(), v)),
      'overallConfidence': overallConfidence,
      'voiceSwitchingEnabled': voiceSwitchingEnabled ? 1 : 0,
      'resolvedTitle': resolvedTitle,
      'resolvedAuthor': resolvedAuthor,
      'hasMidBookPovShift': hasMidBookPovShift ? 1 : 0,
      'midBookShiftChapter': midBookShiftChapter,
      'classifiedAt': classifiedAt.millisecondsSinceEpoch,
      'isComplete': isComplete ? 1 : 0,
    };
  }

  factory BookProfile.fromMap(Map<String, dynamic> map) {
    return BookProfile(
      bookId: map['bookId'] as String,
      narrativePerson: NarrativePerson.values.byName(map['narrativePerson'] as String),
      povStructure: PovStructure.values.byName(map['povStructure'] as String),
      dialogueStyle: DialogueStyle.values.byName(map['dialogueStyle'] as String),
      povCharacters: (map['povCharacters'] as List)
          .map((e) => PovCharacter.fromMap(e as Map<String, dynamic>))
          .toList(),
      chapterPovMap: (map['chapterPovMap'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(int.parse(k), v as String)),
      overallConfidence: (map['overallConfidence'] as num).toDouble(),
      voiceSwitchingEnabled: map['voiceSwitchingEnabled'] == 1,
      resolvedTitle: map['resolvedTitle'] as String?,
      resolvedAuthor: map['resolvedAuthor'] as String?,
      hasMidBookPovShift: map['hasMidBookPovShift'] == 1,
      midBookShiftChapter: map['midBookShiftChapter'] as int?,
      classifiedAt: DateTime.fromMillisecondsSinceEpoch(map['classifiedAt'] as int),
      isComplete: map['isComplete'] == 1,
    );
  }
}
