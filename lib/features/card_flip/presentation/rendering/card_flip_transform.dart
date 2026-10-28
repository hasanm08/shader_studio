import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shader_studio/features/card_flip/domain/models/card_flip_config.dart';

/// Builds the matrix for one frame of a Y-axis card flip.
///
/// The vertex sees transforms in this order:
/// 1. Back-face correction (`rotateY(π)`) when [correctBackFace] is true.
/// 2. The shared Y-axis flip, [angle], from 0 (front) to π (back).
/// 3. Optional tilt.
/// 4. Perspective, stored in matrix entry `(3, 2)` before the rotations.
///
/// The extra π turn is applied in the card's local space. On a flat card it
/// mirrors X and leaves Z at 0, so the silhouette keeps rotating through the
/// edge while the back typography stays readable.
Matrix4 cardFlipTransform({
  required double angle,
  required double perspective,
  required bool correctBackFace,
  double tiltX = 0,
  double tiltY = 0,
  double cardWidth = 300,
}) {
  final safeAngle = angle.isFinite ? angle : 0.0;
  final matrix = Matrix4.identity()
    ..setEntry(
      3,
      2,
      CardFlipConfig.clampPerspective(perspective, width: cardWidth),
    );
  matrix.rotateX(CardFlipConfig.clampTilt(tiltX));
  matrix.rotateY(CardFlipConfig.clampTilt(tiltY));
  matrix.rotateY(safeAngle);
  if (correctBackFace) {
    matrix.rotateY(math.pi);
  }
  return matrix;
}
