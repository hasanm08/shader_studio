import 'package:flutter/material.dart';
import 'package:shader_studio/app/theme/app_theme.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_preset.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_refraction_config.dart';
import 'package:shader_studio/features/glass_refraction/utils/glass_preset_mapper.dart';

/// Horizontal preset chips for the glass demo.
class GlassPresetSelector extends StatelessWidget {
  /// Creates the preset selector.
  const GlassPresetSelector({
    required this.config,
    required this.onSelected,
    super.key,
  });

  final GlassRefractionConfig config;
  final ValueChanged<GlassPreset> onSelected;

  @override
  Widget build(BuildContext context) {
    final active = GlassPresetMapper.matchingPreset(config);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Presets', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final preset in GlassPreset.values) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(preset.label),
                    selected: preset == active,
                    onSelected: (_) => onSelected(preset),
                    selectedColor: AppColors.accent.withValues(alpha: 0.25),
                    checkmarkColor: AppColors.accent,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (active != null) ...[
          const SizedBox(height: 8),
          Text(
            active.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            'Custom mix — adjust sliders or pick a preset.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
