/// A saved position in a book.
/// Can be auto-saved (on close) or manually created by the user.
class Bookmark {
  final String id;
  final String bookId;
  final String? label;         // User-given name, null for auto-saves
  final int chapterIndex;
  final int sentenceIndex;
  final String sentencePreview; // First 80 chars of the sentence for display
  final bool isAutoSave;        // true = last-position save, false = manual
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.bookId,
    this.label,
    required this.chapterIndex,
    required this.sentenceIndex,
    required this.sentencePreview,
    this.isAutoSave = false,
    required this.createdAt,
  });

  String get displayLabel {
    if (label != null && label!.isNotEmpty) return label!;
    if (isAutoSave) return 'Last position';
    return 'Bookmark at Chapter ${chapterIndex + 1}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'label': label,
      'chapterIndex': chapterIndex,
      'sentenceIndex': sentenceIndex,
      'sentencePreview': sentencePreview,
      'isAutoSave': isAutoSave ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as String,
      bookId: map['bookId'] as String,
      label: map['label'] as String?,
      chapterIndex: map['chapterIndex'] as int,
      sentenceIndex: map['sentenceIndex'] as int,
      sentencePreview: map['sentencePreview'] as String,
      isAutoSave: map['isAutoSave'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  @override
  String toString() => 'Bookmark($displayLabel @ ch$chapterIndex:s$sentenceIndex)';
}
