import 'package:flutter/material.dart';

/// Silhouette used to clip and shade the glass panel.
enum GlassShape {
  /// Circular disc.
  circle('Circle', 0),

  /// Rectangle with configurable corner radius.
  roundedRectangle('Rounded rect', 1),

  /// Pill / stadium shape.
  capsule('Capsule', 2),

  /// Elliptical bi-convex lens silhouette.
  lens('Lens', 3);

  const GlassShape(this.label, this.shaderCode);

  /// Short label for selectors.
  final String label;

  /// Value written to the `uShape` uniform.
  final double shaderCode;

  /// Default corner radius for [roundedRectangle]. Ignored by other shapes.
  BorderRadius get defaultBorderRadius {
    return switch (this) {
      GlassShape.circle || GlassShape.lens => BorderRadius.circular(999),
      GlassShape.capsule => BorderRadius.circular(999),
      GlassShape.roundedRectangle => BorderRadius.circular(28),
    };
  }
}
