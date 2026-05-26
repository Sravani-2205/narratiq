import 'dart:async';
import '../../models/book_profile.dart';
import '../../models/pov_character.dart';
import '../../models/voice_settings.dart';
import 'tts_service.dart';

/// Manages chapter-level voice switching based on POV detection.
/// Applies the correct male/female voice at the start of each chapter
/// with a brief crossfade pause between voice changes.
class VoiceSwitcher {
  final TtsService ttsService;
  final VoiceSettings settings;

  String? _currentVoiceGender; // 'male' or 'female'
  int _currentChapterIndex = -1;

  VoiceSwitcher({required this.ttsService, required this.settings});

  /// Call at the start of each chapter.
  /// Applies the correct voice based on POV detection.
  /// Returns the gender being used for this chapter.
  Future<String> onChapterStart({
    required int chapterIndex,
    required BookProfile? profile,
    String? manualOverride, // 'male' or 'female' — user tap override
  }) async {
    if (_currentChapterIndex == chapterIndex) {
      return _currentVoiceGender ?? _defaultGender;
    }

    final targetGender = manualOverride ??
        _detectChapterGender(chapterIndex, profile) ??
        _defaultGender;

    // Only switch and pause if the gender is actually changing
    if (_currentVoiceGender != null && _currentVoiceGender != targetGender) {
      await _crossfadePause();
    }

    // Apply the new voice
    await ttsService.applySettings(settings, useMale: targetGender == 'male');

    _currentVoiceGender = targetGender;
    _currentChapterIndex = chapterIndex;

    return targetGender;
  }

  /// Detect which gender should read a given chapter.
  String? _detectChapterGender(int chapterIndex, BookProfile? profile) {
    if (profile == null) return null;
    if (!profile.voiceSwitchingEnabled) return null;

    final characterName = profile.chapterPovMap[chapterIndex];
    if (characterName == null) return null;

    try {
      final character = profile.povCharacters.firstWhere(
        (c) => c.name == characterName,
      );
      switch (character.gender) {
        case CharacterGender.male:
          return 'male';
        case CharacterGender.female:
          return 'female';
        case CharacterGender.unknown:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// Get the POV character name for a chapter (for the indicator widget).
  String? getChapterCharacterName(int chapterIndex, BookProfile? profile) {
    return profile?.chapterPovMap[chapterIndex];
  }

  /// Brief pause between voice switches — simulates crossfade.
  Future<void> _crossfadePause() async {
    await Future.delayed(const Duration(milliseconds: 1200));
  }

  String get _defaultGender =>
      settings.preferMaleNarrator ? 'male' : 'female';

  String? get currentGender => _currentVoiceGender;

  /// Reset when a new book is opened.
  void reset() {
    _currentVoiceGender = null;
    _currentChapterIndex = -1;
  }
}
