import 'package:flutter/material.dart';
import '../models/chapter.dart';
import '../models/book_profile.dart';

/// Slide-out drawer showing all chapters for navigation.
class ChapterDrawer extends StatelessWidget {
  final List<Chapter> chapters;
  final int currentChapterIndex;
  final BookProfile? profile;
  final Function(int index) onChapterSelected;

  const ChapterDrawer({
    super.key,
    required this.chapters,
    required this.currentChapterIndex,
    required this.profile,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Chapters',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  final isCurrent = index == currentChapterIndex;
                  final character = profile?.characterForChapter(index);

                  return ListTile(
                    selected: isCurrent,
                    selectedTileColor: Theme.of(context)
                        .colorScheme.primary.withOpacity(0.1),
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade200,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isCurrent ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      chapter.title,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: character != null
                        ? Text(
                            character.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: character.gender.name == 'male'
                                  ? const Color(0xFF4E9AF1)
                                  : const Color(0xFFE91E8C),
                            ),
                          )
                        : null,
                    trailing: isCurrent
                        ? Icon(Icons.play_arrow,
                            color: Theme.of(context).colorScheme.primary, size: 18)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      onChapterSelected(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
