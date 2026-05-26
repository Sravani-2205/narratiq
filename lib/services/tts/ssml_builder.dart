import '../../models/voice_settings.dart';

/// Builds naturalised text for TTS by preprocessing sentences
/// with pauses, pace adjustments, and emotional cues.
/// Android TTS does not support full SSML but we can simulate
/// naturalisation by inserting silence markers and adjusting text.
class SsmlBuilder {
  final VoiceSettings settings;

  SsmlBuilder(this.settings);

  /// Process a sentence before speaking it.
  /// Returns the processed text and any rate/pitch overrides.
  ProcessedSentence process({
    required String sentence,
    required SentenceContext context,
  }) {
    var text = sentence;
    double rateMultiplier = 1.0;
    double pitchOffset = 0.0;
    int prePauseMs = 0;
    int postPauseMs = 0;

    // Chapter opening breath pause
    if (context.isChapterOpening && settings.chapterOpeningPause) {
      prePauseMs += 1500;
    }

    // Dialogue pace adjustment
    if (context.isDialogue && settings.dialogueFasterPace) {
      rateMultiplier *= 1.08;
    }

    // Narration slower
    if (!context.isDialogue && settings.narrationSlower) {
      rateMultiplier *= 0.95;
    }

    // Internal thoughts softer (italicised text — passed as flag)
    if (context.isInternalThought && settings.internalThoughtsSofter) {
      rateMultiplier *= 0.92;
      pitchOffset -= 0.05;
    }

    // Emotion detection
    if (settings.emotionDetection) {
      final emotionResult = _detectEmotion(sentence);
      rateMultiplier *= emotionResult.rateMultiplier;
      pitchOffset += emotionResult.pitchOffset;
    }

    // Short sentence micro-pause
    if (settings.shortSentencePauses) {
      final wordCount = sentence.split(' ').length;
      if (wordCount <= 5) {
        postPauseMs += 200;
      }
    }

    // Long sentence breath point — insert a comma pause at clause boundary
    if (settings.longSentenceBreaths) {
      final wordCount = sentence.split(' ').length;
      if (wordCount > 25) {
        text = _insertBreathPoint(text);
      }
    }

    // Punctuation-aware pausing via text manipulation
    if (settings.punctuationPauses) {
      text = _enhancePunctuation(text);
    }

    // Em-dash and ellipsis drama
    if (settings.emDashEllipsisDrama) {
      text = _enhanceEmDashEllipsis(text);
      if (sentence.contains('...') || sentence.contains('\u2026')) {
        postPauseMs += 300;
      }
      if (sentence.contains('\u2014') || sentence.contains('\u2013')) {
        postPauseMs += 200;
      }
    }

    return ProcessedSentence(
      text: text,
      rateMultiplier: rateMultiplier.clamp(0.7, 1.5),
      pitchOffset: pitchOffset.clamp(-0.3, 0.3),
      prePauseMs: prePauseMs,
      postPauseMs: postPauseMs,
    );
  }

  _EmotionResult _detectEmotion(String sentence) {
    final lower = sentence.toLowerCase();

    // Whispered / quiet
    if (RegExp(r'\b(whispered|murmured|breathed|said\s+softly|said\s+quietly|breathed\s+out)\b').hasMatch(lower)) {
      return _EmotionResult(rateMultiplier: 0.88, pitchOffset: -0.08);
    }

    // Shouted / angry
    if (RegExp(r'\b(shouted|screamed|yelled|snapped|barked|roared|bellowed|snarled)\b').hasMatch(lower)) {
      return _EmotionResult(rateMultiplier: 1.12, pitchOffset: 0.1);
    }

    // Growled / threatening
    if (RegExp(r'\b(growled|hissed|gritted|spat)\b').hasMatch(lower)) {
      return _EmotionResult(rateMultiplier: 0.95, pitchOffset: -0.1);
    }

    // Laughed / light
    if (RegExp(r'\b(laughed|chuckled|giggled|teased|joked|grinned)\b').hasMatch(lower)) {
      return _EmotionResult(rateMultiplier: 1.05, pitchOffset: 0.06);
    }

    // Cried / emotional
    if (RegExp(r'\b(sobbed|wept|cried|choked|trembled|broke)\b').hasMatch(lower)) {
      return _EmotionResult(rateMultiplier: 0.9, pitchOffset: -0.05);
    }

    return _EmotionResult(rateMultiplier: 1.0, pitchOffset: 0.0);
  }

  String _enhancePunctuation(String text) {
    // Add slight pause after commas by adding a space
    // TTS engines naturally pause slightly at these
    return text
        .replaceAll(',', ', ')
        .replaceAll('  ', ' ')
        .trim();
  }

  String _enhanceEmDashEllipsis(String text) {
    // Replace em-dash with comma + space for better TTS pause
    return text
        .replaceAll('\u2014', ', ')  // em dash
        .replaceAll('\u2013', ', ')  // en dash
        .replaceAll('...', '. ')     // ellipsis
        .replaceAll('\u2026', '. '); // unicode ellipsis
  }

  /// Insert a brief pause at the longest clause boundary in a long sentence.
  String _insertBreathPoint(String text) {
    // Find a good split point: after a comma, semicolon, or conjunction
    final clausePattern = RegExp(r',\s+(?:but|and|or|yet|so|because|although|though|while|when|where|which|who)\s+');
    final match = clausePattern.firstMatch(text);
    if (match != null) {
      // Insert an extra comma to prompt a slight TTS pause
      return text.substring(0, match.end) + ' ' + text.substring(match.end);
    }
    return text;
  }
}

/// Context flags for a sentence being processed.
class SentenceContext {
  final bool isDialogue;
  final bool isInternalThought;
  final bool isChapterOpening;
  final bool isChapterClosing;

  const SentenceContext({
    this.isDialogue = false,
    this.isInternalThought = false,
    this.isChapterOpening = false,
    this.isChapterClosing = false,
  });
}

/// Result of processing a sentence.
class ProcessedSentence {
  final String text;
  final double rateMultiplier;
  final double pitchOffset;
  final int prePauseMs;
  final int postPauseMs;

  const ProcessedSentence({
    required this.text,
    required this.rateMultiplier,
    required this.pitchOffset,
    required this.prePauseMs,
    required this.postPauseMs,
  });
}

class _EmotionResult {
  final double rateMultiplier;
  final double pitchOffset;
  _EmotionResult({required this.rateMultiplier, required this.pitchOffset});
}
