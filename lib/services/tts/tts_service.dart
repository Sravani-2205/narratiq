import 'package:flutter_tts/flutter_tts.dart';
import '../../models/voice_settings.dart';

/// Core TTS engine wrapper.
/// Handles initialisation, voice selection, and playback control.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialised = false;
  bool _isPlaying = false;

  Function(int start, int end)? onWordBoundary;
  Function()? onComplete;
  Function()? onStart;

  Future<void> initialise() async {
    if (_isInitialised) return;
    await _tts.setSharedInstance(true);
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() {
      _isPlaying = true;
      onStart?.call();
    });

    _tts.setCompletionHandler(() {
      _isPlaying = false;
      onComplete?.call();
    });

    _tts.setProgressHandler((text, start, end, word) {
      onWordBoundary?.call(start, end);
    });

    _isInitialised = true;
  }

  /// Apply voice settings to the TTS engine.
  Future<void> applySettings(VoiceSettings settings, {bool useMale = false}) async {
    await initialise();
    final locale = useMale ? settings.maleVoiceLocale : settings.femaleVoiceLocale;
    await _setVoiceForLocale(locale, useMale: useMale);
    await _tts.setSpeechRate(settings.speechRate);
    await _tts.setPitch(settings.pitch);
    await _tts.setVolume(settings.volume);
  }

  Future<void> _setVoiceForLocale(String locale, {required bool useMale}) async {
    final voices = await _tts.getVoices as List?;
    if (voices == null) {
      await _tts.setLanguage(locale);
      return;
    }

    // Find a voice matching locale and gender
    final targetGender = useMale ? 'male' : 'female';
    Map<String, String>? bestVoice;

    for (final v in voices) {
      final voice = Map<String, String>.from(v as Map);
      final voiceLocale = voice['locale'] ?? '';
      final voiceName = (voice['name'] ?? '').toLowerCase();
      final voiceGender = (voice['gender'] ?? '').toLowerCase();

      if (!voiceLocale.startsWith(locale.substring(0, 2))) continue;

      // Prefer exact locale match with correct gender
      if (voiceLocale == locale) {
        if (voiceGender == targetGender ||
            voiceName.contains(targetGender) ||
            (useMale && (voiceName.contains('male') || voiceName.contains('man'))) ||
            (!useMale && (voiceName.contains('female') || voiceName.contains('woman')))) {
          bestVoice = voice;
          break;
        }
        bestVoice ??= voice; // fallback to any voice with right locale
      }
    }

    if (bestVoice != null) {
      await _tts.setVoice(bestVoice);
    } else {
      await _tts.setLanguage(locale);
    }
  }

  /// Speak a single sentence.
  Future<void> speak(String text) async {
    await initialise();
    await _tts.speak(text);
  }

  /// Stop playback immediately.
  Future<void> stop() async {
    await _tts.stop();
    _isPlaying = false;
  }

  /// Pause playback.
  Future<void> pause() async {
    await _tts.pause();
    _isPlaying = false;
  }

  bool get isPlaying => _isPlaying;

  /// Get all available voices grouped by locale.
  Future<Map<String, List<Map<String, String>>>> getAvailableVoices() async {
    await initialise();
    final voices = await _tts.getVoices as List? ?? [];
    final grouped = <String, List<Map<String, String>>>{};
    for (final v in voices) {
      final voice = Map<String, String>.from(v as Map);
      final locale = voice['locale'] ?? 'unknown';
      grouped.putIfAbsent(locale, () => []).add(voice);
    }
    return grouped;
  }

  /// Get available English voices only.
  Future<List<Map<String, String>>> getEnglishVoices() async {
    final all = await getAvailableVoices();
    final english = <Map<String, String>>[];
    for (final entry in all.entries) {
      if (entry.key.startsWith('en')) {
        english.addAll(entry.value);
      }
    }
    return english;
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}
