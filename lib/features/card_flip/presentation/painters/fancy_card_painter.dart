import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shader_studio/features/card_flip/presentation/theme/card_flip_colors.dart';

/// Chamfered card silhouette with a notch on each side.
///
/// The path is inset so the stroke stays inside the widget bounds. Corners are
/// cut rather than rounded, which reads as a cut card instead of a stadium.
Path fancyCardPath(Size size) {
  if (size.width < 8 || size.height < 8) {
    return Path();
  }

  const inset = 2.0;
  final left = inset;
  final top = inset;
  final right = size.width - inset;
  final bottom = size.height - inset;
  final shortest = math.min(size.width, size.height);
  final chamfer = math.min(32.0, shortest * 0.14);
  var notch = math.min(14.0, shortest * 0.055);
  if (chamfer * 2 + notch * 2 > (bottom - top) - 4) {
    notch = 0;
  }
  final midY = (top + bottom) / 2;

  final path = Path()
    ..moveTo(left + chamfer, top)
    ..lineTo(right - chamfer, top)
    ..lineTo(right, top + chamfer);

  if (notch > 0) {
    path
      ..lineTo(right, midY - notch)
      ..arcToPoint(
        Offset(right, midY + notch),
        radius: Radius.circular(notch),
        clockwise: false,
      );
  }

  path
    ..lineTo(right, bottom - chamfer)
    ..lineTo(right - chamfer, bottom)
    ..lineTo(left + chamfer, bottom)
    ..lineTo(left, bottom - chamfer);

  if (notch > 0) {
    path
      ..lineTo(left, midY + notch)
      ..arcToPoint(
        Offset(left, midY - notch),
        radius: Radius.circular(notch),
        clockwise: false,
      );
  }

  path
    ..lineTo(left, top + chamfer)
    ..close();
  return path;
}

/// Clips a face to [fancyCardPath].
class FancyCardClipper extends CustomClipper<Path> {
  /// Creates a clipper for the fancy card silhouette.
  const FancyCardClipper();

  @override
  Path getClip(Size size) => fancyCardPath(size);

  @override
  bool shouldReclip(covariant FancyCardClipper oldClipper) => false;
}

/// Fills and strokes the fancy card. The shape does not change per frame;
/// the flip transform moves the painted layer.
class FancyCardPainter extends CustomPainter {
  /// Creates the card painter.
  const FancyCardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = fancyCardPath(size);
    if (path.getBounds().isEmpty) {
      return;
    }

    canvas.drawShadow(path, const Color(0xFF000000), 14, false);

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          CardFlipColors.surfaceRaised,
          CardFlipColors.surface,
          Color(0xFF0C1012),
        ],
        stops: <double>[0.0, 0.42, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, fill);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = CardFlipColors.tealBright.withValues(alpha: 0.9),
    );

    final bounds = path.getBounds().deflate(10);
    if (bounds.width > 8 && bounds.height > 8) {
      final inner = fancyCardPath(bounds.size).shift(bounds.topLeft);
      canvas.drawPath(
        inner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = CardFlipColors.teal.withValues(alpha: 0.28),
      );
    }
  }

  @override
  bool shouldRepaint(covariant FancyCardPainter oldDelegate) => false;
}
