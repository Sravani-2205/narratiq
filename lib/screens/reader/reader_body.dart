import 'package:flutter/material.dart';
import '../../models/chapter.dart';
import '../../widgets/sentence_highlight.dart';
import '../../widgets/font_controls.dart';
import '../../widgets/theme_selector.dart';

class ReaderBody extends StatefulWidget {
  final Chapter chapter;
  final int highlightedSentenceIndex;
  final bool isPlaying;
  final double fontSize;
  final String fontFamily;
  final FontWeight fontWeight;
  final ReadingTheme readingTheme;
  final Function(int) onSentenceTap;
  final Function(double) onFontSizeChanged;
  final Function(String) onFontFamilyChanged;
  final Function(FontWeight) onFontWeightChanged;
  final Function(ReadingTheme) onThemeChanged;

  const ReaderBody({
    super.key,
    required this.chapter,
    required this.highlightedSentenceIndex,
    required this.isPlaying,
    required this.fontSize,
    required this.fontFamily,
    required this.fontWeight,
    required this.readingTheme,
    required this.onSentenceTap,
    required this.onFontSizeChanged,
    required this.onFontFamilyChanged,
    required this.onFontWeightChanged,
    required this.onThemeChanged,
  });

  @override
  State<ReaderBody> createState() => _ReaderBodyState();
}

class _ReaderBodyState extends State<ReaderBody> {
  final ScrollController _scrollController = ScrollController();
  bool _showControls = false;

  @override
  void didUpdateWidget(ReaderBody old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying &&
        widget.highlightedSentenceIndex != old.highlightedSentenceIndex) {
      _autoScroll();
    }
  }

  void _autoScroll() {
    if (!_scrollController.hasClients) return;
    final sentenceHeight = widget.fontSize * 1.7 * 1.5;
    final targetOffset = widget.highlightedSentenceIndex * sentenceHeight;
    final viewportHeight = _scrollController.position.viewportDimension;
    final scrollTo = (targetOffset - viewportHeight / 3).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      scrollTo,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = ThemeSelector.backgroundColor(widget.readingTheme);
    final textColor = ThemeSelector.textColor(widget.readingTheme);

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        children: [
          // Reading area
          Container(
            color: bg,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              children: [
                // Chapter title
                Text(
                  widget.chapter.title,
                  style: TextStyle(
                    fontSize: widget.fontSize + 4,
                    fontFamily: widget.fontFamily,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 20),
                // Sentences with highlight
                SentenceHighlight(
                  sentences: widget.chapter.sentences,
                  highlightedIndex: widget.highlightedSentenceIndex,
                  isPlaying: widget.isPlaying,
                  fontSize: widget.fontSize,
                  fontFamily: widget.fontFamily,
                  fontWeight: widget.fontWeight,
                  textColor: textColor,
                  onSentenceTap: widget.onSentenceTap,
                ),
              ],
            ),
          ),
          // Font/theme controls overlay
          if (_showControls)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.97),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FontControls(
                      fontSize: widget.fontSize,
                      fontFamily: widget.fontFamily,
                      fontWeight: widget.fontWeight,
                      onFontSizeChanged: widget.onFontSizeChanged,
                      onFontFamilyChanged: widget.onFontFamilyChanged,
                      onFontWeightChanged: widget.onFontWeightChanged,
                    ),
                    ThemeSelector(
                      currentTheme: widget.readingTheme,
                      onThemeChanged: widget.onThemeChanged,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
