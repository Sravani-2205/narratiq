/// Represents a book in the Narratiq library.
/// Stores metadata, file path, reading progress, and display preferences.
class Book {
  final String id;
  final String title;
  final String author;
  final String filePath;
  final String fileType; // 'epub' or 'txt'
  final String? coverImagePath;
  final int totalChapters;
  final int totalSentences;
  final DateTime importedAt;
  final DateTime? lastOpenedAt;

  // Reading progress
  final int currentChapterIndex;
  final int currentSentenceIndex;

  // Computed
  double get progressPercent {
    if (totalSentences == 0) return 0.0;
    return (currentSentenceIndex / totalSentences).clamp(0.0, 1.0);
  }

  String get progressDisplay {
    return '${(progressPercent * 100).toStringAsFixed(0)}%';
  }

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    required this.fileType,
    this.coverImagePath,
    required this.totalChapters,
    required this.totalSentences,
    required this.importedAt,
    this.lastOpenedAt,
    this.currentChapterIndex = 0,
    this.currentSentenceIndex = 0,
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? filePath,
    String? fileType,
    String? coverImagePath,
    int? totalChapters,
    int? totalSentences,
    DateTime? importedAt,
    DateTime? lastOpenedAt,
    int? currentChapterIndex,
    int? currentSentenceIndex,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      totalChapters: totalChapters ?? this.totalChapters,
      totalSentences: totalSentences ?? this.totalSentences,
      importedAt: importedAt ?? this.importedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      currentSentenceIndex: currentSentenceIndex ?? this.currentSentenceIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'filePath': filePath,
      'fileType': fileType,
      'coverImagePath': coverImagePath,
      'totalChapters': totalChapters,
      'totalSentences': totalSentences,
      'importedAt': importedAt.millisecondsSinceEpoch,
      'lastOpenedAt': lastOpenedAt?.millisecondsSinceEpoch,
      'currentChapterIndex': currentChapterIndex,
      'currentSentenceIndex': currentSentenceIndex,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String,
      filePath: map['filePath'] as String,
      fileType: map['fileType'] as String,
      coverImagePath: map['coverImagePath'] as String?,
      totalChapters: map['totalChapters'] as int,
      totalSentences: map['totalSentences'] as int,
      importedAt: DateTime.fromMillisecondsSinceEpoch(map['importedAt'] as int),
      lastOpenedAt: map['lastOpenedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastOpenedAt'] as int)
          : null,
      currentChapterIndex: map['currentChapterIndex'] as int,
      currentSentenceIndex: map['currentSentenceIndex'] as int,
    );
  }

  @override
  String toString() => 'Book($title by $author — $progressDisplay)';
}
