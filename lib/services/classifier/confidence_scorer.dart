import '../../models/book_profile.dart';
import '../../models/pov_character.dart';

/// Calculates the overall confidence score for a BookProfile.
/// Weighs individual signal confidences to produce a single 0.0–1.0 score.
class ConfidenceScorer {
  /// Calculate overall confidence from individual detection results.
  double calculate({
    required double narrativeConfidence,
    required double povStructureConfidence,
    required double dialogueConfidence,
    required List<PovCharacter> characters,
    required Map<int, String> chapterPovMap,
    required int totalChapters,
  }) {
    // Weight each component
    const narrativeWeight = 0.25;
    const povStructureWeight = 0.30;
    const characterWeight = 0.25;
    const coverageWeight = 0.20;

    // Character confidence = average of individual character confidences
    final characterScore = characters.isEmpty
        ? 0.0
        : characters
                .map((c) => _confidenceToScore(c.confidence))
                .reduce((a, b) => a + b) /
            characters.length;

    // Coverage = what % of chapters have a mapped POV character
    final coverageScore = totalChapters == 0
        ? 0.0
        : (chapterPovMap.length / totalChapters).clamp(0.0, 1.0);

    final overall = (narrativeConfidence * narrativeWeight) +
        (povStructureConfidence * povStructureWeight) +
        (characterScore * characterWeight) +
        (coverageScore * coverageWeight);

    return overall.clamp(0.0, 1.0);
  }

  double _confidenceToScore(DetectionConfidence confidence) {
    switch (confidence) {
      case DetectionConfidence.high:
        return 1.0;
      case DetectionConfidence.medium:
        return 0.6;
      case DetectionConfidence.low:
        return 0.3;
    }
  }

  /// Determine if voice switching should be enabled based on the profile.
  bool shouldEnableVoiceSwitching({
    required PovStructure structure,
    required List<PovCharacter> characters,
    required double overallConfidence,
  }) {
    // Need at least dual POV with characters of different genders
    if (structure == PovStructure.single ||
        structure == PovStructure.omniscient ||
        structure == PovStructure.epistolary) {
      return false;
    }

    if (characters.length < 2) return false;

    // Check if there's at least one male and one female character
    final hasMale = characters.any((c) => c.gender == CharacterGender.male);
    final hasFemale = characters.any((c) => c.gender == CharacterGender.female);

    return hasMale && hasFemale && overallConfidence > 0.4;
  }
}
