import 'package:flutter/material.dart';
import 'package:shader_studio/features/card_flip/domain/models/card_flip_config.dart';
import 'package:shader_studio/features/card_flip/presentation/theme/card_flip_colors.dart';

/// Surface, gradient edge, and padding shared by the demo faces.
class CardFace extends StatelessWidget {
  /// Creates a face shell around [child].
  const CardFace({
    required this.child,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(CardFlipConfig.defaultRadius),
    ),
    super.key,
  });

  /// Face content. Expanded to the card's tight constraints.
  final Widget child;

  /// Inner corner radius. The parent clip uses the same value.
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final inner = BorderRadius.circular(
      (borderRadius.topLeft.x - 1.4).clamp(0, 1000),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF8FF3E6),
            Color(0x3314B8A6),
            Color(0x14FFFFFF),
            Color(0xAA14B8A6),
          ],
          stops: <double>[0.0, 0.28, 0.62, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: inner,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                CardFlipColors.surfaceRaised,
                CardFlipColors.surface,
                Color(0xFF0C1012),
              ],
              stops: <double>[0.0, 0.42, 1.0],
            ),
          ),
          child: ClipRRect(borderRadius: inner, child: child),
        ),
      ),
    );
  }
}
