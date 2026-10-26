import 'dart:ui';

import 'package:shader_studio/core/geometry/path_interpolator.dart';
import 'package:shader_studio/core/geometry/polygon_geometry.dart';
import 'package:shader_studio/core/geometry/shape_factory.dart';
import 'package:shader_studio/core/geometry/shape_geometry.dart';
import 'package:shader_studio/core/geometry/shape_type.dart';

/// Pure geometry service that morphs between [ShapeType] contours.
///
/// Keeps caching and interpolation out of widgets and painters.
class ShapeMorphEngine {
  /// Creates an engine that samples contours at [sampleCount] points.
  ShapeMorphEngine({this.sampleCount = PolygonGeometry.defaultSampleCount});

  /// Number of points on every morphable contour.
  final int sampleCount;

  /// Returns a cached normalized contour for [type].
  ShapeContour contourFor(ShapeType type) {
    return ShapeFactory.contour(type, sampleCount: sampleCount);
  }

  /// Interpolates from [from] toward [to] at progress [t] in `[0, 1]`.
  ShapeContour morph(ShapeType from, ShapeType to, double t) {
    if (from == to) {
      return contourFor(from);
    }
    return PathInterpolator.lerp(contourFor(from), contourFor(to), t);
  }

  /// Interpolates between arbitrary contours of equal length.
  ShapeContour morphContours(ShapeContour from, ShapeContour to, double t) {
    return PathInterpolator.lerp(from, to, t);
  }

  /// Converts a normalized [contour] into a paint-ready [Path].
  Path pathFor(
    ShapeContour contour, {
    required Size size,
    Offset? center,
    double inset = 0,
  }) {
    return PathInterpolator.toPath(
      contour,
      size: size,
      center: center,
      inset: inset,
    );
  }

  /// Convenience: morph then build a path in one call.
  Path morphPath(
    ShapeType from,
    ShapeType to,
    double t, {
    required Size size,
    Offset? center,
    double inset = 0,
  }) {
    return pathFor(
      morph(from, to, t),
      size: size,
      center: center,
      inset: inset,
    );
  }
}
