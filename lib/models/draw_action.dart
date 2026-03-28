import 'dart:ui';

/// Represents one complete drawn stroke on the canvas.
/// Stored in a list so we can undo/redo by index.
class DrawAction {
  final List<Offset> points; // All points in this stroke
  final Color color; // Pen color
  final double strokeWidth; // Pen thickness
  final bool isEraser; // True = eraser stroke (draws transparent)

  DrawAction({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
  });
}
