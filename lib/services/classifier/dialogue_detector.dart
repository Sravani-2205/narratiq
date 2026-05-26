import '../../models/book_profile.dart';
import '../../models/chapter.dart';

/// Detects the dialogue formatting style used in the book.
/// This affects how the TTS engine identifies and reads dialogue.
class DialogueDetector {
  DialogueResult detect(List<Chapter> chapters) {
    if (chapters.isEmpty) return DialogueResult(DialogueStyle.unknown, 0.0);

    // Sample the first 3 chapters for dialogue style
    final sample = chapters.take(3).toList();
    final allSentences = sample.expand((c) => c.sentences).take(100).toList();

    int quotedCount = 0;
    int emDashCount = 0;
    int unquotedCount = 0;

    for (final sentence in allSentences) {
      if (_isStandardQuoted(sentence)) quotedCount++;
      if (_isEmDash(sentence)) emDashCount++;
    }

    // Unquoted is inferred when very little quoting is present
    // but the text is clearly narrative prose
    if (quotedCount < 3 && emDashCount < 3 && allSentences.length > 20) {
      unquotedCount = 1;
    }

    final total = quotedCount + emDashCount + unquotedCount;
    if (total == 0) return DialogueResult(DialogueStyle.unknown, 0.3);

    // Determine dominant style
    if (emDashCount > quotedCount && emDashCount > unquotedCount) {
      final confidence = emDashCount / total;
      return DialogueResult(DialogueStyle.emDash, confidence.clamp(0.0, 1.0));
    }

    if (quotedCount > 0) {
      final confidence = quotedCount / (quotedCount + emDashCount + 1);
      // Mixed if both styles are present significantly
      if (emDashCount > (quotedCount * 0.3)) {
        return DialogueResult(DialogueStyle.mixed, 0.6);
      }
      return DialogueResult(
        DialogueStyle.standardQuoted,
        confidence.clamp(0.0, 1.0),
      );
    }

    return DialogueResult(DialogueStyle.unquoted, 0.5);
  }

  /// Standard quoted dialogue: "Hello," she said. or "Hello," said John.
  bool _isStandardQuoted(String sentence) {
    return RegExp(r'["\u201c\u201d].{3,}["\u201c\u201d]').hasMatch(sentence);
  }

  /// Em-dash dialogue: —Hello, she said. (common in Spanish/translated books)
  bool _isEmDash(String sentence) {
    return RegExp(r'^[\u2014\u2013]').hasMatch(sentence.trim());
  }

  /// Checks if a sentence contains dialogue (for use by other services).
  static bool containsDialogue(String sentence, DialogueStyle style) {
    switch (style) {
      case DialogueStyle.standardQuoted:
      case DialogueStyle.mixed:
        return RegExp(r'["\u201c\u201d].{2,}["\u201c\u201d]').hasMatch(sentence);
      case DialogueStyle.emDash:
        return RegExp(r'[\u2014\u2013]').hasMatch(sentence);
      case DialogueStyle.unquoted:
        return false; // Cannot reliably detect unquoted dialogue
      case DialogueStyle.unknown:
        return RegExp(r'["\u201c\u201d].{2,}["\u201c\u201d]').hasMatch(sentence);
    }
  }
}

class DialogueResult {
  final DialogueStyle style;
  final double confidence;
  DialogueResult(this.style, this.confidence);
}
