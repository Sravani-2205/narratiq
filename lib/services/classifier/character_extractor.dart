import '../../models/chapter.dart';

/// Extracts character names from chapter headings and opening sentences.
/// Returns a map of character name -> list of chapter indices they appear in.
class CharacterExtractor {
  /// Common English words that look like proper nouns but aren't names.
  static const _stopWords = {
    'the', 'a', 'an', 'chapter', 'part', 'prologue', 'epilogue',
    'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight',
    'nine', 'ten', 'i', 'ii', 'iii', 'iv', 'v', 'vi', 'vii', 'viii',
    'ix', 'x', 'book', 'volume', 'section', 'interlude', 'before',
    'after', 'then', 'now', 'here', 'there', 'when', 'where',
    'present', 'past', 'future', 'spring', 'summer', 'autumn',
    'winter', 'fall', 'monday', 'tuesday', 'wednesday', 'thursday',
    'friday', 'saturday', 'sunday', 'january', 'february', 'march',
    'april', 'may', 'june', 'july', 'august', 'september', 'october',
    'november', 'december',
  };

  /// Extract character names and which chapters they headline.
  /// Returns map of name -> chapter indices.
  Map<String, List<int>> extractFromHeadings(List<Chapter> chapters) {
    final nameToChapters = <String, List<int>>{};

    for (final chapter in chapters) {
      final names = _extractNamesFromHeading(chapter.title);
      for (final name in names) {
        nameToChapters.putIfAbsent(name, () => []).add(chapter.index);
      }
    }

    return nameToChapters;
  }

  /// Extract character names from the opening sentences of each chapter.
  /// Looks for proper nouns that appear in subject position.
  Map<String, List<int>> extractFromContent(List<Chapter> chapters) {
    final nameToChapters = <String, List<int>>{};

    for (final chapter in chapters) {
      final sentences = chapter.openingSentences(count: 10);
      final names = _extractNamesFromSentences(sentences);
      for (final name in names) {
        nameToChapters.putIfAbsent(name, () => []).add(chapter.index);
      }
    }

    return nameToChapters;
  }

  /// Merge heading-based and content-based extractions.
  /// Heading names take priority as they are more reliable.
  Map<String, List<int>> merge(
    Map<String, List<int>> fromHeadings,
    Map<String, List<int>> fromContent,
  ) {
    final merged = Map<String, List<int>>.from(fromHeadings);
    for (final entry in fromContent.entries) {
      if (!merged.containsKey(entry.key)) {
        merged[entry.key] = entry.value;
      }
    }
    return merged;
  }

  List<String> _extractNamesFromHeading(String title) {
    final names = <String>[];
    // Remove "Chapter N" / "Part N" prefix patterns
    final cleaned = title
        .replaceAll(RegExp(r'^chapter\s+\d+\s*[·\-–—:]\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^part\s+\d+\s*[·\-–—:]\s*', caseSensitive: false), '')
        .trim();

    // Split on separators — some books have dual names in one heading
    // e.g. "Feyre & Rhysand" or "Feyre / Rhysand"
    final parts = cleaned.split(RegExp(r'\s*[&/,]\s*'));

    for (final part in parts) {
      final candidate = part.trim();
      if (_isValidName(candidate)) {
        names.add(_normaliseName(candidate));
      }
    }

    return names;
  }

  List<String> _extractNamesFromSentences(List<String> sentences) {
    final names = <String>[];
    // Pattern: CapitalisedWord at sentence start, or after "said", "thought", etc.
    final subjectPattern = RegExp(r'^([A-Z][a-z]{2,})\s+(?:was|had|walked|ran|looked|said|felt|knew|turned|stood|sat|moved|stared|smiled|frowned|nodded|shook|reached|took|grabbed|pulled|pushed|stepped|went|came|saw|heard|thought|wanted|needed)');
    final afterAttribution = RegExp(r'(?:said|thought|whispered|murmured|replied|answered|called|shouted|cried|laughed|growled|snarled|snapped)\s+([A-Z][a-z]{2,})');

    for (final sentence in sentences) {
      final subjectMatch = subjectPattern.firstMatch(sentence);
      if (subjectMatch != null) {
        final name = subjectMatch.group(1)!;
        if (_isValidName(name)) names.add(_normaliseName(name));
      }

      final attributionMatch = afterAttribution.firstMatch(sentence);
      if (attributionMatch != null) {
        final name = attributionMatch.group(1)!;
        if (_isValidName(name)) names.add(_normaliseName(name));
      }
    }

    return names.toSet().toList(); // deduplicate
  }

  bool _isValidName(String candidate) {
    if (candidate.isEmpty || candidate.length < 3 || candidate.length > 20) {
      return false;
    }
    // Must start with capital
    if (!RegExp(r'^[A-Z]').hasMatch(candidate)) return false;
    // Must not be a stop word
    if (_stopWords.contains(candidate.toLowerCase())) return false;
    // Must be mostly letters
    if (!RegExp(r'^[A-Za-z\'-]+$').hasMatch(candidate)) return false;
    return true;
  }

  String _normaliseName(String name) {
    // Capitalise first letter, lowercase rest
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }
}
