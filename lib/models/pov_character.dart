/// The detected gender of a POV character.
enum CharacterGender { male, female, unknown }

/// The confidence level of a detection result.
enum DetectionConfidence { high, medium, low }

/// Represents a detected POV character in the book.
/// Created by the classifier and stored in the BookProfile.
class PovCharacter {
  final String name;
  final CharacterGender gender;
  final DetectionConfidence confidence;

  /// Which chapter indices this character appears as POV.
  /// Empty means they appear throughout or detection is ongoing.
  final List<int> chapterIndices;

  const PovCharacter({
    required this.name,
    required this.gender,
    required this.confidence,
    this.chapterIndices = const [],
  });

  String get genderLabel {
    switch (gender) {
      case CharacterGender.male:
        return 'Male';
      case CharacterGender.female:
        return 'Female';
      case CharacterGender.unknown:
        return 'Unknown';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'gender': gender.name,
      'confidence': confidence.name,
      'chapterIndices': chapterIndices,
    };
  }

  factory PovCharacter.fromMap(Map<String, dynamic> map) {
    return PovCharacter(
      name: map['name'] as String,
      gender: CharacterGender.values.byName(map['gender'] as String),
      confidence: DetectionConfidence.values.byName(map['confidence'] as String),
      chapterIndices: List<int>.from(map['chapterIndices'] as List),
    );
  }

  @override
  String toString() => 'PovCharacter($name, $genderLabel, $confidence)';
}
