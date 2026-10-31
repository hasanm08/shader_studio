import 'package:flutter/foundation.dart';

/// Immutable parameters for the glass refraction shader.
///
/// Values are clamped by [GlassRefractionConfig.clamp] before they are written
/// as uniforms. Callers can construct any combination; the demo presets in
/// [GlassPreset] produce coherent looks.
@immutable
class GlassRefractionConfig {
  /// Creates a glass configuration.
  const GlassRefractionConfig({
    this.refractionStrength = defaultRefractionStrength,
    this.curvature = defaultCurvature,
    this.blurSigma = defaultBlurSigma,
    this.reflectionIntensity = defaultReflectionIntensity,
    this.edgeHighlight = defaultEdgeHighlight,
    this.chromaticAberration = defaultChromaticAberration,
    this.opacity = defaultOpacity,
    this.cornerRadius = defaultCornerRadius,
    this.animateHighlights = true,
  });

  static const double defaultRefractionStrength = 0.035;
  static const double defaultCurvature = 0.65;
  static const double defaultBlurSigma = 1.5;
  static const double defaultReflectionIntensity = 0.35;
  static const double defaultEdgeHighlight = 0.6;
  static const double defaultChromaticAberration = 0.002;
  static const double defaultOpacity = 0.55;
  static const double defaultCornerRadius = 0.28;

  static const double minRefractionStrength = 0;
  static const double maxRefractionStrength = 0.12;
  static const double minCurvature = 0;
  static const double maxCurvature = 1.4;
  static const double minBlurSigma = 0;
  static const double maxBlurSigma = 8;
  static const double minReflectionIntensity = 0;
  static const double maxReflectionIntensity = 1;
  static const double minEdgeHighlight = 0;
  static const double maxEdgeHighlight = 1.5;
  static const double minChromaticAberration = 0;
  static const double maxChromaticAberration = 0.02;
  static const double minOpacity = 0;
  static const double maxOpacity = 1;
  static const double minCornerRadius = 0;
  static const double maxCornerRadius = 0.5;

  /// How strongly background UVs bend through the lens.
  final double refractionStrength;

  /// Height-field bulge. Higher values act like thicker glass.
  final double curvature;

  /// Soft frost amount mapped into the shader's multi-tap radius.
  final double blurSigma;

  /// Specular and inner highlight strength.
  final double reflectionIntensity;

  /// Fresnel / SDF rim brightness.
  final double edgeHighlight;

  /// Red/blue split along the refraction direction.
  final double chromaticAberration;

  /// Body opacity of the glass tint (child content stays fully opaque).
  final double opacity;

  /// Rounded-rect corner radius in normalized UV units (0–0.5).
  final double cornerRadius;

  /// When true, the specular light drifts slowly with time.
  final bool animateHighlights;

  /// Clear default glass — light bend, crisp edges.
  static const GlassRefractionConfig clear = GlassRefractionConfig();

  /// Returns a copy with selected fields replaced.
  GlassRefractionConfig copyWith({
    double? refractionStrength,
    double? curvature,
    double? blurSigma,
    double? reflectionIntensity,
    double? edgeHighlight,
    double? chromaticAberration,
    double? opacity,
    double? cornerRadius,
    bool? animateHighlights,
  }) {
    return GlassRefractionConfig(
      refractionStrength: refractionStrength ?? this.refractionStrength,
      curvature: curvature ?? this.curvature,
      blurSigma: blurSigma ?? this.blurSigma,
      reflectionIntensity: reflectionIntensity ?? this.reflectionIntensity,
      edgeHighlight: edgeHighlight ?? this.edgeHighlight,
      chromaticAberration: chromaticAberration ?? this.chromaticAberration,
      opacity: opacity ?? this.opacity,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      animateHighlights: animateHighlights ?? this.animateHighlights,
    );
  }

  /// Clamps every numeric field into the documented ranges.
  GlassRefractionConfig clamp() {
    return GlassRefractionConfig(
      refractionStrength: _clamp(
        refractionStrength,
        minRefractionStrength,
        maxRefractionStrength,
        defaultRefractionStrength,
      ),
      curvature: _clamp(
        curvature,
        minCurvature,
        maxCurvature,
        defaultCurvature,
      ),
      blurSigma: _clamp(
        blurSigma,
        minBlurSigma,
        maxBlurSigma,
        defaultBlurSigma,
      ),
      reflectionIntensity: _clamp(
        reflectionIntensity,
        minReflectionIntensity,
        maxReflectionIntensity,
        defaultReflectionIntensity,
      ),
      edgeHighlight: _clamp(
        edgeHighlight,
        minEdgeHighlight,
        maxEdgeHighlight,
        defaultEdgeHighlight,
      ),
      chromaticAberration: _clamp(
        chromaticAberration,
        minChromaticAberration,
        maxChromaticAberration,
        defaultChromaticAberration,
      ),
      opacity: _clamp(opacity, minOpacity, maxOpacity, defaultOpacity),
      cornerRadius: _clamp(
        cornerRadius,
        minCornerRadius,
        maxCornerRadius,
        defaultCornerRadius,
      ),
      animateHighlights: animateHighlights,
    );
  }

  static double _clamp(double value, double min, double max, double fallback) {
    if (!value.isFinite) {
      return fallback;
    }
    return value.clamp(min, max).toDouble();
  }

  @override
  bool operator ==(Object other) {
    return other is GlassRefractionConfig &&
        other.refractionStrength == refractionStrength &&
        other.curvature == curvature &&
        other.blurSigma == blurSigma &&
        other.reflectionIntensity == reflectionIntensity &&
        other.edgeHighlight == edgeHighlight &&
        other.chromaticAberration == chromaticAberration &&
        other.opacity == opacity &&
        other.cornerRadius == cornerRadius &&
        other.animateHighlights == animateHighlights;
  }

  @override
  int get hashCode => Object.hash(
    refractionStrength,
    curvature,
    blurSigma,
    reflectionIntensity,
    edgeHighlight,
    chromaticAberration,
    opacity,
    cornerRadius,
    animateHighlights,
  );
}
