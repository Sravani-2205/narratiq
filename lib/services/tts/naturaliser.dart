import '../../models/book_profile.dart';
import '../../models/voice_settings.dart';
import 'ssml_builder.dart';

/// Determines the context of each sentence and applies
/// all naturalisation layers before speaking.
class Naturaliser {
  final VoiceSettings settings;
  final DialogueStyle dialogueStyle;
  final Map<String, String> pronunciationDictionary;

  Naturaliser({
    required this.settings,
    required this.dialogueStyle,
    required this.pronunciationDictionary,
  });

  /// Process a sentence with full context awareness.
  ProcessedSentence process({
    required String sentence,
    required int sentenceIndexInChapter,
    required int totalSentencesInChapter,
    required bool isAudioPlaying,
  }) {
    final context = SentenceContext(
      isDialogue: _isDialogue(sentence),
      isInternalThought: _isInternalThought(sentence),
      isChapterOpening: sentenceIndexInChapter == 0,
      isChapterClosing: sentenceIndexInChapter == totalSentencesInChapter - 1,
    );

    // Apply pronunciation corrections
    var processedText = sentence;
    if (settings.pronunciationDictionary) {
      processedText = _applyPronunciations(processedText);
    }

    final builder = SsmlBuilder(settings);
    return builder.process(
      sentence: processedText,
      context: context,
    );
  }

  bool _isDialogue(String sentence) {
    switch (dialogueStyle) {
      case DialogueStyle.standardQuoted:
      case DialogueStyle.mixed:
        return RegExp(r'["\u201c\u201d].{2,}["\u201c\u201d]').hasMatch(sentence);
      case DialogueStyle.emDash:
        return RegExp(r'^[\u2014\u2013]').hasMatch(sentence.trim());
      default:
        return false;
    }
  }

  bool _isInternalThought(String sentence) {
    // Internal thoughts are often in italics in epub — passed as markers
    // We also detect common thought attribution patterns
    return RegExp(
      r'\b(thought|wondered|realized|realised|knew|felt sure|told herself|told himself|reminded herself|reminded himself)\b',
      caseSensitive: false,
    ).hasMatch(sentence);
  }

  String _applyPronunciations(String text) {
    var result = text;
    for (final entry in pronunciationDictionary.entries) {
      result = result.replaceAll(
        RegExp(r'\b' + RegExp.escape(entry.key) + r'\b', caseSensitive: false),
        entry.value,
      );
    }
    return result;
  }
}
