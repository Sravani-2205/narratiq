import 'package:flutter/material.dart';

enum ReadingTheme { light, dark, sepia }

class ThemeSelector extends StatelessWidget {
  final ReadingTheme currentTheme;
  final Function(ReadingTheme) onThemeChanged;

  const ThemeSelector({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  static Color backgroundColor(ReadingTheme theme) {
    switch (theme) {
      case ReadingTheme.light: return const Color(0xFFFFFFFF);
      case ReadingTheme.dark:  return const Color(0xFF1A1A2E);
      case ReadingTheme.sepia: return const Color(0xFFF5E6C8);
    }
  }

  static Color textColor(ReadingTheme theme) {
    switch (theme) {
      case ReadingTheme.light: return const Color(0xFF1A1A1A);
      case ReadingTheme.dark:  return const Color(0xFFE8E8E8);
      case ReadingTheme.sepia: return const Color(0xFF3B2A1A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ThemeButton(label: 'Light', theme: ReadingTheme.light,
            bg: const Color(0xFFFFFFFF), text: const Color(0xFF1A1A1A),
            selected: currentTheme == ReadingTheme.light, onTap: onThemeChanged),
        const SizedBox(width: 12),
        _ThemeButton(label: 'Sepia', theme: ReadingTheme.sepia,
            bg: const Color(0xFFF5E6C8), text: const Color(0xFF3B2A1A),
            selected: currentTheme == ReadingTheme.sepia, onTap: onThemeChanged),
        const SizedBox(width: 12),
        _ThemeButton(label: 'Dark', theme: ReadingTheme.dark,
            bg: const Color(0xFF1A1A2E), text: const Color(0xFFE8E8E8),
            selected: currentTheme == ReadingTheme.dark, onTap: onThemeChanged),
      ],
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final String label;
  final ReadingTheme theme;
  final Color bg;
  final Color text;
  final bool selected;
  final Function(ReadingTheme) onTap;

  const _ThemeButton({
    required this.label, required this.theme, required this.bg,
    required this.text, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(theme),
      child: Container(
        width: 64, height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF6B4EFF) : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: text, fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
