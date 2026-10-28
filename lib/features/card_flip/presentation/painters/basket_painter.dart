import 'package:flutter/material.dart';
import 'package:shader_studio/features/card_flip/presentation/theme/card_flip_colors.dart';

/// Which part of the carton to paint.
enum BasketPart {
  /// Back wall and floor, drawn behind the item.
  cavity,

  /// Front lip, drawn over the item once it has dropped in.
  lip,

  /// Hinged cover.
  lid,
}

/// Flat-shaded carton. Kept free of blur so the lid can animate cheaply.
class BasketPainter extends CustomPainter {
  /// Creates a painter for [part].
  const BasketPainter(this.part);

  /// Which piece this pass draws.
  final BasketPart part;

  @override
  void paint(Canvas canvas, Size size) {
    switch (part) {
      case BasketPart.cavity:
        _cavity(canvas, size);
      case BasketPart.lip:
        _lip(canvas, size);
      case BasketPart.lid:
        _lid(canvas, size);
    }
  }

  void _cavity(Canvas canvas, Size size) {
    final back = Path()
      ..moveTo(size.width * 0.08, size.height * 0.34)
      ..lineTo(size.width * 0.92, size.height * 0.34)
      ..lineTo(size.width * 0.84, size.height * 0.92)
      ..lineTo(size.width * 0.16, size.height * 0.92)
      ..close();
    canvas.drawPath(back, Paint()..color = const Color(0xFF1A2427));
    canvas.drawPath(
      back,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = CardFlipColors.teal.withValues(alpha: 0.7),
    );

    final floor = Path()
      ..moveTo(size.width * 0.16, size.height * 0.62)
      ..lineTo(size.width * 0.84, size.height * 0.62)
      ..lineTo(size.width * 0.76, size.height * 0.88)
      ..lineTo(size.width * 0.24, size.height * 0.88)
      ..close();
    canvas.drawPath(floor, Paint()..color = const Color(0xFF101618));
  }

  void _lip(Canvas canvas, Size size) {
    final lip = Path()
      ..moveTo(0, size.height * 0.2)
      ..lineTo(size.width, size.height * 0.2)
      ..lineTo(size.width * 0.9, size.height)
      ..lineTo(size.width * 0.1, size.height)
      ..close();
    canvas.drawPath(lip, Paint()..color = const Color(0xFF243033));
    canvas.drawPath(
      lip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = CardFlipColors.tealBright.withValues(alpha: 0.75),
    );
  }

  void _lid(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF2A3A3E), Color(0xFF152023)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = CardFlipColors.tealBright,
    );
    final knob = Offset(size.width / 2, size.height * 0.62);
    canvas.drawCircle(knob, 4, Paint()..color = CardFlipColors.teal);
  }

  @override
  bool shouldRepaint(covariant BasketPainter oldDelegate) {
    return oldDelegate.part != part;
  }
}

/// Small chamfered token that drops into the box.
class BasketTokenPainter extends CustomPainter {
  /// Creates the token painter.
  const BasketTokenPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.18, 0)
      ..lineTo(size.width * 0.82, 0)
      ..lineTo(size.width, size.height * 0.18)
      ..lineTo(size.width, size.height * 0.82)
      ..lineTo(size.width * 0.82, size.height)
      ..lineTo(size.width * 0.18, size.height)
      ..lineTo(0, size.height * 0.82)
      ..lineTo(0, size.height * 0.18)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF5EEAD4),
            Color(0xFF14B8A6),
            Color(0xFF0F766E),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant BasketTokenPainter oldDelegate) => false;
}
