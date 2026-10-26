import 'package:flutter/material.dart';
import 'package:shader_studio/core/geometry/shape_geometry.dart';
import 'package:shader_studio/features/shape_morphing/domain/models/morph_shape.dart';
import 'package:shader_studio/features/shape_morphing/domain/services/shape_morph_engine.dart';

/// Paints a [ShapeContour] with fill, optional stroke, shadows, and rotation.
class MorphShapePainter extends CustomPainter {
  /// Creates a painter for [contour] styled by [style].
  MorphShapePainter({
    required this.contour,
    required this.style,
    ShapeMorphEngine? engine,
  }) : engine = engine ?? ShapeMorphEngine();

  /// Normalized contour to paint.
  final ShapeContour contour;

  /// Fill, stroke, shadow, and rotation.
  final MorphShapeStyle style;

  /// Converts contours to paths.
  final ShapeMorphEngine engine;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !contour.isFinite) {
      return;
    }

    final inset = style.borderWidth;
    final path = engine.pathFor(contour, size: size, inset: inset);

    canvas.save();
    if (style.rotation != 0) {
      final center = Offset(size.width / 2, size.height / 2);
      canvas.translate(center.dx, center.dy);
      canvas.rotate(style.rotation);
      canvas.translate(-center.dx, -center.dy);
    }

    for (final shadow in style.shadows) {
      final shadowPaint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);
      if (shadow.offset == Offset.zero && shadow.spreadRadius == 0) {
        canvas.drawPath(path, shadowPaint);
      } else {
        final spread = shadow.spreadRadius;
        canvas.save();
        canvas.translate(shadow.offset.dx, shadow.offset.dy);
        if (spread != 0) {
          final center = Offset(size.width / 2, size.height / 2);
          final scale =
              1.0 +
              spread / (size.shortestSide / 2).clamp(1.0, double.infinity);
          canvas.translate(center.dx, center.dy);
          canvas.scale(scale);
          canvas.translate(-center.dx, -center.dy);
        }
        canvas.drawPath(path, shadowPaint);
        canvas.restore();
      }
    }

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final gradient = style.fillGradient;
    if (gradient != null) {
      fillPaint.shader = gradient.createShader(Offset.zero & size);
    } else {
      fillPaint.color = style.fillColor;
    }
    canvas.drawPath(path, fillPaint);

    if (style.borderColor != null && style.borderWidth > 0) {
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.borderWidth
        ..color = style.borderColor!
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, strokePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MorphShapePainter oldDelegate) {
    return oldDelegate.contour != contour ||
        oldDelegate.style != style ||
        oldDelegate.engine.sampleCount != engine.sampleCount;
  }
}
