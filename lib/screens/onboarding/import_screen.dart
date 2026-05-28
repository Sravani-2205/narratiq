import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/library_service.dart';

class ImportScreen extends StatefulWidget {
  final LibraryService libraryService;
  const ImportScreen({super.key, required this.libraryService});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isImporting = false;
  String? _error;

  Future<void> _pickFile() async {
    setState(() { _isImporting = true; _error = null; });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'txt'],
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      final path = result.files.single.path;
      if (path == null) {
        setState(() { _isImporting = false; _error = 'Could not access file.'; });
        return;
      }

      final book = await widget.libraryService.importBook(path);
      if (!mounted) return;

      if (book == null) {
        setState(() { _isImporting = false; _error = 'Could not read this file. Is it a valid EPUB or TXT?'; });
        return;
      }

      Navigator.pop(context);
    } catch (e) {
      setState(() { _isImporting = false; _error = 'Import failed: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Icon(Icons.upload_file, size: 48, color: Color(0xFF6B4EFF)),
          const SizedBox(height: 12),
          const Text('Add a Book',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Supported formats: EPUB, TXT\nThe book will be analysed automatically after import.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(_error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isImporting ? null : _pickFile,
              icon: _isImporting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.folder_open),
              label: Text(_isImporting ? 'Importing...' : 'Choose File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
