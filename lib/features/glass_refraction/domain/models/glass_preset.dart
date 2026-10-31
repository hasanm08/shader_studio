import 'package:shader_studio/features/glass_refraction/domain/models/glass_refraction_config.dart';

/// Named starting points for the demo and documentation.
enum GlassPreset {
  /// Light bend, low frost — window glass.
  clearGlass(
    'Clear Glass',
    'Light refraction, crisp edges, almost no frost.',
    GlassRefractionConfig(
      refractionStrength: 0.028,
      curvature: 0.45,
      blurSigma: 0.4,
      reflectionIntensity: 0.4,
      edgeHighlight: 0.7,
      chromaticAberration: 0.001,
      opacity: 0.4,
    ),
  ),

  /// Strong bulge and magnification.
  thickLens(
    'Thick Lens',
    'Convex magnification with pronounced edge bend.',
    GlassRefractionConfig(
      refractionStrength: 0.08,
      curvature: 1.15,
      blurSigma: 0.6,
      reflectionIntensity: 0.55,
      edgeHighlight: 0.9,
      chromaticAberration: 0.006,
      opacity: 0.5,
    ),
  ),

  /// Soft diffusion, muted refraction.
  frostedGlass(
    'Frosted Glass',
    'Heavy blur, gentle bend — privacy glass.',
    GlassRefractionConfig(
      refractionStrength: 0.018,
      curvature: 0.35,
      blurSigma: 5.5,
      reflectionIntensity: 0.25,
      edgeHighlight: 0.45,
      chromaticAberration: 0,
      opacity: 0.7,
    ),
  ),

  /// Bright rims and chromatic sparkle.
  crystal(
    'Crystal',
    'High reflection, chromatic fringe, sharp rims.',
    GlassRefractionConfig(
      refractionStrength: 0.05,
      curvature: 0.85,
      blurSigma: 0.3,
      reflectionIntensity: 0.85,
      edgeHighlight: 1.2,
      chromaticAberration: 0.012,
      opacity: 0.35,
    ),
  ),

  /// Minimal UI chrome.
  subtleGlass(
    'Subtle Glass',
    'Barely-there refraction for production chrome.',
    GlassRefractionConfig(
      refractionStrength: 0.012,
      curvature: 0.25,
      blurSigma: 1.2,
      reflectionIntensity: 0.2,
      edgeHighlight: 0.35,
      chromaticAberration: 0,
      opacity: 0.45,
    ),
  );

  const GlassPreset(this.label, this.description, this.config);

  /// Chip / list label.
  final String label;

  /// One-line summary for the info panel.
  final String description;

  /// Shader parameters for this look.
  final GlassRefractionConfig config;
}
