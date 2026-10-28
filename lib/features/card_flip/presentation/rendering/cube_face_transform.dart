import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Places one cube face on the Y-axis carousel.
///
/// The face is pushed out by [depth] and then yawed by [spin] minus a
/// quarter turn per [index]. Positive [spin] brings the next face forward.
/// Perspective is applied by the parent so every face shares one camera.
Matrix4 cubeFaceTransform({
  required double spin,
  required int index,
  required double depth,
}) {
  final safeSpin = spin.isFinite ? spin : 0.0;
  final safeDepth = depth.isFinite ? math.max(0.0, depth) : 0.0;
  final matrix = Matrix4.identity();
  matrix.rotateY(safeSpin - index * math.pi / 2);
  matrix.translateByDouble(0, 0, safeDepth, 1);
  return matrix;
}

/// Z of the face center after [cubeFaceTransform]. Larger is closer.
double cubeFaceDepth({required double spin, required int index}) {
  final angle = (spin.isFinite ? spin : 0.0) - index * math.pi / 2;
  return math.cos(angle);
}
