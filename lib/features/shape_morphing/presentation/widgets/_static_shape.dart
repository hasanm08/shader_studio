import 'package:flutter/material.dart';
import 'package:shader_studio/core/geometry/shape_factory.dart';
import 'package:shader_studio/core/geometry/shape_type.dart';
import 'package:shader_studio/features/shape_morphing/domain/models/morph_shape.dart';
import 'package:shader_studio/features/shape_morphing/domain/services/shape_morph_engine.dart';
import 'package:shader_studio/features/shape_morphing/presentation/painters/morph_shape_painter.dart';

/// Shared static renderer for individual shape widgets.
class StaticShape extends StatelessWidget {
  /// Creates a non-animated shape of [type].
  const StaticShape({
    required this.type,
    super.key,
    this.size = 220,
    this.style = MorphShapeStyle.flowForge,
    this.engine,
  });

  /// Geometry to paint.
  final ShapeType type;

  /// Logical width and height.
  final double size;

  /// Visual style.
  final MorphShapeStyle style;

  /// Optional shared engine (defaults to a new instance).
  final ShapeMorphEngine? engine;

  @override
  Widget build(BuildContext context) {
    final morphEngine = engine ?? ShapeMorphEngine();
    final contour = ShapeFactory.contour(
      type,
      sampleCount: morphEngine.sampleCount,
    );
    return SizedBox(
      width: size,
      height: size,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: MorphShapePainter(
            contour: contour,
            style: style,
            engine: morphEngine,
          ),
          size: Size.square(size),
        ),
      ),
    );
  }
}
