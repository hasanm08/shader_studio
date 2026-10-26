import 'dart:math' as math;
import 'dart:ui';

/// Immutable closed contour in normalized coordinates.
///
/// Points live roughly in `[-1, 1]` with the shape centered at the origin.
/// Contours are ordered counter-clockwise and start near the top
/// (`angle ≈ -π/2`) so morphing stays continuous.
class ShapeContour {
  /// Creates a contour from [points].
  ///
  /// [points] must contain at least three finite offsets. The list is copied.
  ShapeContour(List<Offset> points)
    : assert(points.length >= 3, 'A contour needs at least three points.'),
      points = List<Offset>.unmodifiable(points);

  /// Normalized contour vertices, counter-clockwise.
  final List<Offset> points;

  /// Number of samples on the contour.
  int get length => points.length;

  /// Axis-aligned bounding box of the contour.
  Rect get bounds {
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    for (final p in points) {
      minX = math.min(minX, p.dx);
      minY = math.min(minY, p.dy);
      maxX = math.max(maxX, p.dx);
      maxY = math.max(maxY, p.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Geometric centroid of the polygon (shoelace), falling back to the mean.
  Offset get centroid {
    if (points.isEmpty) {
      return Offset.zero;
    }
    var area = 0.0;
    var cx = 0.0;
    var cy = 0.0;
    for (var i = 0; i < points.length; i++) {
      final a = points[i];
      final b = points[(i + 1) % points.length];
      final cross = a.dx * b.dy - b.dx * a.dy;
      area += cross;
      cx += (a.dx + b.dx) * cross;
      cy += (a.dy + b.dy) * cross;
    }
    area *= 0.5;
    if (area.abs() < 1e-12) {
      var sx = 0.0;
      var sy = 0.0;
      for (final p in points) {
        sx += p.dx;
        sy += p.dy;
      }
      return Offset(sx / points.length, sy / points.length);
    }
    final inv = 1.0 / (6.0 * area);
    return Offset(cx * inv, cy * inv);
  }

  /// True when every coordinate is finite.
  bool get isFinite {
    for (final p in points) {
      if (!p.dx.isFinite || !p.dy.isFinite) {
        return false;
      }
    }
    return true;
  }

  /// Returns a contour translated so its centroid sits at the origin.
  ShapeContour centered() {
    final c = centroid;
    if (c == Offset.zero) {
      return this;
    }
    return ShapeContour([
      for (final p in points) Offset(p.dx - c.dx, p.dy - c.dy),
    ]);
  }

  /// Scales the contour so the larger axis of its bounds equals [targetExtent].
  ShapeContour normalizedTo({double targetExtent = 2.0}) {
    final b = bounds;
    final w = b.width;
    final h = b.height;
    final extent = math.max(w, h);
    if (extent < 1e-12) {
      return this;
    }
    final scale = targetExtent / extent;
    final c = b.center;
    return ShapeContour([
      for (final p in points)
        Offset((p.dx - c.dx) * scale, (p.dy - c.dy) * scale),
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! ShapeContour || other.points.length != points.length) {
      return false;
    }
    for (var i = 0; i < points.length; i++) {
      if (points[i] != other.points[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(points);
}
