import 'package:flutter/material.dart';
import 'package:shader_studio/core/geometry/shape_type.dart';

/// Visual styling for a morphing shape, independent of geometry.
@immutable
class MorphShapeStyle {
  /// Creates a style for fill, stroke, shadow, and rotation.
  const MorphShapeStyle({
    this.fillColor = const Color(0xFF14B8A6),
    this.fillGradient,
    this.borderColor,
    this.borderWidth = 0,
    this.shadows = const <BoxShadow>[
      BoxShadow(color: Color(0x6614B8A6), blurRadius: 28, spreadRadius: 2),
    ],
    this.rotation = 0,
  });

  /// FlowForge teal fill used by the demo when no gradient is set.
  static const MorphShapeStyle flowForge = MorphShapeStyle(
    fillGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFF2DD4BF), Color(0xFF14B8A6), Color(0xFF0F766E)],
      stops: <double>[0.0, 0.45, 1.0],
    ),
    shadows: <BoxShadow>[
      BoxShadow(color: Color(0x6614B8A6), blurRadius: 32, spreadRadius: 1),
    ],
  );

  /// Solid fill used when [fillGradient] is null.
  final Color fillColor;

  /// Optional gradient fill painted inside the morph path.
  final Gradient? fillGradient;

  /// Optional stroke color. Null skips the border.
  final Color? borderColor;

  /// Stroke width in logical pixels.
  final double borderWidth;

  /// Soft glow / drop shadows drawn under the fill.
  final List<BoxShadow> shadows;

  /// Extra rotation in radians applied when painting.
  final double rotation;

  /// Copies this style with selective overrides.
  MorphShapeStyle copyWith({
    Color? fillColor,
    Gradient? fillGradient,
    Color? borderColor,
    double? borderWidth,
    List<BoxShadow>? shadows,
    double? rotation,
  }) {
    return MorphShapeStyle(
      fillColor: fillColor ?? this.fillColor,
      fillGradient: fillGradient ?? this.fillGradient,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      shadows: shadows ?? this.shadows,
      rotation: rotation ?? this.rotation,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MorphShapeStyle &&
        other.fillColor == fillColor &&
        other.fillGradient == fillGradient &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        _listEquals(other.shadows, shadows) &&
        other.rotation == rotation;
  }

  @override
  int get hashCode => Object.hash(
    fillColor,
    fillGradient,
    borderColor,
    borderWidth,
    Object.hashAll(shadows),
    rotation,
  );
}

/// Snapshot of a morph transition between two [ShapeType]s.
@immutable
class MorphTransition {
  /// Creates a transition description.
  const MorphTransition({
    required this.from,
    required this.to,
    required this.progress,
  });

  /// Source shape at progress 0.
  final ShapeType from;

  /// Destination shape at progress 1.
  final ShapeType to;

  /// Interpolation factor in `[0, 1]`.
  final double progress;

  /// True when the contour has fully reached [to].
  bool get isComplete => progress >= 1.0 - 1e-6;

  /// True when still at the source shape.
  bool get isAtStart => progress <= 1e-6;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
