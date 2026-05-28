import 'package:flutter/material.dart';

class ReaderControls extends StatelessWidget {
  final bool isPlaying;
  final double speechRate;
  final String? timeRemaining;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onPrevSentence;
  final VoidCallback onNextSentence;
  final VoidCallback onSleepTimer;
  final VoidCallback onBookmarks;
  final VoidCallback onChapters;
  final Function(double) onSpeedChanged;

  const ReaderControls({
    super.key,
    required this.isPlaying,
    required this.speechRate,
    required this.timeRemaining,
    required this.onPlay,
    required this.onPause,
    required this.onPrevSentence,
    required this.onNextSentence,
    required this.onSleepTimer,
    required this.onBookmarks,
    required this.onChapters,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Speed slider
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const Text('0.5x',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Expanded(
                    child: Slider(
                      value: speechRate,
                      min: 0.25,
                      max: 2.0,
                      divisions: 7,
                      activeColor: const Color(0xFF6B4EFF),
                      onChanged: onSpeedChanged,
                    ),
                  ),
                  Text('${speechRate.toStringAsFixed(2)}x',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            // Main controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.format_list_bulleted),
                  tooltip: 'Chapters',
                  onPressed: onChapters,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 32,
                  onPressed: onPrevSentence,
                ),
                GestureDetector(
                  onTap: isPlaying ? onPause : onPlay,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6B4EFF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 32,
                  onPressed: onNextSentence,
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  tooltip: 'Bookmarks',
                  onPressed: onBookmarks,
                ),
              ],
            ),
            // Time remaining + sleep timer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (timeRemaining != null)
                    Text(timeRemaining!,
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const Spacer(),
                  GestureDetector(
                    onTap: onSleepTimer,
                    child: const Row(
                      children: [
                        Icon(Icons.bedtime_outlined, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text('Sleep', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
