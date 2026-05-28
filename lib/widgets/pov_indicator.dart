import 'package:flutter/material.dart';
import '../models/book_profile.dart';
import '../models/pov_character.dart';

/// Shows the current POV character and voice gender.
/// Tappable to manually override the detected gender.
class PovIndicator extends StatelessWidget {
  final BookProfile? profile;
  final int currentChapterIndex;
  final String? manualOverride;
  final Function(String gender) onOverride;

  const PovIndicator({
    super.key,
    required this.profile,
    required this.currentChapterIndex,
    required this.manualOverride,
    required this.onOverride,
  });

  @override
  Widget build(BuildContext context) {
    if (profile == null || !profile!.voiceSwitchingEnabled) {
      return const SizedBox.shrink();
    }

    final character = profile!.characterForChapter(currentChapterIndex);
    if (character == null) return const SizedBox.shrink();

    final gender = manualOverride ?? _genderString(character.gender);
    final icon = gender == 'male' ? Icons.person : Icons.person_2;
    final color = gender == 'male'
        ? const Color(0xFF4E9AF1)
        : const Color(0xFFE91E8C);

    return GestureDetector(
      onTap: () => _showOverrideDialog(context, gender),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              'Reading as: ${character.name}',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit, size: 11, color: color.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  String _genderString(CharacterGender gender) {
    return gender == CharacterGender.male ? 'male' : 'female';
  }

  void _showOverrideDialog(BuildContext context, String currentGender) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Override Voice'),
        content: const Text('Choose the voice for this chapter:'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.person),
            label: const Text('Male Voice'),
            onPressed: () { Navigator.pop(ctx); onOverride('male'); },
          ),
          TextButton.icon(
            icon: const Icon(Icons.person_2),
            label: const Text('Female Voice'),
            onPressed: () { Navigator.pop(ctx); onOverride('female'); },
          ),
        ],
      ),
    );
  }
}
