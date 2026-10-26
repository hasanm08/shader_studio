import 'dart:math' as math;
import 'dart:ui';

import 'package:shader_studio/core/geometry/shape_geometry.dart';

/// Polygon helpers: resampling, winding, and start-point alignment.
abstract final class PolygonGeometry {
  /// Default sample count used by the morphing engine.
  static const int defaultSampleCount = 64;

  /// Resamples [vertices] to exactly [sampleCount] points along the perimeter.
  ///
  /// Vertices form a closed polygon. Degenerate or empty input returns a tiny
  /// regular polygon so callers never receive an empty contour.
  static List<Offset> resample(
    List<Offset> vertices, {
    int sampleCount = defaultSampleCount,
  }) {
    final count = math.max(3, sampleCount);
    if (vertices.isEmpty) {
      return _fallbackCircle(count);
    }

    final cleaned = <Offset>[];
    for (final v in vertices) {
      if (!v.dx.isFinite || !v.dy.isFinite) {
        continue;
      }
      if (cleaned.isEmpty || (cleaned.last - v).distanceSquared > 1e-16) {
        cleaned.add(v);
      }
    }
    if (cleaned.length < 2) {
      return _fallbackCircle(count);
    }

    // Drop duplicate closing vertex if present.
    if ((cleaned.first - cleaned.last).distanceSquared < 1e-16) {
      cleaned.removeLast();
    }
    if (cleaned.length < 2) {
      return _fallbackCircle(count);
    }

    final n = cleaned.length;
    final segmentLengths = List<double>.filled(n, 0);
    var perimeter = 0.0;
    for (var i = 0; i < n; i++) {
      final a = cleaned[i];
      final b = cleaned[(i + 1) % n];
      final len = (b - a).distance;
      segmentLengths[i] = len;
      perimeter += len;
    }

    if (perimeter < 1e-12) {
      return _fallbackCircle(count);
    }

    final result = List<Offset>.filled(count, Offset.zero);
    var segIndex = 0;
    var segStart = 0.0;
    var segEnd = segmentLengths[0];

    for (var i = 0; i < count; i++) {
      final target = perimeter * (i / count);
      while (target > segEnd && segIndex < n - 1) {
        segIndex++;
        segStart = segEnd;
        segEnd += segmentLengths[segIndex];
      }
      final segLen = segmentLengths[segIndex];
      final t = segLen < 1e-12
          ? 0.0
          : ((target - segStart) / segLen).clamp(0.0, 1.0);
      final a = cleaned[segIndex];
      final b = cleaned[(segIndex + 1) % n];
      result[i] = Offset.lerp(a, b, t)!;
    }
    return result;
  }

  /// Ensures the polygon winds counter-clockwise.
  static List<Offset> ensureCounterClockwise(List<Offset> points) {
    if (points.length < 3) {
      return points;
    }
    if (_signedArea(points) < 0) {
      return points.reversed.toList();
    }
    return points;
  }

  /// Rotates [points] so index 0 is the vertex closest to angle [startAngle].
  ///
  /// Default [startAngle] is `-π/2` (top of the shape in Flutter's Y-down
  /// space after the painter flips, and top in math space before).
  static List<Offset> alignStart(
    List<Offset> points, {
    double startAngle = -math.pi / 2,
  }) {
    if (points.isEmpty) {
      return points;
    }
    var bestIndex = 0;
    var bestScore = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final angle = math.atan2(p.dy, p.dx);
      var delta = (angle - startAngle).abs();
      if (delta > math.pi) {
        delta = 2 * math.pi - delta;
      }
      // Prefer the outermost point near the target angle.
      final score = delta - 0.001 * p.distance;
      if (score < bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }
    if (bestIndex == 0) {
      return points;
    }
    return [...points.sublist(bestIndex), ...points.sublist(0, bestIndex)];
  }

  /// Aligns [target] to [source] by rotating the sample ring for minimal
  /// squared distance, trying both windings.
  static List<Offset> alignTo(List<Offset> source, List<Offset> target) {
    assert(source.length == target.length);
    final n = source.length;
    if (n == 0) {
      return target;
    }

    var bestShift = 0;
    var bestReversed = false;
    var bestCost = double.infinity;

    void consider(List<Offset> candidate, {required bool reversed}) {
      for (var shift = 0; shift < n; shift++) {
        var cost = 0.0;
        for (var i = 0; i < n; i++) {
          final a = source[i];
          final b = candidate[(i + shift) % n];
          final dx = a.dx - b.dx;
          final dy = a.dy - b.dy;
          cost += dx * dx + dy * dy;
          if (cost >= bestCost) {
            break;
          }
        }
        if (cost < bestCost) {
          bestCost = cost;
          bestShift = shift;
          bestReversed = reversed;
        }
      }
    }

    consider(target, reversed: false);
    consider(target.reversed.toList(), reversed: true);

    final ordered = bestReversed ? target.reversed.toList() : target;
    if (bestShift == 0) {
      return ordered;
    }
    return [...ordered.sublist(bestShift), ...ordered.sublist(0, bestShift)];
  }

  /// Builds a closed [ShapeContour] from raw [vertices].
  static ShapeContour contourFromVertices(
    List<Offset> vertices, {
    int sampleCount = defaultSampleCount,
    bool normalize = true,
  }) {
    var points = resample(vertices, sampleCount: sampleCount);
    points = ensureCounterClockwise(points);
    points = alignStart(points);
    var contour = ShapeContour(points);
    if (normalize) {
      contour = contour.centered().normalizedTo();
      // Re-align after normalization in case centering shifted angles.
      final realigned = alignStart(contour.points);
      contour = ShapeContour(realigned);
    }
    return contour;
  }

  /// Signed polygon area via the shoelace formula. Positive = CCW.
  static double _signedArea(List<Offset> points) {
    var area = 0.0;
    for (var i = 0; i < points.length; i++) {
      final a = points[i];
      final b = points[(i + 1) % points.length];
      area += a.dx * b.dy - b.dx * a.dy;
    }
    return area * 0.5;
  }

  static List<Offset> _fallbackCircle(int count) {
    return [
      for (var i = 0; i < count; i++)
        Offset(
          math.cos(-math.pi / 2 + 2 * math.pi * i / count),
          math.sin(-math.pi / 2 + 2 * math.pi * i / count),
        ),
    ];
  }
}
