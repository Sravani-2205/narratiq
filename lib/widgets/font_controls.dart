import 'package:flutter/material.dart';

class FontControls extends StatelessWidget {
  final double fontSize;
  final String fontFamily;
  final FontWeight fontWeight;
  final Function(double) onFontSizeChanged;
  final Function(String) onFontFamilyChanged;
  final Function(FontWeight) onFontWeightChanged;

  const FontControls({
    super.key,
    required this.fontSize,
    required this.fontFamily,
    required this.fontWeight,
    required this.onFontSizeChanged,
    required this.onFontFamilyChanged,
    required this.onFontWeightChanged,
  });

  static const _fonts = ['Georgia', 'Palatino', 'sans-serif', 'monospace'];
  static const _weights = [FontWeight.w300, FontWeight.w400, FontWeight.w500, FontWeight.w700];
  static const _weightLabels = ['Light', 'Regular', 'Medium', 'Bold'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Font size
          Row(
            children: [
              const Text('A', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: fontSize,
                  min: 12,
                  max: 28,
                  divisions: 8,
                  onChanged: onFontSizeChanged,
                ),
              ),
              const Text('A', style: TextStyle(fontSize: 24)),
            ],
          ),
          // Font family
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _fonts.map((font) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(font, style: TextStyle(fontFamily: font)),
                  selected: fontFamily == font,
                  onSelected: (_) => onFontFamilyChanged(font),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Font weight
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_weights.length, (i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_weightLabels[i],
                      style: TextStyle(fontWeight: _weights[i])),
                  selected: fontWeight == _weights[i],
                  onSelected: (_) => onFontWeightChanged(_weights[i]),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}
