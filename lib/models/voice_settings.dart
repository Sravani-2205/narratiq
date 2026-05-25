/// All voice and naturalisation settings for the app.
/// Stored in SharedPreferences and applied globally,
/// with per-book overrides possible.
class VoiceSettings {
  // Voice selection
  final String maleVoiceLocale;    // e.g. 'en-GB' for British Male
  final String femaleVoiceLocale;  // e.g. 'en-US' for American Female
  final bool preferMaleNarrator;   // true = male for narration, false = female

  // Playback
  final double speechRate;   // 0.5 = slow, 1.0 = normal, 2.0 = fast
  final double pitch;        // 0.5 = low, 1.0 = normal, 2.0 = high
  final double volume;       // 0.0 to 1.0

  // Naturalisation toggles — all default ON
  final bool punctuationPauses;       // Respect . , — … with varied pauses
  final bool emDashEllipsisDrama;     // Dramatic pause on — and ...
  final bool dialogueFasterPace;      // Dialogue slightly faster than narration
  final bool narrationSlower;         // Narration slightly slower, deliberate
  final bool internalThoughtsSofter;  // Italicised thoughts quieter
  final bool emotionDetection;        // Adjust voice on whispered/shouted etc.
  final bool chapterOpeningPause;     // Breath pause before chapter starts
  final bool shortSentencePauses;     // Micro-pause after very short sentences
  final bool longSentenceBreaths;     // Natural breath in very long sentences
  final bool pronunciationDictionary; // Per-book name corrections

  const VoiceSettings({
    this.maleVoiceLocale = 'en-GB',
    this.femaleVoiceLocale = 'en-GB',
    this.preferMaleNarrator = false,
    this.speechRate = 0.5,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.punctuationPauses = true,
    this.emDashEllipsisDrama = true,
    this.dialogueFasterPace = true,
    this.narrationSlower = true,
    this.internalThoughtsSofter = true,
    this.emotionDetection = true,
    this.chapterOpeningPause = true,
    this.shortSentencePauses = true,
    this.longSentenceBreaths = true,
    this.pronunciationDictionary = true,
  });

  VoiceSettings copyWith({
    String? maleVoiceLocale,
    String? femaleVoiceLocale,
    bool? preferMaleNarrator,
    double? speechRate,
    double? pitch,
    double? volume,
    bool? punctuationPauses,
    bool? emDashEllipsisDrama,
    bool? dialogueFasterPace,
    bool? narrationSlower,
    bool? internalThoughtsSofter,
    bool? emotionDetection,
    bool? chapterOpeningPause,
    bool? shortSentencePauses,
    bool? longSentenceBreaths,
    bool? pronunciationDictionary,
  }) {
    return VoiceSettings(
      maleVoiceLocale: maleVoiceLocale ?? this.maleVoiceLocale,
      femaleVoiceLocale: femaleVoiceLocale ?? this.femaleVoiceLocale,
      preferMaleNarrator: preferMaleNarrator ?? this.preferMaleNarrator,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      punctuationPauses: punctuationPauses ?? this.punctuationPauses,
      emDashEllipsisDrama: emDashEllipsisDrama ?? this.emDashEllipsisDrama,
      dialogueFasterPace: dialogueFasterPace ?? this.dialogueFasterPace,
      narrationSlower: narrationSlower ?? this.narrationSlower,
      internalThoughtsSofter: internalThoughtsSofter ?? this.internalThoughtsSofter,
      emotionDetection: emotionDetection ?? this.emotionDetection,
      chapterOpeningPause: chapterOpeningPause ?? this.chapterOpeningPause,
      shortSentencePauses: shortSentencePauses ?? this.shortSentencePauses,
      longSentenceBreaths: longSentenceBreaths ?? this.longSentenceBreaths,
      pronunciationDictionary: pronunciationDictionary ?? this.pronunciationDictionary,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maleVoiceLocale': maleVoiceLocale,
      'femaleVoiceLocale': femaleVoiceLocale,
      'preferMaleNarrator': preferMaleNarrator,
      'speechRate': speechRate,
      'pitch': pitch,
      'volume': volume,
      'punctuationPauses': punctuationPauses,
      'emDashEllipsisDrama': emDashEllipsisDrama,
      'dialogueFasterPace': dialogueFasterPace,
      'narrationSlower': narrationSlower,
      'internalThoughtsSofter': internalThoughtsSofter,
      'emotionDetection': emotionDetection,
      'chapterOpeningPause': chapterOpeningPause,
      'shortSentencePauses': shortSentencePauses,
      'longSentenceBreaths': longSentenceBreaths,
      'pronunciationDictionary': pronunciationDictionary,
    };
  }

  factory VoiceSettings.fromMap(Map<String, dynamic> map) {
    return VoiceSettings(
      maleVoiceLocale: map['maleVoiceLocale'] as String? ?? 'en-GB',
      femaleVoiceLocale: map['femaleVoiceLocale'] as String? ?? 'en-GB',
      preferMaleNarrator: map['preferMaleNarrator'] as bool? ?? false,
      speechRate: (map['speechRate'] as num?)?.toDouble() ?? 0.5,
      pitch: (map['pitch'] as num?)?.toDouble() ?? 1.0,
      volume: (map['volume'] as num?)?.toDouble() ?? 1.0,
      punctuationPauses: map['punctuationPauses'] as bool? ?? true,
      emDashEllipsisDrama: map['emDashEllipsisDrama'] as bool? ?? true,
      dialogueFasterPace: map['dialogueFasterPace'] as bool? ?? true,
      narrationSlower: map['narrationSlower'] as bool? ?? true,
      internalThoughtsSofter: map['internalThoughtsSofter'] as bool? ?? true,
      emotionDetection: map['emotionDetection'] as bool? ?? true,
      chapterOpeningPause: map['chapterOpeningPause'] as bool? ?? true,
      shortSentencePauses: map['shortSentencePauses'] as bool? ?? true,
      longSentenceBreaths: map['longSentenceBreaths'] as bool? ?? true,
      pronunciationDictionary: map['pronunciationDictionary'] as bool? ?? true,
    );
  }
}
