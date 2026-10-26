import 'dart:math' as math;
import 'dart:ui';

import 'package:shader_studio/core/geometry/polygon_geometry.dart';
import 'package:shader_studio/core/geometry/shape_geometry.dart';
import 'package:shader_studio/core/geometry/shape_type.dart';

/// Builds and caches normalized [ShapeContour]s for each [ShapeType].
abstract final class ShapeFactory {
  static final Map<String, ShapeContour> _cache = {};

  /// Returns a normalized contour for [type] with [sampleCount] points.
  static ShapeContour contour(
    ShapeType type, {
    int sampleCount = PolygonGeometry.defaultSampleCount,
  }) {
    final key = '${type.name}:$sampleCount';
    final cached = _cache[key];
    if (cached != null) {
      return cached;
    }
    final built = _build(type, sampleCount);
    _cache[key] = built;
    return built;
  }

  /// Clears the contour cache. Intended for tests.
  static void clearCache() => _cache.clear();

  /// Raw five-pointed star vertices before resampling (10 points).
  ///
  /// Even indices are outer tips; odd indices are inner valleys.
  static List<Offset> starVertices({
    double outerRadius = 1.0,
    double innerRadius = 0.38,
    int tips = 5,
  }) {
    final vertices = <Offset>[];
    for (var i = 0; i < tips * 2; i++) {
      final angle = -math.pi / 2 + i * math.pi / tips;
      final r = i.isEven ? outerRadius : innerRadius;
      vertices.add(Offset(math.cos(angle) * r, math.sin(angle) * r));
    }
    return vertices;
  }

  static ShapeContour _build(ShapeType type, int sampleCount) {
    switch (type) {
      case ShapeType.circle:
        return _circle(sampleCount);
      case ShapeType.star:
        return _star(sampleCount);
      case ShapeType.square:
        return _regularPolygon(4, sampleCount, startAngle: math.pi / 4);
      case ShapeType.roundedSquare:
        return _roundedSquare(sampleCount);
      case ShapeType.triangle:
        return _regularPolygon(3, sampleCount, startAngle: -math.pi / 2);
      case ShapeType.hexagon:
        return _regularPolygon(6, sampleCount, startAngle: 0);
      case ShapeType.heart:
        return _heart(sampleCount);
      case ShapeType.organicBlob:
        return _organicBlob(sampleCount);
    }
  }

  static ShapeContour _circle(int sampleCount) {
    final points = <Offset>[
      for (var i = 0; i < sampleCount; i++)
        Offset(
          math.cos(-math.pi / 2 + 2 * math.pi * i / sampleCount),
          math.sin(-math.pi / 2 + 2 * math.pi * i / sampleCount),
        ),
    ];
    return ShapeContour(points);
  }

  /// Five-pointed star: five outer tips and five inner vertices.
  static ShapeContour _star(int sampleCount) {
    return PolygonGeometry.contourFromVertices(
      starVertices(),
      sampleCount: sampleCount,
    );
  }

  static ShapeContour _regularPolygon(
    int sides,
    int sampleCount, {
    required double startAngle,
  }) {
    final vertices = <Offset>[
      for (var i = 0; i < sides; i++)
        Offset(
          math.cos(startAngle + 2 * math.pi * i / sides),
          math.sin(startAngle + 2 * math.pi * i / sides),
        ),
    ];
    return PolygonGeometry.contourFromVertices(
      vertices,
      sampleCount: sampleCount,
    );
  }

  static ShapeContour _roundedSquare(int sampleCount) {
    // Corner radius as a fraction of half-side in normalized space.
    const half = 0.85;
    const corner = 0.35;
    final straight = half - corner;
    final vertices = <Offset>[];

    void arc(Offset center, double from, double to, int steps) {
      for (var i = 0; i <= steps; i++) {
        final t = from + (to - from) * (i / steps);
        vertices.add(
          Offset(
            center.dx + math.cos(t) * corner,
            center.dy + math.sin(t) * corner,
          ),
        );
      }
    }

    // Walk counter-clockwise starting near the top edge, then top-right arc.
    // Top edge left → right (excluding corners).
    vertices.add(Offset(-straight, -half));
    vertices.add(Offset(straight, -half));
    // Top-right
    arc(Offset(straight, -straight), -math.pi / 2, 0, 6);
    // Right
    vertices.add(Offset(half, straight));
    // Bottom-right
    arc(Offset(straight, straight), 0, math.pi / 2, 6);
    // Bottom
    vertices.add(Offset(-straight, half));
    // Bottom-left
    arc(Offset(-straight, straight), math.pi / 2, math.pi, 6);
    // Left
    vertices.add(Offset(-half, -straight));
    // Top-left
    arc(Offset(-straight, -straight), math.pi, 3 * math.pi / 2, 6);

    return PolygonGeometry.contourFromVertices(
      vertices,
      sampleCount: sampleCount,
    );
  }

  static ShapeContour _heart(int sampleCount) {
    // Classic parametric heart, sampled densely then normalized.
    final raw = <Offset>[];
    for (var i = 0; i < sampleCount; i++) {
      final t = -math.pi + 2 * math.pi * i / sampleCount;
      final x = 16 * math.pow(math.sin(t), 3).toDouble();
      final y =
          -(13 * math.cos(t) -
              5 * math.cos(2 * t) -
              2 * math.cos(3 * t) -
              math.cos(4 * t));
      raw.add(Offset(x, y));
    }
    return PolygonGeometry.contourFromVertices(raw, sampleCount: sampleCount);
  }

  static ShapeContour _organicBlob(int sampleCount) {
    final points = <Offset>[];
    for (var i = 0; i < sampleCount; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / sampleCount;
      final r =
          0.72 +
          0.14 * math.sin(3 * angle) +
          0.09 * math.cos(5 * angle + 0.4) +
          0.05 * math.sin(7 * angle - 0.8);
      points.add(Offset(math.cos(angle) * r, math.sin(angle) * r));
    }
    return PolygonGeometry.contourFromVertices(
      points,
      sampleCount: sampleCount,
    );
  }
}
