import '../../models/book_profile.dart';
import '../../models/chapter.dart';

/// Detects the narrative person style of a book.
/// Analyses opening sentences across multiple chapters to determine
/// whether the book is first person, third limited, third omniscient, etc.
class NarrativeDetector {
  /// Analyse chapters and return the detected narrative person
  /// along with a confidence score (0.0 to 1.0).
  NarrativeResult detect(List<Chapter> chapters) {
    if (chapters.isEmpty) {
      return NarrativeResult(NarrativePerson.unknown, 0.0);
    }

    // Sample strategically: first chapter, second chapter,
    // a middle chapter, and a late chapter
    final sampleIndices = _sampleIndices(chapters.length);
    final sampledChapters = sampleIndices.map((i) => chapters[i]).toList();

    int firstPersonScore = 0;
    int thirdLimitedScore = 0;
    int thirdOmniscientScore = 0;
    int secondPersonScore = 0;
    int totalSentencesAnalysed = 0;

    for (final chapter in sampledChapters) {
      final sentences = chapter.openingSentences(count: 10);
      for (final sentence in sentences) {
        final lower = sentence.toLowerCase();
        totalSentencesAnalysed++;

        // First person signals
        if (_hasFirstPersonSignals(lower)) firstPersonScore++;

        // Second person signals
        if (_hasSecondPersonSignals(lower)) secondPersonScore++;

        // Third person signals
        if (_hasThirdPersonSignals(lower)) {
          // Distinguish limited vs omniscient
          if (_hasOmniscientSignals(lower)) {
            thirdOmniscientScore++;
          } else {
            thirdLimitedScore++;
          }
        }
      }
    }

    if (totalSentencesAnalysed == 0) {
      return NarrativeResult(NarrativePerson.unknown, 0.0);
    }

    // Find the dominant style
    final scores = {
      NarrativePerson.firstPerson: firstPersonScore,
      NarrativePerson.thirdLimited: thirdLimitedScore,
      NarrativePerson.thirdOmniscient: thirdOmniscientScore,
      NarrativePerson.secondPerson: secondPersonScore,
    };

    final dominant = scores.entries.reduce((a, b) => a.value > b.value ? a : b);
    final total = scores.values.fold(0, (a, b) => a + b);

    if (total == 0) return NarrativeResult(NarrativePerson.unknown, 0.0);

    final confidence = dominant.value / total;

    // Check for mixed narrative (no clear dominant)
    if (confidence < 0.45) {
      return NarrativeResult(NarrativePerson.mixed, confidence);
    }

    return NarrativeResult(dominant.key, confidence.clamp(0.0, 1.0));
  }

  bool _hasFirstPersonSignals(String sentence) {
    return RegExp(
      r'\b(i\s+(?:was|had|felt|saw|knew|walked|ran|thought|said|told|looked|heard|could|would|should|am|have|do|did|went|came|got|made|took|found|left|tried|wanted|needed|loved|hated)|'
      r'my\s+(?:eyes|heart|hands|mind|voice|face|body|room|house|mother|father|sister|brother|name|life|first)|'
      r'i\'(?:d|ve|ll|m)|me\s+(?:and|to|from|with|in|at|for)|myself\b)',
    ).hasMatch(sentence);
  }

  bool _hasSecondPersonSignals(String sentence) {
    return RegExp(
      r'\byou\s+(?:are|were|had|feel|felt|see|saw|know|knew|walk|ran|think|thought|said|look|hear|heard|could|would|should|have|do|did|go|went|come|came|get|got|make|made|take|took|find|found)\b',
    ).hasMatch(sentence);
  }

  bool _hasThirdPersonSignals(String sentence) {
    return RegExp(
      r'\b(she|he|they)\s+(?:was|had|felt|saw|knew|walked|ran|thought|said|told|looked|heard|could|would|should|is|has|does|did|went|came|got|made|took|found|left|tried|wanted|needed|loved|hated)\b',
    ).hasMatch(sentence);
  }

  bool _hasOmniscientSignals(String sentence) {
    // Omniscient narrators often show multiple characters' inner thoughts
    // in the same passage, or use phrases like "neither of them knew"
    return RegExp(
      r'\b(neither|both of them|none of them|all of them|each of them|'
      r'they both|they all|he and she|she and he)\b',
    ).hasMatch(sentence);
  }

  List<int> _sampleIndices(int total) {
    if (total <= 4) return List.generate(total, (i) => i);
    return [
      0,
      1,
      (total * 0.33).round().clamp(2, total - 2),
      (total * 0.66).round().clamp(2, total - 2),
      total - 1,
    ];
  }
}

class NarrativeResult {
  final NarrativePerson person;
  final double confidence;
  NarrativeResult(this.person, this.confidence);
}
