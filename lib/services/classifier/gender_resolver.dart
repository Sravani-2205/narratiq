import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/pov_character.dart';
import '../../models/chapter.dart';

/// Resolves the gender of character names using:
/// 1. On-device pronoun analysis (primary, always runs)
/// 2. Genderize.io API (secondary, only if internet available)
class GenderResolver {
  static const String _genderizeUrl = 'https://api.genderize.io';

  /// Resolve genders for a list of character names.
  /// [chapterMap] maps name -> list of chapter indices they appear in.
  /// [chapters] is the full chapter list for pronoun scanning.
  Future<List<PovCharacter>> resolve({
    required Map<String, List<int>> chapterMap,
    required List<Chapter> chapters,
    bool useInternet = true,
  }) async {
    final results = <PovCharacter>[];

    for (final entry in chapterMap.entries) {
      final name = entry.key;
      final chapterIndices = entry.value;

      // Step 1: On-device pronoun analysis
      final onDeviceResult = _analysePronouns(name, chapterIndices, chapters);

      // Step 2: Internet lookup if confidence is not already high
      if (useInternet && onDeviceResult.confidence != DetectionConfidence.high) {
        final internetResult = await _lookupGenderize(name);
        if (internetResult != null) {
          // Merge: internet fills gaps, on-device takes priority if high confidence
          results.add(PovCharacter(
            name: name,
            gender: internetResult.gender,
            confidence: internetResult.confidence,
            chapterIndices: chapterIndices,
          ));
          continue;
        }
      }

      results.add(PovCharacter(
        name: name,
        gender: onDeviceResult.gender,
        confidence: onDeviceResult.confidence,
        chapterIndices: chapterIndices,
      ));
    }

    return results;
  }

  /// Scan chapter content for gendered pronouns near the character's name.
  _GenderHint _analysePronouns(
    String name,
    List<int> chapterIndices,
    List<Chapter> chapters,
  ) {
    int femaleScore = 0;
    int maleScore = 0;

    final namePattern = RegExp(r'\b' + RegExp.escape(name) + r'\b', caseSensitive: false);

    for (final idx in chapterIndices) {
      if (idx >= chapters.length) continue;
      final sentences = chapters[idx].openingSentences(count: 10);

      for (final sentence in sentences) {
        if (!namePattern.hasMatch(sentence)) continue;
        final lower = sentence.toLowerCase();

        // Female signals near the name
        if (RegExp(r'\b(she|her|hers|herself)\b').hasMatch(lower)) femaleScore += 2;
        if (RegExp(r'\b(woman|girl|lady|queen|princess|witch|duchess|countess)\b').hasMatch(lower)) femaleScore += 1;

        // Male signals near the name
        if (RegExp(r'\b(he|him|his|himself)\b').hasMatch(lower)) maleScore += 2;
        if (RegExp(r'\b(man|boy|lord|king|prince|duke|count|knight)\b').hasMatch(lower)) maleScore += 1;
      }
    }

    // Also scan chapter headings for pronoun context in nearby chapters
    for (final idx in chapterIndices) {
      if (idx >= chapters.length) continue;
      final title = chapters[idx].title.toLowerCase();
      if (title.contains(name.toLowerCase())) {
        // Check the chapter before and after for pronoun context
        for (final nearIdx in [idx - 1, idx + 1]) {
          if (nearIdx < 0 || nearIdx >= chapters.length) continue;
          final nearSentences = chapters[nearIdx].openingSentences(count: 5);
          for (final s in nearSentences) {
            final lower = s.toLowerCase();
            if (RegExp(r'\b(she|her|hers|herself)\b').hasMatch(lower)) femaleScore += 1;
            if (RegExp(r'\b(he|him|his|himself)\b').hasMatch(lower)) maleScore += 1;
          }
        }
      }
    }

    if (femaleScore == 0 && maleScore == 0) {
      return _GenderHint(CharacterGender.unknown, DetectionConfidence.low);
    }

    final total = femaleScore + maleScore;
    final dominantScore = femaleScore > maleScore ? femaleScore : maleScore;
    final gender = femaleScore > maleScore ? CharacterGender.female : CharacterGender.male;
    final ratio = dominantScore / total;

    final confidence = ratio > 0.75
        ? DetectionConfidence.high
        : ratio > 0.55
            ? DetectionConfidence.medium
            : DetectionConfidence.low;

    return _GenderHint(gender, confidence);
  }

  /// Call genderize.io API for a single name.
  /// Returns null if the call fails or confidence is too low.
  Future<_GenderHint?> _lookupGenderize(String name) async {
    try {
      final uri = Uri.parse('$_genderizeUrl?name=${Uri.encodeComponent(name)}');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final genderStr = data['gender'] as String?;
      final probability = (data['probability'] as num?)?.toDouble() ?? 0.0;
      final count = (data['count'] as num?)?.toInt() ?? 0;

      // Ignore results with very few data points
      if (count < 10 || genderStr == null) return null;

      final gender = genderStr == 'female'
          ? CharacterGender.female
          : genderStr == 'male'
              ? CharacterGender.male
              : CharacterGender.unknown;

      final confidence = probability > 0.85
          ? DetectionConfidence.high
          : probability > 0.65
              ? DetectionConfidence.medium
              : DetectionConfidence.low;

      return _GenderHint(gender, confidence);
    } catch (_) {
      return null; // Network failure — fall back to on-device result
    }
  }
}

class _GenderHint {
  final CharacterGender gender;
  final DetectionConfidence confidence;
  _GenderHint(this.gender, this.confidence);
}
