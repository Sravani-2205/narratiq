import 'package:flutter/material.dart';

/// Displays a list of sentences with the current one highlighted.
/// Used in the reader body during TTS playback.
class SentenceHighlight extends StatelessWidget {
  final List<String> sentences;
  final int highlightedIndex;
  final bool isPlaying;
  final double fontSize;
  final String fontFamily;
  final FontWeight fontWeight;
  final Color textColor;
  final Color highlightColor;
  final Function(int index) onSentenceTap;

  const SentenceHighlight({
    super.key,
    required this.sentences,
    required this.highlightedIndex,
    required this.isPlaying,
    required this.fontSize,
    required this.fontFamily,
    required this.fontWeight,
    required this.textColor,
    this.highlightColor = const Color(0xFFFFD700),
    required this.onSentenceTap,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: sentences.asMap().entries.map((entry) {
          final index = entry.key;
          final sentence = entry.value;
          final isHighlighted = isPlaying && index == highlightedIndex;

          return WidgetSpan(
            child: GestureDetector(
              onTap: () => onSentenceTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 1),
                decoration: isHighlighted
                    ? BoxDecoration(
                        color: highlightColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      )
                    : null,
                child: Text(
                  '$sentence ',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontFamily: fontFamily,
                    fontWeight: fontWeight,
                    color: isHighlighted ? Colors.black87 : textColor,
                    backgroundColor: isHighlighted
                        ? highlightColor.withOpacity(0.25)
                        : Colors.transparent,
                    height: 1.7,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
