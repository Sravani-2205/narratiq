import 'package:flutter/material.dart';
import '../models/book_profile.dart';
import '../models/pov_character.dart';

/// Expandable card showing the full book classification result.
class BookProfileCard extends StatelessWidget {
  final BookProfile profile;
  final VoidCallback onDismiss;

  const BookProfileCard({
    super.key,
    required this.profile,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('BOOK PROFILE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                        letterSpacing: 1.2, color: Colors.grey)),
                IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
              ],
            ),
            const Divider(),
            _row('Narrative style', _narrativeLabel(profile.narrativePerson)),
            _row('POV structure', _povLabel(profile.povStructure)),
            _row('Dialogue style', _dialogueLabel(profile.dialogueStyle)),
            _row('Confidence', profile.confidenceDisplay),
            if (profile.povCharacters.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('POV CHARACTERS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                      letterSpacing: 1.2, color: Colors.grey)),
              const SizedBox(height: 6),
              ...profile.povCharacters.map((c) => _characterRow(c)),
            ],
            if (profile.hasMidBookPovShift) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'POV pattern shifts around chapter ${(profile.midBookShiftChapter ?? 0) + 1}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Looks good — Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    ),
  );

  Widget _characterRow(PovCharacter character) {
    final color = character.gender == CharacterGender.male
        ? const Color(0xFF4E9AF1)
        : const Color(0xFFE91E8C);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            character.gender == CharacterGender.male ? Icons.person : Icons.person_2,
            size: 16, color: color,
          ),
          const SizedBox(width: 8),
          Text(character.name,
              style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          const SizedBox(width: 4),
          Text('· ${character.genderLabel}',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  String _narrativeLabel(NarrativePerson p) {
    switch (p) {
      case NarrativePerson.firstPerson: return 'First person';
      case NarrativePerson.thirdLimited: return 'Third person limited';
      case NarrativePerson.thirdOmniscient: return 'Third person omniscient';
      case NarrativePerson.secondPerson: return 'Second person';
      case NarrativePerson.mixed: return 'Mixed';
      case NarrativePerson.unknown: return 'Unknown';
    }
  }

  String _povLabel(PovStructure s) {
    switch (s) {
      case PovStructure.single: return 'Single POV';
      case PovStructure.dual: return 'Dual POV';
      case PovStructure.multi: return 'Multi POV';
      case PovStructure.omniscient: return 'Omniscient narrator';
      case PovStructure.epistolary: return 'Epistolary';
      case PovStructure.unknown: return 'Unknown';
    }
  }

  String _dialogueLabel(DialogueStyle s) {
    switch (s) {
      case DialogueStyle.standardQuoted: return 'Standard quoted';
      case DialogueStyle.emDash: return 'Em-dash style';
      case DialogueStyle.unquoted: return 'Unquoted';
      case DialogueStyle.mixed: return 'Mixed';
      case DialogueStyle.unknown: return 'Unknown';
    }
  }
}
