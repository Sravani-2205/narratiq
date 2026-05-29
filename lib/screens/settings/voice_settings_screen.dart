import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/voice_settings.dart';

class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  VoiceSettings _settings = const VoiceSettings();
  bool _loading = true;

  static const _accents = {
    'en-GB': 'British',
    'en-US': 'American',
    'en-AU': 'Australian',
    'en-IN': 'Indian',
    'en-IE': 'Irish',
    'en-ZA': 'South African',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _settings = VoiceSettings(
        maleVoiceLocale: prefs.getString('maleVoiceLocale') ?? 'en-GB',
        femaleVoiceLocale: prefs.getString('femaleVoiceLocale') ?? 'en-GB',
        preferMaleNarrator: prefs.getBool('preferMaleNarrator') ?? false,
        speechRate: prefs.getDouble('speechRate') ?? 0.5,
        pitch: prefs.getDouble('pitch') ?? 1.0,
        punctuationPauses: prefs.getBool('punctuationPauses') ?? true,
        emDashEllipsisDrama: prefs.getBool('emDashEllipsisDrama') ?? true,
        dialogueFasterPace: prefs.getBool('dialogueFasterPace') ?? true,
        narrationSlower: prefs.getBool('narrationSlower') ?? true,
        internalThoughtsSofter: prefs.getBool('internalThoughtsSofter') ?? true,
        emotionDetection: prefs.getBool('emotionDetection') ?? true,
        chapterOpeningPause: prefs.getBool('chapterOpeningPause') ?? true,
        shortSentencePauses: prefs.getBool('shortSentencePauses') ?? true,
        longSentenceBreaths: prefs.getBool('longSentenceBreaths') ?? true,
        pronunciationDictionary: prefs.getBool('pronunciationDictionary') ?? true,
      );
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('maleVoiceLocale', _settings.maleVoiceLocale);
    await prefs.setString('femaleVoiceLocale', _settings.femaleVoiceLocale);
    await prefs.setBool('preferMaleNarrator', _settings.preferMaleNarrator);
    await prefs.setDouble('speechRate', _settings.speechRate);
    await prefs.setDouble('pitch', _settings.pitch);
    await prefs.setBool('punctuationPauses', _settings.punctuationPauses);
    await prefs.setBool('emDashEllipsisDrama', _settings.emDashEllipsisDrama);
    await prefs.setBool('dialogueFasterPace', _settings.dialogueFasterPace);
    await prefs.setBool('narrationSlower', _settings.narrationSlower);
    await prefs.setBool('internalThoughtsSofter', _settings.internalThoughtsSofter);
    await prefs.setBool('emotionDetection', _settings.emotionDetection);
    await prefs.setBool('chapterOpeningPause', _settings.chapterOpeningPause);
    await prefs.setBool('shortSentencePauses', _settings.shortSentencePauses);
    await prefs.setBool('longSentenceBreaths', _settings.longSentenceBreaths);
    await prefs.setBool('pronunciationDictionary', _settings.pronunciationDictionary);
  }

  void _update(VoiceSettings updated) {
    setState(() => _settings = updated);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _header('Voice Selection'),
          // Male accent
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Male voice accent',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _accents.entries.map((e) => ChoiceChip(
                    label: Text(e.value),
                    selected: _settings.maleVoiceLocale == e.key,
                    selectedColor: const Color(0xFF4E9AF1).withOpacity(0.2),
                    onSelected: (_) => _update(_settings.copyWith(maleVoiceLocale: e.key)),
                  )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Female accent
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Female voice accent',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _accents.entries.map((e) => ChoiceChip(
                    label: Text(e.value),
                    selected: _settings.femaleVoiceLocale == e.key,
                    selectedColor: const Color(0xFFE91E8C).withOpacity(0.2),
                    onSelected: (_) => _update(_settings.copyWith(femaleVoiceLocale: e.key)),
                  )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Narrator gender preference
          SwitchListTile(
            title: const Text('Male narrator voice'),
            subtitle: const Text('Use male voice for narration by default'),
            value: _settings.preferMaleNarrator,
            activeColor: const Color(0xFF6B4EFF),
            onChanged: (v) => _update(_settings.copyWith(preferMaleNarrator: v)),
          ),
          const Divider(indent: 16, endIndent: 16),
          _header('Naturalisation'),
          _toggle('Punctuation pausing',
              'Varied pauses for . , — and …',
              _settings.punctuationPauses,
              (v) => _update(_settings.copyWith(punctuationPauses: v))),
          _toggle('Em-dash & ellipsis drama',
              'Extra pause on — and ... for effect',
              _settings.emDashEllipsisDrama,
              (v) => _update(_settings.copyWith(emDashEllipsisDrama: v))),
          _toggle('Dialogue faster pace',
              'Dialogue reads slightly faster than narration',
              _settings.dialogueFasterPace,
              (v) => _update(_settings.copyWith(dialogueFasterPace: v))),
          _toggle('Narration slower',
              'Narration reads more deliberately',
              _settings.narrationSlower,
              (v) => _update(_settings.copyWith(narrationSlower: v))),
          _toggle('Internal thoughts softer',
              'Quieter, slower pace for character thoughts',
              _settings.internalThoughtsSofter,
              (v) => _update(_settings.copyWith(internalThoughtsSofter: v))),
          _toggle('Emotion detection',
              'Adjust pace and pitch for whispered, shouted etc.',
              _settings.emotionDetection,
              (v) => _update(_settings.copyWith(emotionDetection: v))),
          _toggle('Chapter opening pause',
              '1.5s breath pause before each chapter',
              _settings.chapterOpeningPause,
              (v) => _update(_settings.copyWith(chapterOpeningPause: v))),
          _toggle('Short sentence pauses',
              'Extra beat after very short sentences',
              _settings.shortSentencePauses,
              (v) => _update(_settings.copyWith(shortSentencePauses: v))),
          _toggle('Long sentence breaths',
              'Natural pause at clause boundaries in long sentences',
              _settings.longSentenceBreaths,
              (v) => _update(_settings.copyWith(longSentenceBreaths: v))),
          _toggle('Pronunciation dictionary',
              'Apply per-book name corrections',
              _settings.pronunciationDictionary,
              (v) => _update(_settings.copyWith(pronunciationDictionary: v))),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _header(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(title.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
            letterSpacing: 1.2, color: Colors.grey.shade500)),
  );

  Widget _toggle(String title, String subtitle, bool value, Function(bool) onChanged) =>
      SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        activeColor: const Color(0xFF6B4EFF),
        onChanged: onChanged,
      );
}
