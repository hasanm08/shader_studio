import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shader_studio/core/geometry/path_interpolator.dart';
import 'package:shader_studio/core/geometry/polygon_geometry.dart';
import 'package:shader_studio/core/geometry/shape_factory.dart';
import 'package:shader_studio/core/geometry/shape_type.dart';
import 'package:shader_studio/features/shape_morphing/domain/services/shape_morph_engine.dart';

void main() {
  setUp(ShapeFactory.clearCache);

  group('circle geometry', () {
    test('stays within the unit bounding box and is finite', () {
      final circle = ShapeFactory.contour(ShapeType.circle);
      expect(circle.isFinite, isTrue);
      expect(circle.length, PolygonGeometry.defaultSampleCount);

      final bounds = circle.bounds;
      expect(bounds.left, greaterThanOrEqualTo(-1.01));
      expect(bounds.top, greaterThanOrEqualTo(-1.01));
      expect(bounds.right, lessThanOrEqualTo(1.01));
      expect(bounds.bottom, lessThanOrEqualTo(1.01));

      // Nearly circular: radii stay close to 1.
      for (final p in circle.points) {
        expect(p.distance, closeTo(1.0, 1e-9));
      }

      final centroid = circle.centroid;
      expect(centroid.dx.abs(), lessThan(1e-9));
      expect(centroid.dy.abs(), lessThan(1e-9));
    });
  });

  group('star geometry', () {
    test('has five outer tips and five inner vertices', () {
      final vertices = ShapeFactory.starVertices();
      expect(vertices, hasLength(10));

      final outers = <Offset>[];
      final inners = <Offset>[];
      for (var i = 0; i < vertices.length; i++) {
        if (i.isEven) {
          outers.add(vertices[i]);
        } else {
          inners.add(vertices[i]);
        }
      }
      expect(outers, hasLength(5));
      expect(inners, hasLength(5));

      for (final tip in outers) {
        expect(tip.distance, closeTo(1.0, 1e-9));
      }
      for (final valley in inners) {
        expect(valley.distance, closeTo(0.38, 1e-9));
      }

      // First tip points upward.
      expect(outers.first.dx.abs(), lessThan(1e-9));
      expect(outers.first.dy, lessThan(0));
    });

    test('resampled star stays finite and bounded', () {
      final star = ShapeFactory.contour(ShapeType.star);
      expect(star.isFinite, isTrue);
      final bounds = star.bounds;
      expect(bounds.width, lessThanOrEqualTo(2.05));
      expect(bounds.height, lessThanOrEqualTo(2.05));
    });
  });

  group('polygon resampling', () {
    test('produces the requested sample count', () {
      const square = <Offset>[
        Offset(-1, -1),
        Offset(1, -1),
        Offset(1, 1),
        Offset(-1, 1),
      ];
      final sampled = PolygonGeometry.resample(square, sampleCount: 32);
      expect(sampled, hasLength(32));
      for (final p in sampled) {
        expect(p.dx.isFinite, isTrue);
        expect(p.dy.isFinite, isTrue);
      }
    });

    test('handles degenerate input without throwing', () {
      final empty = PolygonGeometry.resample(const [], sampleCount: 16);
      expect(empty, hasLength(16));
      expect(empty.every((p) => p.dx.isFinite && p.dy.isFinite), isTrue);

      final single = PolygonGeometry.resample(const [
        Offset(0, 0),
      ], sampleCount: 8);
      expect(single, hasLength(8));

      final nan = PolygonGeometry.resample(const [
        Offset(double.nan, 0),
        Offset(1, 1),
        Offset(0, 1),
      ], sampleCount: 12);
      expect(nan, hasLength(12));
      expect(nan.every((p) => p.dx.isFinite && p.dy.isFinite), isTrue);
    });
  });

  group('point interpolation', () {
    test('lerps corresponding points and endpoints', () {
      final from = ShapeFactory.contour(ShapeType.circle);
      final to = ShapeFactory.contour(ShapeType.star);

      final start = PathInterpolator.lerp(from, to, 0);
      final end = PathInterpolator.lerp(from, to, 1);
      final mid = PathInterpolator.lerp(from, to, 0.5);

      expect(start.points.first, from.points.first);
      expect(end.length, to.length);
      expect(mid.isFinite, isTrue);

      for (var i = 0; i < mid.length; i++) {
        final expected = Offset.lerp(
          from.points[i],
          PathInterpolator.lerp(from, to, 1).points[i],
          0.5,
        )!;
        expect(mid.points[i].dx, closeTo(expected.dx, 1e-9));
        expect(mid.points[i].dy, closeTo(expected.dy, 1e-9));
      }
    });

    test('clamps t outside 0..1', () {
      final from = ShapeFactory.contour(ShapeType.circle);
      final to = ShapeFactory.contour(ShapeType.square);
      final below = PathInterpolator.lerp(from, to, -1);
      final above = PathInterpolator.lerp(from, to, 2);
      expect(below, from);
      expect(above.length, to.length);
    });
  });

  group('circle to star morph', () {
    test('contour changes continuously and stays bounded', () {
      final engine = ShapeMorphEngine();
      Offset? previousCentroid;
      for (var step = 0; step <= 20; step++) {
        final t = step / 20;
        final contour = engine.morph(ShapeType.circle, ShapeType.star, t);
        expect(contour.isFinite, isTrue);
        expect(contour.bounds.width, lessThanOrEqualTo(2.2));
        expect(contour.bounds.height, lessThanOrEqualTo(2.2));

        final c = contour.centroid;
        if (previousCentroid != null) {
          expect((c - previousCentroid).distance, lessThan(0.15));
        }
        previousCentroid = c;
      }

      final atStart = engine.morph(ShapeType.circle, ShapeType.star, 0);
      final atEnd = engine.morph(ShapeType.circle, ShapeType.star, 1);
      expect((atStart.points.first.distance - 1.0).abs(), lessThan(0.05));
      // End contour should reach near the star's outer extent.
      final maxR = atEnd.points.map((p) => p.distance).reduce(math.max);
      expect(maxR, greaterThan(0.85));
    });

    test('path mapping preserves center inside the paint box', () {
      final engine = ShapeMorphEngine();
      const size = Size(200, 200);
      final path = engine.morphPath(
        ShapeType.circle,
        ShapeType.star,
        0.5,
        size: size,
      );
      final bounds = path.getBounds();
      expect(bounds.center.dx, closeTo(100, 8));
      expect(bounds.center.dy, closeTo(100, 8));
      expect(bounds.width, lessThanOrEqualTo(200));
      expect(bounds.height, lessThanOrEqualTo(200));
    });
  });

  group('all shapes', () {
    test('every shape type produces a valid normalized contour', () {
      for (final type in ShapeType.values) {
        final contour = ShapeFactory.contour(type, sampleCount: 48);
        expect(contour.length, 48, reason: type.name);
        expect(contour.isFinite, isTrue, reason: type.name);
        expect(contour.bounds.width, lessThanOrEqualTo(2.1), reason: type.name);
        expect(
          contour.bounds.height,
          lessThanOrEqualTo(2.1),
          reason: type.name,
        );
      }
    });
  });
}
