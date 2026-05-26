import '../../models/voice_settings.dart';

class SsmlBuilder {
  final VoiceSettings settings;
  SsmlBuilder(this.settings);

  ProcessedSentence process({
    required String sentence,
    required SentenceContext context,
  }) {
    var text = sentence;
    double rateMultiplier = 1.0;
    double pitchOffset = 0.0;
    int prePauseMs = 0;
    int postPauseMs = 0;

    if (context.isChapterOpening && settings.chapterOpeningPause) prePauseMs += 1500;
    if (context.isDialogue && settings.dialogueFasterPace) rateMultiplier *= 1.08;
    if (!context.isDialogue && settings.narrationSlower) rateMultiplier *= 0.95;
    if (context.isInternalThought && settings.internalThoughtsSofter) {
      rateMultiplier *= 0.92;
      pitchOffset -= 0.05;
    }

    if (settings.emotionDetection) {
      final e = _detectEmotion(sentence);
      rateMultiplier *= e.rateMultiplier;
      pitchOffset += e.pitchOffset;
    }

    if (settings.shortSentencePauses && sentence.split(' ').length <= 5) {
      postPauseMs += 200;
    }

    if (settings.longSentenceBreaths && sentence.split(' ').length > 25) {
      text = _insertBreathPoint(text);
    }

    if (settings.punctuationPauses) text = _enhancePunctuation(text);

    if (settings.emDashEllipsisDrama) {
      text = _enhanceEmDashEllipsis(text);
      if (sentence.contains('...') || sentence.contains('\u2026')) postPauseMs += 300;
      if (sentence.contains('\u2014') || sentence.contains('\u2013')) postPauseMs += 200;
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
    if (RegExp(r'\b(whispered|murmured|breathed|said softly|said quietly)\b').hasMatch(lower))
      return _EmotionResult(rateMultiplier: 0.88, pitchOffset: -0.08);
    if (RegExp(r'\b(shouted|screamed|yelled|snapped|barked|roared|bellowed|snarled)\b').hasMatch(lower))
      return _EmotionResult(rateMultiplier: 1.12, pitchOffset: 0.1);
    if (RegExp(r'\b(growled|hissed|gritted|spat)\b').hasMatch(lower))
      return _EmotionResult(rateMultiplier: 0.95, pitchOffset: -0.1);
    if (RegExp(r'\b(laughed|chuckled|giggled|teased|joked|grinned)\b').hasMatch(lower))
      return _EmotionResult(rateMultiplier: 1.05, pitchOffset: 0.06);
    if (RegExp(r'\b(sobbed|wept|cried|choked|trembled)\b').hasMatch(lower))
      return _EmotionResult(rateMultiplier: 0.9, pitchOffset: -0.05);
    return _EmotionResult(rateMultiplier: 1.0, pitchOffset: 0.0);
  }

  String _enhancePunctuation(String text) =>
      text.replaceAll(',', ', ').replaceAll('  ', ' ').trim();

  String _enhanceEmDashEllipsis(String text) => text
      .replaceAll('\u2014', ', ')
      .replaceAll('\u2013', ', ')
      .replaceAll('...', '. ')
      .replaceAll('\u2026', '. ');

  String _insertBreathPoint(String text) {
    final match = RegExp(
      r',\s+(?:but|and|or|yet|so|because|although|though|while|when|where|which|who)\s+'
    ).firstMatch(text);
    if (match != null) return text.substring(0, match.end) + ' ' + text.substring(match.end);
    return text;
  }
}

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
