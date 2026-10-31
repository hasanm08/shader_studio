import 'package:flutter_test/flutter_test.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_preset.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_refraction_config.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_shape.dart';
import 'package:shader_studio/features/glass_refraction/utils/glass_preset_mapper.dart';

void main() {
  group('GlassRefractionConfig', () {
    test('defaults match clear glass targets', () {
      const config = GlassRefractionConfig();
      expect(
        config.refractionStrength,
        GlassRefractionConfig.defaultRefractionStrength,
      );
      expect(config.curvature, GlassRefractionConfig.defaultCurvature);
      expect(config.blurSigma, GlassRefractionConfig.defaultBlurSigma);
      expect(config.animateHighlights, isTrue);
    });

    test('custom configuration is preserved until clamp', () {
      const config = GlassRefractionConfig(
        refractionStrength: 0.09,
        curvature: 1.1,
        blurSigma: 4,
        reflectionIntensity: 0.8,
        edgeHighlight: 1.0,
        chromaticAberration: 0.01,
        opacity: 0.2,
        cornerRadius: 0.4,
        animateHighlights: false,
      );
      expect(config.refractionStrength, 0.09);
      expect(config.animateHighlights, isFalse);
      expect(config.copyWith(blurSigma: 2).blurSigma, 2);
      expect(config.copyWith(blurSigma: 2).curvature, 1.1);
    });

    test('clamp rejects non-finite and out-of-range values', () {
      const wild = GlassRefractionConfig(
        refractionStrength: 99,
        curvature: double.nan,
        blurSigma: -3,
        chromaticAberration: double.infinity,
      );
      final clamped = wild.clamp();
      expect(
        clamped.refractionStrength,
        GlassRefractionConfig.maxRefractionStrength,
      );
      expect(clamped.curvature, GlassRefractionConfig.defaultCurvature);
      expect(clamped.blurSigma, GlassRefractionConfig.minBlurSigma);
      expect(
        clamped.chromaticAberration,
        GlassRefractionConfig.defaultChromaticAberration,
      );
    });

    test('equality is structural', () {
      expect(
        const GlassRefractionConfig(),
        equals(GlassRefractionConfig.clear),
      );
      expect(
        const GlassRefractionConfig(opacity: 0.1),
        isNot(equals(const GlassRefractionConfig())),
      );
    });
  });

  group('GlassPresetMapper', () {
    test('maps every preset to a clamped config', () {
      for (final preset in GlassPreset.values) {
        final config = GlassPresetMapper.configFor(preset);
        expect(config, equals(preset.config.clamp()));
        expect(GlassPresetMapper.matches(preset, config), isTrue);
      }
    });

    test('matchingPreset returns null for custom mixes', () {
      final custom = GlassPreset.clearGlass.config.copyWith(
        refractionStrength: 0.041,
      );
      expect(GlassPresetMapper.matchingPreset(custom), isNull);
      expect(
        GlassPresetMapper.matchingPreset(GlassPreset.crystal.config),
        GlassPreset.crystal,
      );
    });

    test('presets are visibly distinct', () {
      final clear = GlassPresetMapper.configFor(GlassPreset.clearGlass);
      final thick = GlassPresetMapper.configFor(GlassPreset.thickLens);
      final frost = GlassPresetMapper.configFor(GlassPreset.frostedGlass);
      expect(thick.curvature, greaterThan(clear.curvature));
      expect(frost.blurSigma, greaterThan(clear.blurSigma));
    });
  });

  group('GlassShape', () {
    test('shader codes are stable', () {
      expect(GlassShape.circle.shaderCode, 0);
      expect(GlassShape.roundedRectangle.shaderCode, 1);
      expect(GlassShape.capsule.shaderCode, 2);
      expect(GlassShape.lens.shaderCode, 3);
    });
  });
}
