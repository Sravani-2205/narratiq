/// Represents a single chapter extracted from a book.
/// Contains the full text split into sentences, plus metadata
/// used by the POV classifier.
class Chapter {
  final int index;
  final String title;        // e.g. "Chapter 4 · Feyre" or "Chapter 4"
  final List<String> sentences;
  final int startSentenceIndex; // global sentence index where this chapter begins

  const Chapter({
    required this.index,
    required this.title,
    required this.sentences,
    required this.startSentenceIndex,
  });

  int get sentenceCount => sentences.length;

  int get endSentenceIndex => startSentenceIndex + sentences.length - 1;

  /// Returns the first N sentences for POV classification scanning.
  List<String> openingSentences({int count = 10}) {
    return sentences.take(count).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'title': title,
      'sentences': sentences,
      'startSentenceIndex': startSentenceIndex,
    };
  }

  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      index: map['index'] as int,
      title: map['title'] as String,
      sentences: List<String>.from(map['sentences'] as List),
      startSentenceIndex: map['startSentenceIndex'] as int,
    );
  }

  @override
  String toString() => 'Chapter($index: $title, ${sentenceCount} sentences)';
}
