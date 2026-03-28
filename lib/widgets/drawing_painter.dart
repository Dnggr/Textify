import 'package:flutter/material.dart';
import '../models/draw_action.dart';

/// CustomPainter that renders all completed draw strokes
/// plus the current in-progress stroke onto a canvas.
class DrawingPainter extends CustomPainter {
  final List<DrawAction> completedActions;
  final DrawAction? currentAction; // The stroke being drawn right now

  DrawingPainter({
    required this.completedActions,
    this.currentAction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all completed strokes first
    for (final action in completedActions) {
      _drawAction(canvas, action);
    }
    // Then draw the in-progress stroke on top
    if (currentAction != null) {
      _drawAction(canvas, currentAction!);
    }
  }

  void _drawAction(Canvas canvas, DrawAction action) {
    if (action.points.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = action.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (action.isEraser) {
      // Eraser: blend mode clear removes pixels
      paint.blendMode = BlendMode.clear;
      paint.color = Colors.transparent;
    } else {
      paint.color = action.color;
    }

    // Draw smooth connected lines between points
    if (action.points.length == 1) {
      // Single tap = draw a dot
      canvas.drawCircle(action.points.first, action.strokeWidth / 2, paint);
    } else {
      final path = Path();
      path.moveTo(action.points.first.dx, action.points.first.dy);
      for (int i = 1; i < action.points.length; i++) {
        path.lineTo(action.points[i].dx, action.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    // Repaint whenever the stroke list or current stroke changes
    return oldDelegate.completedActions != completedActions ||
        oldDelegate.currentAction != currentAction;
  }
}
