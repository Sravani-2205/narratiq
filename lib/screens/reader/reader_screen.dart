import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/book.dart';
import '../../models/book_profile.dart';
import '../../models/bookmark.dart';
import '../../models/chapter.dart';
import '../../models/voice_settings.dart';
import '../../services/library_service.dart';
import '../../services/tts/tts_service.dart';
import '../../services/tts/voice_switcher.dart';
import '../../services/tts/naturaliser.dart';
import '../../services/storage/progress_repository.dart';
import '../../widgets/pov_indicator.dart';
import '../../widgets/chapter_drawer.dart';
import '../../widgets/bookmark_sheet.dart';
import '../../widgets/sleep_timer_widget.dart';
import '../../widgets/theme_selector.dart';
import 'reader_body.dart';
import 'reader_controls.dart';
import 'package:uuid/uuid.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;
  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> with WidgetsBindingObserver {
  final TtsService _tts = TtsService();
  final ProgressRepository _progressRepo = ProgressRepository();
  final _uuid = const Uuid();

  late VoiceSwitcher _voiceSwitcher;
  late VoiceSettings _voiceSettings;

  List<Chapter> _chapters = [];
  BookProfile? _profile;
  List<Bookmark> _bookmarks = [];

  int _currentChapterIndex = 0;
  int _currentSentenceIndex = 0;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _manualVoiceOverride;

  // Display settings
  double _fontSize = 17.0;
  String _fontFamily = 'Georgia';
  FontWeight _fontWeight = FontWeight.w400;
  ReadingTheme _readingTheme = ReadingTheme.light;

  Chapter? get _currentChapter =>
      _chapters.isNotEmpty ? _chapters[_currentChapterIndex] : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _voiceSettings = const VoiceSettings();
    _voiceSwitcher = VoiceSwitcher(ttsService: _tts, settings: _voiceSettings);
    _loadBook();
  }

  Future<void> _loadBook() async {
    final library = context.read<LibraryService>();
    final chapters = await library.getChapters(widget.book.id);
    final profile = await _progressRepo.getBookProfile(widget.book.id);
    final bookmarks = await _progressRepo.getBookmarks(widget.book.id);
    final prefs = await SharedPreferences.getInstance();
    await _loadDisplaySettings(prefs);

    if (!mounted) return;
    setState(() {
      _chapters = chapters;
      _profile = profile;
      _bookmarks = bookmarks;
      _currentChapterIndex = widget.book.currentChapterIndex;
      _currentSentenceIndex = widget.book.currentSentenceIndex;
      _isLoading = false;
    });

    await _tts.initialise();
    _tts.onComplete = _onSentenceComplete;
    _voiceSwitcher.reset();
    await _voiceSwitcher.onChapterStart(
      chapterIndex: _currentChapterIndex,
      profile: _profile,
    );
  }

  Future<void> _loadDisplaySettings(SharedPreferences prefs) async {
    _fontSize = prefs.getDouble('fontSize') ?? 17.0;
    _fontFamily = prefs.getString('fontFamily') ?? 'Georgia';
    _fontWeight = FontWeight.values[prefs.getInt('fontWeight') ?? 3];
    _readingTheme = ReadingTheme.values[prefs.getInt('readingTheme') ?? 0];
  }

  Future<void> _saveDisplaySettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setString('fontFamily', _fontFamily);
    await prefs.setInt('fontWeight', FontWeight.values.indexOf(_fontWeight));
    await prefs.setInt('readingTheme', ReadingTheme.values.indexOf(_readingTheme));
  }

  Future<void> _play() async {
    if (_currentChapter == null) return;
    final sentences = _currentChapter!.sentences;
    if (_currentSentenceIndex >= sentences.length) return;

    setState(() => _isPlaying = true);

    final naturaliser = Naturaliser(
      settings: _voiceSettings,
      dialogueStyle: _profile?.dialogueStyle ?? DialogueStyle.standardQuoted,
      pronunciationDictionary: {},
    );

    final sentence = sentences[_currentSentenceIndex];
    final processed = naturaliser.process(
      sentence: sentence,
      sentenceIndexInChapter: _currentSentenceIndex,
      totalSentencesInChapter: sentences.length,
      isAudioPlaying: true,
    );

    if (processed.prePauseMs > 0) {
      await Future.delayed(Duration(milliseconds: processed.prePauseMs));
    }

    await _tts.speak(processed.text);
  }

  void _onSentenceComplete() async {
    if (!_isPlaying) return;
    final sentences = _currentChapter?.sentences ?? [];

    if (_currentSentenceIndex < sentences.length - 1) {
      setState(() => _currentSentenceIndex++);
      await _play();
    } else if (_currentChapterIndex < _chapters.length - 1) {
      await _nextChapter();
    } else {
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _pause() async {
    await _tts.stop();
    setState(() => _isPlaying = false);
  }

  Future<void> _nextSentence() async {
    await _tts.stop();
    final sentences = _currentChapter?.sentences ?? [];
    if (_currentSentenceIndex < sentences.length - 1) {
      setState(() => _currentSentenceIndex++);
      if (_isPlaying) await _play();
    }
  }

  Future<void> _prevSentence() async {
    await _tts.stop();
    if (_currentSentenceIndex > 0) {
      setState(() => _currentSentenceIndex--);
      if (_isPlaying) await _play();
    }
  }

  Future<void> _nextChapter() async {
    if (_currentChapterIndex >= _chapters.length - 1) return;
    await _tts.stop();
    setState(() {
      _currentChapterIndex++;
      _currentSentenceIndex = 0;
      _manualVoiceOverride = null;
    });
    await _voiceSwitcher.onChapterStart(
      chapterIndex: _currentChapterIndex,
      profile: _profile,
    );
    if (_isPlaying) await _play();
    await _saveProgress();
  }

  Future<void> _goToChapter(int index) async {
    await _tts.stop();
    setState(() {
      _currentChapterIndex = index;
      _currentSentenceIndex = 0;
      _manualVoiceOverride = null;
      _isPlaying = false;
    });
    await _voiceSwitcher.onChapterStart(
      chapterIndex: index,
      profile: _profile,
    );
    await _saveProgress();
  }

  Future<void> _saveProgress() async {
    final sentence = _currentChapter?.sentences.elementAtOrNull(_currentSentenceIndex) ?? '';
    final preview = sentence.length > 80 ? sentence.substring(0, 80) : sentence;
    await context.read<LibraryService>().saveProgress(
      bookId: widget.book.id,
      chapterIndex: _currentChapterIndex,
      sentenceIndex: _currentSentenceIndex,
      sentencePreview: preview,
    );
  }

  Future<void> _addBookmark() async {
    final sentence = _currentChapter?.sentences.elementAtOrNull(_currentSentenceIndex) ?? '';
    final preview = sentence.length > 80 ? sentence.substring(0, 80) : sentence;

    String? label;
    if (mounted) {
      label = await showDialog<String>(
        context: context,
        builder: (_) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Name this bookmark'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Optional label'),
              autofocus: true,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip')),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    }

    final bookmark = Bookmark(
      id: _uuid.v4(),
      bookId: widget.book.id,
      label: label?.isNotEmpty == true ? label : null,
      chapterIndex: _currentChapterIndex,
      sentenceIndex: _currentSentenceIndex,
      sentencePreview: preview,
      createdAt: DateTime.now(),
    );

    await _progressRepo.saveBookmark(bookmark);
    setState(() => _bookmarks.add(bookmark));
  }

  void _showBookmarks() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BookmarkSheet(
        bookmarks: _bookmarks,
        onBookmarkTap: (b) {
          _goToChapter(b.chapterIndex);
          setState(() => _currentSentenceIndex = b.sentenceIndex);
        },
        onBookmarkDelete: (b) async {
          await _progressRepo.deleteBookmark(b.id);
          setState(() => _bookmarks.remove(b));
        },
        onAddBookmark: () { Navigator.pop(context); _addBookmark(); },
      ),
    );
  }

  void _showSleepTimer() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SleepTimerWidget(onTimerEnd: _pause),
    );
  }

  String _timeRemaining() {
    if (_currentChapter == null) return '';
    final sentences = _currentChapter!.sentences;
    final remaining = sentences.length - _currentSentenceIndex;
    final avgSecondsPerSentence = 4.0 / _voiceSettings.speechRate;
    final totalSeconds = (remaining * avgSecondsPerSentence).round();
    final minutes = totalSeconds ~/ 60;
    if (minutes < 1) return '< 1 min left';
    return '$minutes min left in chapter';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _saveProgress();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tts.stop();
    _tts.dispose();
    _saveProgress();
    _saveDisplaySettings();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_chapters.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.book.title)),
        body: const Center(child: Text('Could not load book content.')),
      );
    }

    return Consumer<LibraryService>(
      builder: (context, library, _) {
        final liveProfile = library.profileFor(widget.book.id) ?? _profile;

        return Scaffold(
          drawer: ChapterDrawer(
            chapters: _chapters,
            currentChapterIndex: _currentChapterIndex,
            profile: liveProfile,
            onChapterSelected: _goToChapter,
          ),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: ThemeSelector.backgroundColor(_readingTheme),
            foregroundColor: ThemeSelector.textColor(_readingTheme),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.book.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                Text(_currentChapter?.title ?? '',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal)),
              ],
            ),
            actions: [
              PovIndicator(
                profile: liveProfile,
                currentChapterIndex: _currentChapterIndex,
                manualOverride: _manualVoiceOverride,
                onOverride: (gender) async {
                  setState(() => _manualVoiceOverride = gender);
                  await _voiceSwitcher.onChapterStart(
                    chapterIndex: _currentChapterIndex,
                    profile: liveProfile,
                    manualOverride: gender,
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  itemCount: _chapters.length,
                  controller: PageController(initialPage: _currentChapterIndex),
                  onPageChanged: (index) => _goToChapter(index),
                  itemBuilder: (context, index) => ReaderBody(
                    chapter: _chapters[index],
                    highlightedSentenceIndex: index == _currentChapterIndex
                        ? _currentSentenceIndex : 0,
                    isPlaying: _isPlaying && index == _currentChapterIndex,
                    fontSize: _fontSize,
                    fontFamily: _fontFamily,
                    fontWeight: _fontWeight,
                    readingTheme: _readingTheme,
                    onSentenceTap: (i) {
                      setState(() => _currentSentenceIndex = i);
                      if (_isPlaying) { _tts.stop(); _play(); }
                    },
                    onFontSizeChanged: (v) => setState(() => _fontSize = v),
                    onFontFamilyChanged: (v) => setState(() => _fontFamily = v),
                    onFontWeightChanged: (v) => setState(() => _fontWeight = v),
                    onThemeChanged: (v) => setState(() => _readingTheme = v),
                  ),
                ),
              ),
              ReaderControls(
                isPlaying: _isPlaying,
                speechRate: _voiceSettings.speechRate,
                timeRemaining: _timeRemaining(),
                onPlay: _play,
                onPause: _pause,
                onPrevSentence: _prevSentence,
                onNextSentence: _nextSentence,
                onSleepTimer: _showSleepTimer,
                onBookmarks: _showBookmarks,
                onChapters: () => Scaffold.of(context).openDrawer(),
                onSpeedChanged: (v) => setState(() {
                  _voiceSettings = _voiceSettings.copyWith(speechRate: v);
                  _voiceSwitcher = VoiceSwitcher(ttsService: _tts, settings: _voiceSettings);
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
