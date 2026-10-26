/// Supported geometric shapes for the morphing system.
enum ShapeType {
  /// Unit circle sampled as a closed contour.
  circle,

  /// Five-pointed star with five outer tips and five inner valleys.
  star,

  /// Axis-aligned square.
  square,

  /// Square with rounded corners.
  roundedSquare,

  /// Equilateral triangle, tip up.
  triangle,

  /// Regular hexagon, flat-top oriented for stable morphs.
  hexagon,

  /// Classic parametric heart.
  heart,

  /// Soft organic blob from a radial Fourier series.
  organicBlob,
}

/// Human-readable labels for UI selectors.
extension ShapeTypeLabel on ShapeType {
  /// Short display name.
  String get label {
    switch (this) {
      case ShapeType.circle:
        return 'Circle';
      case ShapeType.star:
        return 'Star';
      case ShapeType.square:
        return 'Square';
      case ShapeType.roundedSquare:
        return 'Rounded Square';
      case ShapeType.triangle:
        return 'Triangle';
      case ShapeType.hexagon:
        return 'Hexagon';
      case ShapeType.heart:
        return 'Heart';
      case ShapeType.organicBlob:
        return 'Organic Blob';
    }
  }
}
