import 'package:flutter/material.dart';
import 'package:shader_studio/app/theme/app_theme.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_refraction_config.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_shape.dart';

/// Live parameter sliders for the glass demo.
///
/// Rebuilds only when the parent passes a new [config]; the parent should
/// isolate this panel from the canvas ticker.
class GlassControls extends StatelessWidget {
  /// Creates the control panel.
  const GlassControls({
    required this.config,
    required this.shape,
    required this.onConfigChanged,
    required this.onShapeChanged,
    required this.onReset,
    this.glassWidth = 220,
    this.glassHeight = 160,
    this.onSizeChanged,
    super.key,
  });

  final GlassRefractionConfig config;
  final GlassShape shape;
  final ValueChanged<GlassRefractionConfig> onConfigChanged;
  final ValueChanged<GlassShape> onShapeChanged;
  final VoidCallback onReset;
  final double glassWidth;
  final double glassHeight;
  final void Function(double width, double height)? onSizeChanged;

  @override
  Widget build(BuildContext context) {
    final c = config.clamp();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Shape', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in GlassShape.values)
              ChoiceChip(
                label: Text(s.label),
                selected: s == shape,
                onSelected: (_) => onShapeChanged(s),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Optics', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _SliderRow(
          label: 'Refraction',
          value: c.refractionStrength,
          min: GlassRefractionConfig.minRefractionStrength,
          max: GlassRefractionConfig.maxRefractionStrength,
          semanticLabel: 'Refraction strength',
          onChanged: (v) => onConfigChanged(c.copyWith(refractionStrength: v)),
        ),
        _SliderRow(
          label: 'Thickness',
          value: c.curvature,
          min: GlassRefractionConfig.minCurvature,
          max: GlassRefractionConfig.maxCurvature,
          semanticLabel: 'Glass thickness and curvature',
          onChanged: (v) => onConfigChanged(c.copyWith(curvature: v)),
        ),
        _SliderRow(
          label: 'Blur',
          value: c.blurSigma,
          min: GlassRefractionConfig.minBlurSigma,
          max: GlassRefractionConfig.maxBlurSigma,
          semanticLabel: 'Blur radius',
          onChanged: (v) => onConfigChanged(c.copyWith(blurSigma: v)),
        ),
        _SliderRow(
          label: 'Reflection',
          value: c.reflectionIntensity,
          min: GlassRefractionConfig.minReflectionIntensity,
          max: GlassRefractionConfig.maxReflectionIntensity,
          semanticLabel: 'Reflection intensity',
          onChanged: (v) => onConfigChanged(c.copyWith(reflectionIntensity: v)),
        ),
        _SliderRow(
          label: 'Edge highlight',
          value: c.edgeHighlight,
          min: GlassRefractionConfig.minEdgeHighlight,
          max: GlassRefractionConfig.maxEdgeHighlight,
          semanticLabel: 'Edge highlight intensity',
          onChanged: (v) => onConfigChanged(c.copyWith(edgeHighlight: v)),
        ),
        _SliderRow(
          label: 'Chromatic',
          value: c.chromaticAberration,
          min: GlassRefractionConfig.minChromaticAberration,
          max: GlassRefractionConfig.maxChromaticAberration,
          semanticLabel: 'Chromatic aberration',
          onChanged: (v) => onConfigChanged(c.copyWith(chromaticAberration: v)),
        ),
        _SliderRow(
          label: 'Opacity',
          value: c.opacity,
          min: GlassRefractionConfig.minOpacity,
          max: GlassRefractionConfig.maxOpacity,
          semanticLabel: 'Glass opacity',
          onChanged: (v) => onConfigChanged(c.copyWith(opacity: v)),
        ),
        if (shape == GlassShape.roundedRectangle)
          _SliderRow(
            label: 'Corner radius',
            value: c.cornerRadius,
            min: GlassRefractionConfig.minCornerRadius,
            max: GlassRefractionConfig.maxCornerRadius,
            semanticLabel: 'Corner radius',
            onChanged: (v) => onConfigChanged(c.copyWith(cornerRadius: v)),
          ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Animate highlights'),
          subtitle: const Text('Slow specular drift'),
          value: c.animateHighlights,
          onChanged: (v) => onConfigChanged(c.copyWith(animateHighlights: v)),
        ),
        if (onSizeChanged != null) ...[
          const SizedBox(height: 8),
          Text('Size', style: Theme.of(context).textTheme.titleMedium),
          _SliderRow(
            label: 'Width',
            value: glassWidth,
            min: 120,
            max: 360,
            semanticLabel: 'Glass width',
            onChanged: (v) => onSizeChanged!(v, glassHeight),
          ),
          _SliderRow(
            label: 'Height',
            value: glassHeight,
            min: 80,
            max: 280,
            semanticLabel: 'Glass height',
            onChanged: (v) => onSizeChanged!(glassWidth, v),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.semanticLabel,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final text = value.toStringAsFixed(3);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                text,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Slider(
            min: min,
            max: max,
            value: value.clamp(min, max).toDouble(),
            label: text,
            onChanged: onChanged,
            divisions: 100,
          ),
          // Expose an explicit semantics node for tests / screen readers.
          Semantics(
            slider: true,
            label: semanticLabel,
            value: text,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
