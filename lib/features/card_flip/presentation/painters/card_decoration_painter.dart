import 'package:flutter/material.dart';
import 'package:shader_studio/features/card_flip/presentation/theme/card_flip_colors.dart';

/// Geometric mark painted on a demo card face.
enum CardMarkVariant {
  /// Nested diamonds for the front.
  prism,

  /// Rules and nodes for the back.
  schematic,
}

/// Static decoration. Repaints only when the variant or colors change,
/// not on each flip frame. The transform above it moves the layer.
class CardMarkPainter extends CustomPainter {
  /// Creates a mark painter.
  const CardMarkPainter({
    required this.variant,
    this.primary = CardFlipColors.teal,
    this.highlight = CardFlipColors.tealBright,
  });

  /// Which composition to draw.
  final CardMarkVariant variant;

  /// Main stroke.
  final Color primary;

  /// Lighter stroke.
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    switch (variant) {
      case CardMarkVariant.prism:
        _paintPrism(canvas, size);
      case CardMarkVariant.schematic:
        _paintSchematic(canvas, size);
    }
  }

  void _paintPrism(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = highlight.withValues(alpha: 0.45);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = primary.withValues(alpha: 0.95);

    Path diamond(double rx, double ry) {
      return Path()
        ..moveTo(center.dx, center.dy - ry)
        ..lineTo(center.dx + rx, center.dy)
        ..lineTo(center.dx, center.dy + ry)
        ..lineTo(center.dx - rx, center.dy)
        ..close();
    }

    canvas.drawLine(
      Offset(center.dx, size.height * 0.08),
      Offset(center.dx, size.height * 0.92),
      faint,
    );
    canvas.drawPath(diamond(size.width * 0.36, size.height * 0.40), faint);
    canvas.drawPath(diamond(size.width * 0.24, size.height * 0.26), stroke);

    final shard = diamond(size.width * 0.11, size.height * 0.12);
    canvas.drawPath(
      shard,
      Paint()
        ..style = PaintingStyle.fill
        ..color = primary.withValues(alpha: 0.22),
    );
    canvas.drawPath(shard, stroke);

    final tick = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = highlight.withValues(alpha: 0.8);
    final left = center.dx - size.width * 0.24;
    final right = center.dx + size.width * 0.24;
    canvas.drawLine(
      Offset(left, center.dy - 8),
      Offset(left, center.dy + 8),
      tick,
    );
    canvas.drawLine(
      Offset(right, center.dy - 8),
      Offset(right, center.dy + 8),
      tick,
    );
  }

  void _paintSchematic(Canvas canvas, Size size) {
    final grid = Paint()
      ..strokeWidth = 1
      ..color = primary.withValues(alpha: 0.28);
    final bright = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = highlight.withValues(alpha: 0.85);

    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.18 + i * 0.2);
      canvas.drawLine(
        Offset(size.width * 0.08, y),
        Offset(size.width * 0.92, y),
        grid,
      );
    }

    final nodes = <double>[0.22, 0.5, 0.78];
    final nodeY = size.height * 0.58;
    for (final nx in nodes) {
      final center = Offset(size.width * nx, nodeY);
      canvas.drawCircle(center, 5, Paint()..color = primary);
      canvas.drawCircle(center, 9, bright);
    }
    canvas.drawLine(
      Offset(size.width * 0.22, nodeY),
      Offset(size.width * 0.78, nodeY),
      bright,
    );

    final bracket = Path()
      ..moveTo(size.width * 0.16, size.height * 0.14)
      ..lineTo(size.width * 0.08, size.height * 0.14)
      ..lineTo(size.width * 0.08, size.height * 0.30);
    canvas.drawPath(bracket, bright);
  }

  @override
  bool shouldRepaint(CardMarkPainter oldDelegate) {
    return oldDelegate.variant != variant ||
        oldDelegate.primary != primary ||
        oldDelegate.highlight != highlight;
  }
}
