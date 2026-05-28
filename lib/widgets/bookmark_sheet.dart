import 'package:flutter/material.dart';
import '../models/bookmark.dart';

/// Bottom sheet showing all bookmarks for a book.
class BookmarkSheet extends StatelessWidget {
  final List<Bookmark> bookmarks;
  final Function(Bookmark) onBookmarkTap;
  final Function(Bookmark) onBookmarkDelete;
  final VoidCallback onAddBookmark;

  const BookmarkSheet({
    super.key,
    required this.bookmarks,
    required this.onBookmarkTap,
    required this.onBookmarkDelete,
    required this.onAddBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Bookmarks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    onPressed: onAddBookmark,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: bookmarks.isEmpty
                  ? const Center(
                      child: Text('No bookmarks yet.\nTap Add to save your place.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: bookmarks.length,
                      itemBuilder: (context, index) {
                        final bookmark = bookmarks[index];
                        return ListTile(
                          leading: const Icon(Icons.bookmark, color: Color(0xFF6B4EFF)),
                          title: Text(bookmark.displayLabel,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            bookmark.sentencePreview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => onBookmarkDelete(bookmark),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            onBookmarkTap(bookmark);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
