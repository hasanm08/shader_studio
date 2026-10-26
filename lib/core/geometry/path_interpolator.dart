import 'dart:ui';

import 'package:shader_studio/core/geometry/polygon_geometry.dart';
import 'package:shader_studio/core/geometry/shape_geometry.dart';

/// Interpolates compatible [ShapeContour]s and converts them to [Path]s.
abstract final class PathInterpolator {
  /// Linearly interpolates corresponding points of [from] and [to].
  ///
  /// Contours must share the same point count. [t] is clamped to `[0, 1]`.
  /// When [align] is true, [to] is rotated/reflected for minimal travel.
  static ShapeContour lerp(
    ShapeContour from,
    ShapeContour to,
    double t, {
    bool align = true,
  }) {
    assert(
      from.length == to.length,
      'Contours must share the same sample count '
      '(${from.length} vs ${to.length}).',
    );
    final progress = t.clamp(0.0, 1.0);
    final targetPoints = align
        ? PolygonGeometry.alignTo(from.points, to.points)
        : to.points;

    if (progress <= 0) {
      return from;
    }
    if (progress >= 1) {
      return ShapeContour(targetPoints);
    }

    final n = from.length;
    final out = List<Offset>.filled(n, Offset.zero);
    for (var i = 0; i < n; i++) {
      out[i] = Offset.lerp(from.points[i], targetPoints[i], progress)!;
    }
    return ShapeContour(out);
  }

  /// Builds a closed path from [contour], mapped into [size] around [center].
  ///
  /// Normalized coordinates roughly span `[-1, 1]`. The mapping scales by
  /// half the smaller side so the shape stays square inside [size].
  static Path toPath(
    ShapeContour contour, {
    required Size size,
    Offset? center,
    double inset = 0,
  }) {
    final c = center ?? Offset(size.width / 2, size.height / 2);
    final usable = Size(
      (size.width - inset * 2).clamp(0.0, double.infinity),
      (size.height - inset * 2).clamp(0.0, double.infinity),
    );
    final scale = (usable.shortestSide / 2).clamp(0.0, double.infinity);
    final path = Path();
    if (contour.points.isEmpty || scale <= 0) {
      return path;
    }
    final first = contour.points.first;
    path.moveTo(c.dx + first.dx * scale, c.dy + first.dy * scale);
    for (var i = 1; i < contour.points.length; i++) {
      final p = contour.points[i];
      path.lineTo(c.dx + p.dx * scale, c.dy + p.dy * scale);
    }
    path.close();
    return path;
  }
}
