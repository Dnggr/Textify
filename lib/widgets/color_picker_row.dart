import 'package:flutter/material.dart';

/// The color picker toolbar shown at the bottom of the drawing editor.
/// Has preset color swatches + a custom color picker button (eyedropper).
class ColorPickerRow extends StatelessWidget {
  final Color selectedColor;
  final void Function(Color) onColorSelected;

  // Preset palette — covers common annotation needs
  static const List<Color> presetColors = [
    Colors.white,
    Colors.black,
    Color(0xFFFF3B3B), // Red
    Color(0xFFFF9500), // Orange
    Color(0xFFFFD60A), // Yellow
    Color(0xFF30D158), // Green
    Color(0xFF00C7FF), // Cyan
    Color(0xFF0A84FF), // Blue
    Color(0xFFBF5AF2), // Purple
    Color(0xFFFF375F), // Pink
  ];

  const ColorPickerRow({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          // Preset color swatches (scrollable row)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: presetColors.map((color) {
                  final isSelected = color.value == selectedColor.value;
                  return GestureDetector(
                    onTap: () => onColorSelected(color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      width: isSelected ? 32 : 26,
                      height: isSelected ? 32 : 26,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white24,
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Custom color picker (eyedropper icon opens full color dialog)
          GestureDetector(
            onTap: () => _showCustomColorPicker(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF0000),
                    Color(0xFF00FF00),
                    Color(0xFF0000FF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.colorize_rounded, // eyedropper icon
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens a simple HSV color picker dialog.
  /// We build this without any external package using Flutter's built-in widgets.
  void _showCustomColorPicker(BuildContext context) {
    double hue = HSVColor.fromColor(selectedColor).hue;
    double sat = HSVColor.fromColor(selectedColor).saturation;
    double val = HSVColor.fromColor(selectedColor).value;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final currentColor = HSVColor.fromAHSV(1.0, hue, sat, val).toColor();
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text(
              'PICK COLOR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Color preview
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: currentColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                ),
                const SizedBox(height: 16),

                // Hue slider
                _buildSlider(
                  label: 'Hue',
                  value: hue / 360,
                  gradient: LinearGradient(
                    colors: List.generate(
                      7,
                      (i) => HSVColor.fromAHSV(1, i * 60.0, 1, 1).toColor(),
                    ),
                  ),
                  onChanged: (v) => setDialogState(() => hue = v * 360),
                ),

                // Saturation slider
                _buildSlider(
                  label: 'Saturation',
                  value: sat,
                  gradient: LinearGradient(
                    colors: [
                      HSVColor.fromAHSV(1, hue, 0, val).toColor(),
                      HSVColor.fromAHSV(1, hue, 1, val).toColor(),
                    ],
                  ),
                  onChanged: (v) => setDialogState(() => sat = v),
                ),

                // Brightness slider
                _buildSlider(
                  label: 'Brightness',
                  value: val,
                  gradient: LinearGradient(
                    colors: [
                      Colors.black,
                      HSVColor.fromAHSV(1, hue, sat, 1).toColor(),
                    ],
                  ),
                  onChanged: (v) => setDialogState(() => val = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
              TextButton(
                onPressed: () {
                  onColorSelected(currentColor);
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Use Color',
                  style: TextStyle(color: Color(0xFF00E5FF)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required LinearGradient gradient,
    required void Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 20,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SliderTheme(
            data: const SliderThemeData(
              trackHeight: 0,
              thumbColor: Colors.white,
              overlayColor: Colors.transparent,
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
