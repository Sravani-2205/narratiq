import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/library_service.dart';
import '../../app/routes.dart';
import 'library_card.dart';
import '../onboarding/import_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Narratiq',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF6B4EFF),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: Consumer<LibraryService>(
        builder: (context, library, _) {
          final books = library.books;

          if (books.isEmpty) {
            return _EmptyLibrary(
              onImport: () => _openImport(context, library),
            );
          }

          return ListView(
            children: [
              // Recently opened section
              if (library.recentBooks.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Continue Reading',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      )),
                ),
                ...library.recentBooks.map((book) => LibraryCard(
                      book: book,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.reader,
                        arguments: book,
                      ),
                      onDelete: () => _confirmDelete(context, library, book.id),
                    )),
                const Divider(indent: 16, endIndent: 16, height: 24),
              ],
              // All books section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Library',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    )),
              ),
              ...books.map((book) => LibraryCard(
                    book: book,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.reader,
                      arguments: book,
                    ),
                    onDelete: () => _confirmDelete(context, library, book.id),
                  )),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Consumer<LibraryService>(
          builder: (context, library, _) => const SizedBox.shrink(),
        ) is Widget
            ? _openImport(
                context,
                context.read<LibraryService>(),
              )
            : null,
        backgroundColor: const Color(0xFF6B4EFF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
      ),
    );
  }

  Future<void> _openImport(BuildContext context, LibraryService library) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ImportScreen(libraryService: library),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    LibraryService library,
    String bookId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Book'),
        content: const Text('This will remove the book and all its data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) await library.deleteBook(bookId);
  }
}

class _EmptyLibrary extends StatelessWidget {
  final VoidCallback onImport;
  const _EmptyLibrary({required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Your library is empty',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Add an EPUB or TXT file to get started',
              style: TextStyle(color: Colors.grey.shade400)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onImport,
            icon: const Icon(Icons.add),
            label: const Text('Add Book'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4EFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
