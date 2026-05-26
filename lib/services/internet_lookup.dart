import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Handles internet-based metadata enrichment.
/// Used once on book import to improve classification accuracy.
/// All lookups are read-only — no book content is ever sent externally.
class InternetLookup {
  static const _openLibraryUrl = 'https://openlibrary.org/search.json';
  static const _timeout = Duration(seconds: 8);

  /// Check if internet is available.
  Future<bool> isAvailable() async {
    try {
      final result = await InternetAddress.lookup('openlibrary.org')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Look up book metadata from Open Library.
  /// Returns null if not found or network fails.
  Future<BookMetadata?> lookupBook({
    required String title,
    required String author,
  }) async {
    try {
      final query = Uri.encodeComponent('$title $author');
      final uri = Uri.parse('$_openLibraryUrl?q=$query&limit=1&fields=title,author_name,subject,number_of_pages_median');
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = data['docs'] as List?;
      if (docs == null || docs.isEmpty) return null;

      final doc = docs.first as Map<String, dynamic>;
      return BookMetadata(
        resolvedTitle: doc['title'] as String?,
        resolvedAuthor: (doc['author_name'] as List?)?.first as String?,
        subjects: List<String>.from(doc['subject'] as List? ?? []),
      );
    } catch (_) {
      return null;
    }
  }

  /// Resolve the gender of a name using genderize.io.
  /// Returns null if the call fails or confidence is too low.
  Future<GenderResult?> resolveGender(String name) async {
    try {
      final uri = Uri.parse('https://api.genderize.io?name=${Uri.encodeComponent(name)}');
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final gender = data['gender'] as String?;
      final probability = (data['probability'] as num?)?.toDouble() ?? 0.0;
      final count = (data['count'] as num?)?.toInt() ?? 0;

      if (count < 10 || gender == null) return null;

      return GenderResult(
        gender: gender,
        probability: probability,
        sampleCount: count,
      );
    } catch (_) {
      return null;
    }
  }

  /// Resolve genders for multiple names in parallel.
  Future<Map<String, GenderResult>> resolveGenders(List<String> names) async {
    final results = <String, GenderResult>{};
    final futures = names.map((name) async {
      final result = await resolveGender(name);
      if (result != null) results[name] = result;
    });
    await Future.wait(futures);
    return results;
  }
}

class BookMetadata {
  final String? resolvedTitle;
  final String? resolvedAuthor;
  final List<String> subjects;

  BookMetadata({
    this.resolvedTitle,
    this.resolvedAuthor,
    required this.subjects,
  });
}

class GenderResult {
  final String gender;
  final double probability;
  final int sampleCount;

  GenderResult({
    required this.gender,
    required this.probability,
    required this.sampleCount,
  });

  bool get isReliable => probability > 0.75 && sampleCount > 50;
}
