import 'package:flutter/material.dart';
import 'package:shader_studio/features/card_flip/presentation/painters/fancy_card_painter.dart';

/// Paints a chamfered, notched card and clips [child] to that silhouette.
class FancyCardShell extends StatelessWidget {
  /// Creates a shell around [child].
  const FancyCardShell({required this.child, super.key});

  /// Face content. Receives the card's tight constraints.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const FancyCardPainter(),
      child: ClipPath(clipper: const FancyCardClipper(), child: child),
    );
  }
}
