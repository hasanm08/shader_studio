import 'package:shader_studio/features/glass_refraction/domain/models/glass_preset.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_refraction_config.dart';

/// Maps between [GlassPreset] values and live [GlassRefractionConfig]s.
abstract final class GlassPresetMapper {
  /// Config for [preset], already clamped.
  static GlassRefractionConfig configFor(GlassPreset preset) {
    return preset.config.clamp();
  }

  /// Best matching preset for [config], or null when no preset matches.
  ///
  /// Equality is exact on the clamped config so slider drift leaves the
  /// selection as a custom mix.
  static GlassPreset? matchingPreset(GlassRefractionConfig config) {
    final clamped = config.clamp();
    for (final preset in GlassPreset.values) {
      if (preset.config.clamp() == clamped) {
        return preset;
      }
    }
    return null;
  }

  /// True when [config] equals the clamped parameters of [preset].
  static bool matches(GlassPreset preset, GlassRefractionConfig config) {
    return preset.config.clamp() == config.clamp();
  }
}
