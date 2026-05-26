import '../../models/book_profile.dart';
import '../../models/chapter.dart';

class NarrativeDetector {
  NarrativeResult detect(List<Chapter> chapters) {
    if (chapters.isEmpty) return NarrativeResult(NarrativePerson.unknown, 0.0);

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
        if (_hasFirstPersonSignals(lower)) firstPersonScore++;
        if (_hasSecondPersonSignals(lower)) secondPersonScore++;
        if (_hasThirdPersonSignals(lower)) {
          if (_hasOmniscientSignals(lower)) {
            thirdOmniscientScore++;
          } else {
            thirdLimitedScore++;
          }
        }
      }
    }

    if (totalSentencesAnalysed == 0) return NarrativeResult(NarrativePerson.unknown, 0.0);

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
    if (confidence < 0.45) return NarrativeResult(NarrativePerson.mixed, confidence);

    return NarrativeResult(dominant.key, confidence.clamp(0.0, 1.0));
  }

  bool _hasFirstPersonSignals(String s) => RegExp(
    r"\b(i\s+(was|had|felt|saw|knew|walked|ran|thought|said|looked|heard|could|would|am|have|did|went|came|got|made|took|found)|my\s+(eyes|heart|hands|mind|voice|face|body|room|name|life)|i'(d|ve|ll|m)|myself\b)"
  ).hasMatch(s);

  bool _hasSecondPersonSignals(String s) => RegExp(
    r'\byou\s+(are|were|had|feel|felt|see|saw|know|knew|walk|ran|think|thought|said|look|hear|heard|could|would|have|did|go|went|come|came|get|got|make|made)\b'
  ).hasMatch(s);

  bool _hasThirdPersonSignals(String s) => RegExp(
    r'\b(she|he|they)\s+(was|had|felt|saw|knew|walked|ran|thought|said|told|looked|heard|could|would|is|has|did|went|came|got|made|took|found|left|tried|wanted|needed)\b'
  ).hasMatch(s);

  bool _hasOmniscientSignals(String s) => RegExp(
    r'\b(neither|both of them|none of them|all of them|each of them|they both|they all|he and she|she and he)\b'
  ).hasMatch(s);

  List<int> _sampleIndices(int total) {
    if (total <= 4) return List.generate(total, (i) => i);
    return [0, 1, (total * 0.33).round().clamp(2, total - 2), (total * 0.66).round().clamp(2, total - 2), total - 1];
  }
}

class NarrativeResult {
  final NarrativePerson person;
  final double confidence;
  NarrativeResult(this.person, this.confidence);
}
