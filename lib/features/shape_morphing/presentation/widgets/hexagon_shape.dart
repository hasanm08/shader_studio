import 'package:flutter/material.dart';
import 'package:shader_studio/core/geometry/shape_type.dart';
import 'package:shader_studio/features/shape_morphing/domain/models/morph_shape.dart';
import 'package:shader_studio/features/shape_morphing/domain/services/shape_morph_engine.dart';
import 'package:shader_studio/features/shape_morphing/presentation/widgets/_static_shape.dart';

/// Reusable regular hexagon.
class HexagonShape extends StatelessWidget {
  /// Creates a hexagon of [size] with optional [style].
  const HexagonShape({
    super.key,
    this.size = 220,
    this.style = MorphShapeStyle.flowForge,
    this.engine,
  });

  /// Logical width and height.
  final double size;

  /// Fill, border, shadow, and rotation.
  final MorphShapeStyle style;

  /// Optional shared geometry engine.
  final ShapeMorphEngine? engine;

  @override
  Widget build(BuildContext context) {
    return StaticShape(
      type: ShapeType.hexagon,
      size: size,
      style: style,
      engine: engine,
    );
  }
}
